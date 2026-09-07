import 'package:freezed_annotation/freezed_annotation.dart';

part 'heatmap.freezed.dart';

/// نقطة قياس إشارة على الخريطة (مع موضع على صورة المسح أو إحداثي).
@freezed
class SignalSample with _$SignalSample {
  const factory SignalSample({
    required int rssi,
    double? x, // موضع نسبي على صورة مخطط الطابق (0–1)
    double? y,
    double? latitude,
    double? longitude,
    required DateTime capturedAt,
    String? bssid,
    String? ssid,
  }) = _SignalSample;
}

/// مسح موقع (Site Survey) بمخطط طابق وعينات إشارة.
@freezed
class SiteSurvey with _$SiteSurvey {
  const SiteSurvey._();

  const factory SiteSurvey({
    int? id,
    required String name,
    String? floor,
    String? imagePath,
    double? latitude,
    double? longitude,
    @Default([]) List<SignalSample> samples,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SiteSurvey;

  /// متوسط قوة الإشارة في الموقع (مؤشر جودة التغطية العام).
  double get averageRssi {
    if (samples.isEmpty) return 0;
    return samples.map((s) => s.rssi).reduce((a, b) => a + b) / samples.length;
  }

  /// أضعف نقطة في التغطية — لاقتراح تقوية/نقل نقطة وصول.
  SignalSample? get weakestSpot {
    if (samples.isEmpty) return null;
    return samples.reduce((a, b) => a.rssi < b.rssi ? a : b);
  }
}
