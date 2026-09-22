import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/datasources/remote/dio_client.dart';
import '../../../core/database/app_database.dart';
import '../../../core/data/mappers/speed_mapper.dart';
import '../../../core/domain/entities/speed_test_result.dart';
import '../../../core/domain/repositories/speed_test_repository.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/app_logger.dart';

/// تنفيذ اختبار السرعة بقياس HTTP فعلي.
///
/// التنزيل: ننزّل ملفات قياس من مزوّدي CDN عامين ونحسب السرعة
/// من حجم البيانات الفعلية المُستقبلة خلال زمن القياس.
/// الرفع: نرسل حمولة POST إلى نقطة قياس.
/// الكمون: متوسط زمن طلبات خفيفة، والتذبذب من تباينها.
///
/// المحرك الكامل باختيار أقرب خادم سيُبنى على هذا في PHASE 6؛
/// هنا المنطق العملي عامل بدون أي مفتاح API.
class SpeedTestRepositoryImpl implements SpeedTestRepository {
  SpeedTestRepositoryImpl(this._dio, this._db);
  final Dio _dio;
  final AppDatabase _db;

  // ملفات قياس عامة (Cloudflare) بأحجام متدرجة.
  static const _downloadUrls = [
    'https://speed.cloudflare.com/__down?bytes=10000000',
    'https://speed.cloudflare.com/__down?bytes=25000000',
  ];
  static const _uploadUrl = 'https://speed.cloudflare.com/__up';
  static const _pingUrl = 'https://speed.cloudflare.com/__down?bytes=0';

  @override
  Future<Result<List<SpeedTestServer>>> getServers() async {
    return guard(() async => const [
          SpeedTestServer(
            id: 'cloudflare',
            name: 'Cloudflare',
            location: 'أقرب خادم تلقائي',
            host: 'speed.cloudflare.com',
          ),
        ]);
  }

  @override
  Future<Result<SpeedTestResult>> runTest({
    SpeedTestServer? server,
    void Function(SpeedTestProgress)? onProgress,
  }) async {
    return guard(() async {
      // ── الكمون والتذبذب ──
      onProgress?.call(const SpeedTestProgress(phase: SpeedTestPhase.ping));
      final rtts = <double>[];
      for (var i = 0; i < 8; i++) {
        final sw = Stopwatch()..start();
        try {
          await _dio.get<dynamic>(_pingUrl,
              options: Options(receiveTimeout: const Duration(seconds: 5)));
          rtts.add(sw.elapsedMilliseconds.toDouble());
        } catch (_) {}
      }
      rtts.sort();
      final ping = rtts.isEmpty ? 0.0 : rtts.reduce((a, b) => a + b) / rtts.length;
      final jitter = rtts.length < 2
          ? 0.0
          : [for (var i = 1; i < rtts.length; i++) (rtts[i] - rtts[i - 1]).abs()]
                  .reduce((a, b) => a + b) /
              (rtts.length - 1);

      // ── التنزيل ──
      onProgress?.call(const SpeedTestProgress(phase: SpeedTestPhase.download));
      double downloadMbps = 0;
      for (final url in _downloadUrls) {
        final mbps = await _measureDownload(url, onProgress);
        downloadMbps = math.max(downloadMbps, mbps);
      }

      // ── الرفع ──
      onProgress?.call(const SpeedTestProgress(phase: SpeedTestPhase.upload));
      final uploadMbps = await _measureUpload(onProgress);

      onProgress?.call(const SpeedTestProgress(
          phase: SpeedTestPhase.done, percent: 100));

      final result = SpeedTestResult(
        downloadMbps: downloadMbps,
        uploadMbps: uploadMbps,
        pingMs: ping,
        jitterMs: jitter,
        serverName: server?.name ?? 'Cloudflare',
        serverLocation: server?.location,
        timestamp: DateTime.now(),
      );

      await _db.speedTestDao.insert(SpeedTestMapper.toCompanion(result));
      return result;
    });
  }

  Future<double> _measureDownload(
    String url,
    void Function(SpeedTestProgress)? onProgress,
  ) async {
    final completer = Completer<double>();
    var received = 0;
    final sw = Stopwatch()..start();
    StreamSubscription<List<int>>? sub;

    try {
      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream),
      );
      final total = response.data?.contentLength ?? 25000000;
      sub = response.data?.stream.listen(
        (chunk) {
          received += chunk.length;
          final seconds = sw.elapsedMilliseconds / 1000;
          if (seconds > 0.1) {
            final mbps = (received * 8) / (seconds * 1000000);
            final percent = (received / total).clamp(0.0, 1.0);
            onProgress?.call(SpeedTestProgress(
              phase: SpeedTestPhase.download,
              percent: percent,
              currentMbps: mbps,
            ));
          }
        },
        onDone: () {
          final seconds = sw.elapsedMilliseconds / 1000;
          completer.complete(seconds == 0 ? 0 : (received * 8) / (seconds * 1000000));
        },
        onError: (Object e) {
          AppLogger.warning('خطأ أثناء قياس التنزيل', error: e);
          completer.complete(0);
        },
      );
    } catch (e) {
      AppLogger.warning('فشل بدء قياس التنزيل', error: e);
      return 0;
    }

    final result = await completer.future;
    await sub?.cancel();
    return result;
  }

  Future<double> _measureUpload(void Function(SpeedTestProgress)? onProgress) async {
    // حمولة رفع ~5 ميغابايت تُولَّد مرة واحدة.
    final payload = List<int>.generate(5 * 1024 * 1024, (i) => i % 256);
    final sw = Stopwatch()..start();
    var sent = 0;

    try {
      final stream = Stream.fromIterable(payload.map((e) => [e])).transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            sent += data.length;
            final seconds = sw.elapsedMilliseconds / 1000;
            if (seconds > 0.2 && sent % 500000 < 1000) {
              onProgress?.call(SpeedTestProgress(
                phase: SpeedTestPhase.upload,
                percent: (sent / payload.length).clamp(0.0, 1.0),
                currentMbps: (sent * 8) / (seconds * 1000000),
              ));
            }
            sink.add(data);
          },
        ),
      );

      await _dio.post<dynamic>(
        _uploadUrl,
        data: stream,
        options: Options(
          headers: {'Content-Length': payload.length},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final seconds = sw.elapsedMilliseconds / 1000;
      return seconds == 0 ? 0 : (sent * 8) / (seconds * 1000000);
    } catch (e) {
      AppLogger.warning('فشل قياس الرفع', error: e);
      return 0;
    }
  }

  @override
  Stream<List<SpeedTestResult>> watchHistory({int limit = 100}) =>
      _db.speedTestDao
          .watchAll(limit: limit)
          .map((rows) => rows.map(SpeedTestMapper.toEntity).toList());

  @override
  Future<Result<SpeedTestResult?>> getLatest() async =>
      guard(() async {
        final row = await _db.speedTestDao.getLatest();
        return row == null ? null : SpeedTestMapper.toEntity(row);
      });

  @override
  Future<Result<SpeedTestResult?>> getPeak() async => guard(() async {
        final row = await _db.speedTestDao.getPeakDownload();
        return row == null ? null : SpeedTestMapper.toEntity(row);
      });

  @override
  Future<Result<void>> saveResult(SpeedTestResult result) =>
      guard(() => _db.speedTestDao.insert(SpeedTestMapper.toCompanion(result)));

  @override
  Future<Result<void>> clearHistory() =>
      guard(() => _db.speedTestDao.clear());
}

final speedTestRepositoryProvider = Provider<SpeedTestRepository>((ref) {
  return SpeedTestRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(appDatabaseProvider),
  );
});
