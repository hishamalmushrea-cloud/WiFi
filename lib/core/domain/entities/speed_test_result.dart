import 'package:freezed_annotation/freezed_annotation.dart';

part 'speed_test_result.freezed.dart';

/// نوع اختبار السرعة.
enum SpeedTestType { standard, video, dns }

/// مرحلة اختبار السرعة الحالية (لتحريك الواجهة).
enum SpeedTestPhase { idle, ping, download, upload, done }

/// نتيجة اختبار سرعة واحد.
@freezed
class SpeedTestResult with _$SpeedTestResult {
  const SpeedTestResult._();

  const factory SpeedTestResult({
    int? id,
    required double downloadMbps,
    required double uploadMbps,
    required double pingMs,
    @Default(0) double jitterMs,
    String? serverName,
    String? serverLocation,
    String? serverUrl,
    String? isp,
    String? connectionType,
    @Default(SpeedTestType.standard) SpeedTestType testType,
    required DateTime timestamp,
  }) = _SpeedTestResult;

  /// تصنيف نوعي للسرعة لرسائل الواجهة.
  String get qualityLabel {
    if (downloadMbps >= 100) return 'ممتاز';
    if (downloadMbps >= 50) return 'جيد جداً';
    if (downloadMbps >= 25) return 'جيد';
    if (downloadMbps >= 10) return 'مقبول';
    return 'ضعيف';
  }
}

/// تقدّم اختبار السرعة الحيّ (يُبث للواجهة أثناء القياس).
@freezed
class SpeedTestProgress with _$SpeedTestProgress {
  const factory SpeedTestProgress({
    @Default(SpeedTestPhase.idle) SpeedTestPhase phase,
    @Default(0) double percent,
    @Default(0) double currentMbps,
    @Default(0) double currentPingMs,
  }) = _SpeedTestProgress;
}

/// معلومات خادم اختبار السرعة.
@freezed
class SpeedTestServer with _$SpeedTestServer {
  const factory SpeedTestServer({
    required String id,
    required String name,
    required String location,
    required String host,
    double? distanceKm,
    int? lat,
    int? lon,
  }) = _SpeedTestServer;
}
