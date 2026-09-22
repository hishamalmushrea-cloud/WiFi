import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_info.freezed.dart';

/// معلومات الشبكة المحلية الحالية للجهاز.
@freezed
class NetworkInfoData with _$NetworkInfoData {
  const factory NetworkInfoData({
    String? deviceIp,
    String? gatewayIp,
    int? prefixLength,
    String? subnet,
    String? wifiName,
    String? bssid,
    String? ipv6,
    String? publicIp,
  }) = _NetworkInfoData;
}

/// معلومات حية عن الشبكة بعد فحص سريع (أجهزة + إحصائيات).
@freezed
class NetworkOverview with _$NetworkOverview {
  const NetworkOverview._();

  const factory NetworkOverview({
    required NetworkInfoData info,
    @Default(0) int deviceCount,
    @Default(0) int onlineCount,
    @Default(0) int blockedCount,
    required DateTime scannedAt,
  }) = _NetworkOverview;

  int get guestCount => deviceCount;
}
