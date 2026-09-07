import 'package:freezed_annotation/freezed_annotation.dart';

import 'device.dart';

part 'router.freezed.dart';

/// أنواع الراوترات المدعومة (10 + عام).
enum RouterBrand {
  tpLink,
  dLink,
  huawei,
  xiaomi,
  cisco,
  asus,
  netgear,
  zte,
  tenda,
  generic,
}

/// بيانات اتصال الراوتر المحفوظة (كلمة المرور في الخزن الآمن).
@freezed
class RouterInfo with _$RouterInfo {
  const factory RouterInfo({
    int? id,
    @Default(RouterBrand.generic) RouterBrand brand,
    required String ip,
    String? username,
    String? model,
    String? firmware,
    String? macAddress,
    DateTime? lastConnected,
    @Default(false) bool isActive,
  }) = _RouterInfo;
}

/// إعدادات واي فاي الراوتر.
@freezed
class RouterWifiSettings with _$RouterWifiSettings {
  const factory RouterWifiSettings({
    required String ssid,
    required String password,
    @Default(6) int channel,
    @Default('WPA2PSK') String security,
    @Default(true) bool isEnabled,
    @Default(false) bool isHidden,
    @Default(20) int channelWidth,
  }) = _RouterWifiSettings;
}

/// إعدادات شبكة الضيوف.
@freezed
class GuestNetwork with _$GuestNetwork {
  const factory GuestNetwork({
    required String ssid,
    required String password,
    @Default(false) bool isEnabled,
    @Default(10240) int speedLimitKbps,
    @Default(true) bool isolateClients,
  }) = _GuestNetwork;
}

/// قاعدة توجيه منافذ (Port Forwarding).
@freezed
class PortForwardRule with _$PortForwardRule {
  const factory PortForwardRule({
    String? id,
    required String name,
    required int externalPort,
    required int internalPort,
    required String internalIp,
    @Default('TCP') String protocol,
    @Default(true) bool enabled,
  }) = _PortForwardRule;
}

/// قاعدة تصفية MAC (سماح/حظر).
@freezed
class MacFilterEntry with _$MacFilterEntry {
  const factory MacFilterEntry({
    required String mac,
    String? name,
    @Default(true) bool isAllowed,
  }) = _MacFilterEntry;
}

/// جهاز متصل بالراوتر كما يراه الراوتر نفسه.
@freezed
class RouterClient with _$RouterClient {
  const factory RouterClient({
    required String mac,
    required String ip,
    String? name,
    @Default(ConnectionType.unknown) ConnectionType connectionType,
    @Default(0) int upSpeedKbps,
    @Default(0) int downSpeedKbps,
    @Default(0) int dataLimitKbps,
  }) = _RouterClient;
}

/// إحصائيات حركة الراوتر الكلية.
@freezed
class RouterTrafficStats with _$RouterTrafficStats {
  const factory RouterTrafficStats({
    @Default(0) int connectedClients,
    @Default(0) int totalUploadKbps,
    @Default(0) int totalDownloadKbps,
    @Default(0) int uptimeSeconds,
    double? cpuUsage,
    double? memoryUsage,
  }) = _RouterTrafficStats;
}
