import 'package:freezed_annotation/freezed_annotation.dart';

import 'access_point.dart';

part 'wardriving.freezed.dart';

/// نقطة رصد واي فاي أثناء الـ Wardriving (مع إحداثيات GPS).
@freezed
class WardrivingPoint with _$WardrivingPoint {
  const factory WardrivingPoint({
    int? id,
    String? ssid,
    required String bssid,
    int? channel,
    int? rssi,
    WifiSecurity? security,
    String? capabilities,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    double? altitude,
    required DateTime timestamp,
    @Default(false) bool uploaded,
  }) = _WardrivingPoint;
}

/// جهاز بلوتوث/BLE مكتشف.
@freezed
class BluetoothDeviceData with _$BluetoothDeviceData {
  const factory BluetoothDeviceData({
    required String id,
    required String name,
    String? mac,
    int? rssi,
    @Default(false) bool isLe,
    String? vendor,
  }) = _BluetoothDeviceData;
}

/// معلومات برج خلوي (تقريبية — تعتمد على توافرها من المنصة).
@freezed
class CellTowerInfo with _$CellTowerInfo {
  const factory CellTowerInfo({
    String? operatorName,
    int? mcc,
    int? mnc,
    int? lac,
    int? cid,
    int? signalDbm,
    @Default('') String generation,
  }) = _CellTowerInfo;
}

/// إحصائيات جلسة Wardriving.
@freezed
class WardrivingStats with _$WardrivingStats {
  const factory WardrivingStats({
    @Default(0) int totalNetworks,
    @Default(0) int openNetworks,
    @Default(0) int encryptedNetworks,
    @Default(0) int wpa3Networks,
    @Default(0) int wpa2Networks,
    @Default(0) int vendors,
    @Default(0.0) double distanceKm,
  }) = _WardrivingStats;
}
