import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../domain/entities/access_point.dart';
import '../../domain/entities/wardriving.dart';

/// تحويلات بيانات الـ Wardriving.
class WardrivingMapper {
  const WardrivingMapper._();

  static WardrivingPoint toEntity(WardrivingDatumRow r) => WardrivingPoint(
        id: r.id,
        ssid: r.ssid,
        bssid: r.bssid,
        channel: r.channel,
        rssi: r.rssi,
        security: r.security == null
            ? null
            : WifiSecurity.values
                .firstWhere((s) => s.name == r.security,
                    orElse: () => WifiSecurity.unknown),
        capabilities: r.capabilities,
        latitude: r.latitude,
        longitude: r.longitude,
        accuracyMeters: r.accuracy,
        altitude: r.altitude,
        timestamp: r.timestamp,
        uploaded: r.uploaded,
      );

  static WardrivingDataCompanion toCompanion(WardrivingPoint p) =>
      WardrivingDataCompanion(
        ssid: Value(p.ssid),
        bssid: Value(p.bssid),
        channel: Value(p.channel),
        rssi: Value(p.rssi),
        security: Value(p.security?.name),
        capabilities: Value(p.capabilities),
        latitude: Value(p.latitude),
        longitude: Value(p.longitude),
        accuracy: Value(p.accuracyMeters),
        altitude: Value(p.altitude),
        timestamp: Value(p.timestamp),
        uploaded: Value(p.uploaded),
      );
}
