import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../domain/entities/access_point.dart';
import '../../domain/entities/channel_analysis.dart';

/// تحويلات نقاط الوصول وتحليل القنوات.
class WifiMapper {
  const WifiMapper._();

  static AccessPoint toAccessPointEntity(AccessPointRow r) => AccessPoint(
        bssid: r.bssid,
        ssid: r.ssid,
        channel: r.channel ?? 0,
        frequencyMhz: r.frequency,
        rssi: r.rssi ?? -100,
        security: _parseSecurity(r.security),
        capabilities: r.capabilities,
        vendor: r.vendor,
        channelWidthMhz: r.width,
        band: _parseBand(r.band),
        lastSeen: r.lastSeen,
        isHidden: r.isHidden,
      );

  static AccessPointsCompanion toAccessPointCompanion(AccessPoint ap) =>
      AccessPointsCompanion(
        ssid: Value(ap.ssid),
        bssid: Value(ap.bssid),
        channel: Value(ap.channel),
        frequency: Value(ap.frequencyMhz),
        rssi: Value(ap.rssi),
        security: Value(ap.security.name),
        capabilities: Value(ap.capabilities),
        vendor: Value(ap.vendor),
        width: Value(ap.channelWidthMhz),
        band: Value(_bandString(ap.band)),
        lastSeen: Value(ap.lastSeen),
        isHidden: Value(ap.isHiddenNetwork),
      );

  static ChannelRating toChannelRatingEntity(ChannelAnalysisRow r) =>
      ChannelRating(
        channel: r.channel,
        band: _parseBand(r.band),
        accessPointCount: r.apCount,
        noiseDbm: r.noiseLevel,
        interferenceScore: r.interferenceScore ?? 0,
        rating: r.rating ?? 3,
        recommendedAccessPoints: const [],
        analyzedAt: r.analyzedAt,
      );

  static ChannelAnalysisCompanion toChannelAnalysisCompanion(
          ChannelRating c) =>
      ChannelAnalysisCompanion(
        channel: Value(c.channel),
        band: Value(_bandString(c.band)),
        apCount: Value(c.accessPointCount),
        noiseLevel: Value(c.noiseDbm),
        interferenceScore: Value(c.interferenceScore),
        rating: Value(c.rating),
        recommendedAps: Value(c.recommendedAccessPoints.join(',')),
        analyzedAt: Value(c.analyzedAt),
      );

  static WifiSecurity _parseSecurity(String? raw) {
    if (raw == null) return WifiSecurity.unknown;
    final lower = raw.toLowerCase();
    if (lower.contains('wpa3')) return WifiSecurity.wpa3;
    if (lower.contains('enterprise')) return WifiSecurity.wpaEnterprise;
    if (lower.contains('wpa2')) return WifiSecurity.wpa2;
    if (lower.contains('wpa')) return WifiSecurity.wpa;
    if (lower.contains('wep')) return WifiSecurity.wep;
    if (lower.contains('open')) return WifiSecurity.open;
    return WifiSecurity.unknown;
  }

  static String _bandString(WifiBand band) => switch (band) {
        WifiBand.ghz24 => '2.4GHz',
        WifiBand.ghz5 => '5GHz',
        WifiBand.ghz6 => '6GHz',
      };

  static WifiBand _parseBand(String? raw) => switch (raw) {
        '5GHz' => WifiBand.ghz5,
        '6GHz' => WifiBand.ghz6,
        _ => WifiBand.ghz24,
      };
}
