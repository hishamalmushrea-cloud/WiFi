import 'package:freezed_annotation/freezed_annotation.dart';

part 'access_point.freezed.dart';

/// نطاق تردد WiFi.
enum WifiBand { ghz24, ghz5, ghz6 }

/// نوع/مستوى تشفير الشبكة.
enum WifiSecurity {
  open,
  wep,
  wpa,
  wpa2,
  wpa3,
  wpaEnterprise,
  unknown,
}

/// نقطة وصول لاسلكية مكتشفة.
///
/// كيان يحمل بيانات المسح اللحظية اللازمة لتحليل القنوات
/// والتداخل ورسوم WiFi، مع منطق اشتقاق النطاق من التردد.
@freezed
class AccessPoint with _$AccessPoint {
  const AccessPoint._();

  const factory AccessPoint({
    required String bssid,
    String? ssid,
    required int channel,
    int? frequencyMhz,
    required int rssi,
    @Default(WifiSecurity.unknown) WifiSecurity security,
    String? capabilities,
    String? vendor,
    int? channelWidthMhz,
    @Default(WifiBand.ghz24) WifiBand band,
    required DateTime lastSeen,
    @Default(false) bool isHidden,
  }) = _AccessPoint;

  bool get isHiddenNetwork => isHidden || (ssid == null) || ssid!.trim().isEmpty;

  String get displaySsid => isHiddenNetwork ? 'شبكة مخفية' : ssid!;

  /// نسبة الإشارة (0–100) للعرض.
  int get signalPercent => ((rssi + 100) * 100 / 60).clamp(0, 100).round();

  /// يحدّد النطاق من تردد MHz إن توفّر — وإلا يبقى المعطى.
  static WifiBand bandForFrequency(int? freqMhz, WifiBand fallback) {
    if (freqMhz == null) return fallback;
    if (freqMhz >= 5925 && freqMhz <= 7125) return WifiBand.ghz6;
    if (freqMhz >= 4900 && freqMhz <= 5900) return WifiBand.ghz5;
    return WifiBand.ghz24;
  }
}
