import 'package:freezed_annotation/freezed_annotation.dart';

part 'security.freezed.dart';

/// شدة الحدث الأمني.
enum ThreatSeverity { low, medium, high, critical }

/// أنواع التهديدات التي يكشفها محرك الأمان.
enum SecurityAlertType {
  arpSpoofing,
  rogueDhcp,
  evilTwin,
  deauth,
  intruder,
  rogueAp,
  wpsVulnerability,
  openNetwork,
  weakEncryption,
  karmaAttack,
  pineap,
  other,
}

/// تنبيه أمني واحد.
@freezed
class SecurityAlert with _$SecurityAlert {
  const factory SecurityAlert({
    int? id,
    required SecurityAlertType type,
    required ThreatSeverity severity,
    required String title,
    String? description,
    String? sourceIp,
    String? sourceMac,
    String? targetIp,
    String? targetMac,
    String? details,
    required DateTime timestamp,
    @Default(false) bool isResolved,
    DateTime? resolvedAt,
  }) = _SecurityAlert;
}

/// مكوّنات مؤشر الأمان — كل بند يمثل فحصة بوزن.
@freezed
class SecurityCheck with _$SecurityCheck {
  const factory SecurityCheck({
    required String id,
    required String title,
    required String description,
    required bool passed,
    required int weight,
    String? recommendation,
  }) = _SecurityCheck;
}

/// نتيجة تقييم أمان الشبكة الكاملة.
@freezed
class SecurityScore with _$SecurityScore {
  const SecurityScore._();

  const factory SecurityScore({
    required int score, // 0–100
    required List<SecurityCheck> checks,
    required List<SecurityAlert> activeAlerts,
    required DateTime evaluatedAt,
  }) = _SecurityScore;

  /// تصنيف حرفي/لوني للدرجة.
  String get grade {
    if (score >= 85) return 'ممتاز';
    if (score >= 70) return 'جيد';
    if (score >= 50) return 'متوسط';
    if (score >= 30) return 'ضعيف';
    return 'حرج';
  }

  /// عدد التنبيهات الحرجة النشطة (للرايات في الواجهة).
  int get criticalCount =>
      activeAlerts.where((a) => a.severity == ThreatSeverity.critical).length;
}
