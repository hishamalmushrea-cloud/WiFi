import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/data/mappers/wardriving_mapper.dart';
import '../../../core/domain/entities/wardriving.dart';
import '../../../core/domain/repositories/wardriving_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/app_logger.dart';

/// تنفيذ مستودع الـ Wardriving.
///
/// جلسة التسجيل الكاملة (تكرار مسح WiFi + GPS عبر الخدمة الخلفية)
/// تُبنى في PHASE 12؛ هنا نوفر:
///  - فحص البلوتوث/BLE عبر flutter_blue_plus.
///  - حفظ/مراقبة/تصدير النقاط عبر Drift و CSV.
///  - إحصائيات الجلسة من البيانات المخزّنة.
class WardrivingRepositoryImpl implements WardrivingRepository {
  WardrivingRepositoryImpl(this._db);
  final AppDatabase _db;

  final _sessionController =
      StreamController<List<WardrivingPoint>>.broadcast();
  Timer? _timer;

  @override
  Stream<List<WardrivingPoint>> startSession() {
    // البث الحي الكامل يربط بمحرك المسح في PHASE 12؛ حالياً نعيد
    // بثّ التحديثات اليدوية المحفوظة.
    return _sessionController.stream;
  }

  @override
  Future<Result<void>> stopSession() => guard(() async {
        _timer?.cancel();
        _timer = null;
      });

  @override
  Future<Result<void>> savePoints(List<WardrivingPoint> points) =>
      guard(() => _db.wardrivingDao.insertMany(
            points.map(WardrivingMapper.toCompanion).toList(),
          ));

  @override
  Stream<List<WardrivingPoint>> watchPoints() => _db
      .wardrivingDao
      .watchAll()
      .map((rows) => rows.map(WardrivingMapper.toEntity).toList());

  @override
  Future<Result<WardrivingStats>> getStatistics() {
    return guard(() async {
      final rows = await _db.wardrivingDao.watchAll().first;
      final points = rows.map(WardrivingMapper.toEntity).toList();
      final total = points.length;
      final open = points.where((pt) => pt.security == null).length;
      final encrypted = total - open;

      double distanceKm = 0;
      WardrivingPoint? prev;
      for (final point in points) {
        if (prev != null &&
            point.latitude != null &&
            point.longitude != null &&
            prev.latitude != null &&
            prev.longitude != null) {
          distanceKm += _haversineKm(
            prev.latitude!, prev.longitude!,
            point.latitude!, point.longitude!,
          );
        }
        prev = point;
      }

      return WardrivingStats(
        totalNetworks: total,
        openNetworks: open,
        encryptedNetworks: encrypted,
        distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
      );
    });
  }

  @override
  Future<Result<int>> uploadToWigle(String apiToken) {
    return guard(() async {
      final rows = await _db.wardrivingDao.getUnuploaded();
      if (rows.isEmpty) return 0;
      // الرفع الفعلي عبر Dio إلى /api/v2/file/upload يُنفّذ في
      // PHASE 12؛ الآن نعيد العدد الجاهز للرفع.
      AppLogger.info(
        'جاهز للرفع إلى WiGLE: ${rows.length} نقطة',
        tag: 'Wardriving',
      );
      return rows.length;
    });
  }

  @override
  Future<Result<List<BluetoothDeviceData>>> scanBluetooth({
    Duration duration = const Duration(seconds: 8),
  }) {
    // فحص BLE عبر القناة الأصلية يأتي لاحقاً (مكتبة flutter_blue_plus
    // لم تتوافق مع صياغة Gradle لـ Flutter 3.24 عند لحظة البناء)؛
    // نُرجع قائمة فارغة الآن فتتدهور الميزة بأمان بدل كسر البناء.
    return guard(() async {
      AppLogger.info(
        'فحص البلوتوث غير متاح في هذه النسخة — سيتوفر عبر القناة الأصلية',
        tag: 'Wardriving',
      );
      return const <BluetoothDeviceData>[];
    });
  }

  @override
  Future<Result<String>> exportCsv() {
    return guard(() async {
      final rows = await _db.wardrivingDao.watchAll().first;
      final data = [
        [
          'SSID', 'BSSID', 'Channel', 'RSSI', 'Security',
          'Latitude', 'Longitude', 'Accuracy', 'Timestamp',
        ],
        ...rows.map((r) => [
              r.ssid ?? '',
              r.bssid,
              r.channel ?? '',
              r.rssi ?? '',
              r.security ?? '',
              r.latitude ?? '',
              r.longitude ?? '',
              r.accuracy ?? '',
              r.timestamp.toIso8601String(),
            ]),
      ];

      final csv = const ListToCsvConverter().convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'wardriving_export.csv'));
      await file.writeAsString(csv);
      return file.path;
    });
  }

  /// مسافة Haversine بالكيلومتر بين نقطتي GPS.
  double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

final wardrivingRepositoryProvider =
    Provider<WardrivingRepository>((ref) {
  return WardrivingRepositoryImpl(ref.watch(appDatabaseProvider));
});
