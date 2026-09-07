import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/data/mappers/wifi_mappers.dart';
import '../../../core/domain/entities/access_point.dart';
import '../../../core/domain/entities/channel_analysis.dart';
import '../../../core/domain/repositories/wifi_analysis_repository.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/app_logger.dart';
import 'wifi_channel_analyzer.dart';

/// تنفيذ مستودع تحليل الواي فاي.
///
/// قراءة نقاط الوصول المحيطة تحتاج صلاحيات موقع وواجهة نظام
/// غير متاحة مباشرة عبر Flutter، فتُقرأ عبر القناة الأصلية
/// (Kotlin WifiManager / iOS NEHotspotConfiguration — PHASE 11).
/// حتى وصولها، يوفّر المستودع التحليل والعرض بما يتوفر محلياً،
/// ويتدهور بأمان (قائمة فارغة) عند غياب القناة.
class WifiAnalysisRepositoryImpl implements WifiAnalysisRepository {
  WifiAnalysisRepositoryImpl(this._channel, this._db);

  final MethodChannel _channel;
  final AppDatabase _db;

  final _apController = StreamController<List<AccessPoint>>.broadcast();
  List<AccessPoint> _lastAps = const [];

  @override
  Stream<List<AccessPoint>> watchAccessPoints() async* {
    yield _lastAps;
    yield* _apController.stream;
  }

  @override
  Future<Result<List<AccessPoint>>> scanAccessPoints() async {
    return guard(() async {
      List<AccessPoint> aps;
      try {
        final raw = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
          'scanWifi',
        );
        aps = (raw ?? const [])
            .map(_mapRawAp)
            .where((e) => e != null)
            .cast<AccessPoint>()
            .toList();
      } on MissingPluginException {
        AppLogger.warning(
          'قناة مسح WiFi غير متاحة بعد (PHASE 11) — عرض المحفوظ',
          tag: 'WifiScan',
        );
        final saved = await _db.accessPointDao.watchAll().first;
        aps = saved.map(WifiMapper.toAccessPointEntity).toList();
      }

      // حدّث التردد→قناة والنطاق إن لزم.
      aps = aps.map(_normalize).toList();
      _lastAps = aps;
      _apController.add(aps);

      // خزّن النتيجة في القاعدة للمقارنة التاريخية.
      await _db.accessPointDao
          .upsertMany(aps.map(WifiMapper.toAccessPointCompanion).toList());
      return aps;
    });
  }

  @override
  Future<Result<WifiAnalysisResult>> analyze(List<AccessPoint> aps) async {
    return guard(() async {
      // التحليل حساب لحظي في الذاكرة؛ نحفظ ملخص كل نطاق دفعة واحدة
      // (لا نستبدل داخل الحلقة حتى لا تُمسح تقييمات القنوات السابقة).
      final result = WifiChannelAnalyzer.analyze(aps);
      for (final band in [WifiBand.ghz24, WifiBand.ghz5, WifiBand.ghz6]) {
        final ratings = result.channelRatings
            .where((r) => r.band == band)
            .toList();
        if (ratings.isNotEmpty) {
          await _db.channelAnalysisDao.replaceForBand(
            _bandName(band),
            ratings.map(WifiMapper.toChannelAnalysisCompanion).toList(),
          );
        }
      }
      return result;
    });
  }

  @override
  Future<Result<ChannelRecommendation?>> recommendChannel(WifiBand band) {
    return guard(() async {
      final result = WifiChannelAnalyzer.analyze(_lastAps);
      for (final r in result.recommendations) {
        if (r.band == band) return r;
      }
      return null;
    });
  }

  @override
  Future<Result<List<AccessPoint>>> getSavedAccessPoints() {
    return guard(() async {
      final rows = await _db.accessPointDao.watchAll().first;
      return rows.map(WifiMapper.toAccessPointEntity).toList();
    });
  }

  // ── أدوات التحويل ──────────────────────────────────────────
  AccessPoint? _mapRawAp(Map<dynamic, dynamic> raw) {
    try {
      final freq = (raw['frequency'] as num?)?.toInt();
      final channel = (raw['channel'] as num?)?.toInt() ??
          WifiChannelAnalyzer.channelForFrequency(freq ?? 0) ??
          0;
      final rssi = (raw['rssi'] as num?)?.toInt() ?? -100;
      final capabilities = raw['capabilities'] as String?;
      return AccessPoint(
        bssid: raw['bssid'] as String? ?? '',
        ssid: raw['ssid'] as String?,
        channel: channel,
        frequencyMhz: freq,
        rssi: rssi,
        security: _parseSecurity(capabilities),
        capabilities: capabilities,
        band: AccessPoint.bandForFrequency(freq, WifiBand.ghz24),
        channelWidthMhz: (raw['width'] as num?)?.toInt() ?? 20,
        lastSeen: DateTime.now(),
        isHidden: raw['isHidden'] == true || (raw['ssid'] == null),
      );
    } catch (e) {
      return null;
    }
  }

  AccessPoint _normalize(AccessPoint ap) {
    if (ap.frequencyMhz != null && ap.channel == 0) {
      final ch = WifiChannelAnalyzer.channelForFrequency(ap.frequencyMhz!);
      if (ch != null) {
        return AccessPoint(
          bssid: ap.bssid,
          ssid: ap.ssid,
          channel: ch,
          frequencyMhz: ap.frequencyMhz,
          rssi: ap.rssi,
          security: ap.security,
          capabilities: ap.capabilities,
          vendor: ap.vendor,
          channelWidthMhz: ap.channelWidthMhz,
          band: AccessPoint.bandForFrequency(ap.frequencyMhz, ap.band),
          lastSeen: ap.lastSeen,
          isHidden: ap.isHidden,
        );
      }
    }
    return ap;
  }

  WifiSecurity _parseSecurity(String? caps) {
    final c = caps?.toUpperCase() ?? '';
    if (c.contains('WPA3')) return WifiSecurity.wpa3;
    if (c.contains('WPA2')) return WifiSecurity.wpa2;
    if (c.contains('WPA')) return WifiSecurity.wpa;
    if (c.contains('WEP')) return WifiSecurity.wep;
    if (c.isEmpty || c.contains('ESS')) return WifiSecurity.open;
    return WifiSecurity.unknown;
  }

  String _bandName(WifiBand band) => switch (band) {
        WifiBand.ghz24 => '2.4GHz',
        WifiBand.ghz5 => '5GHz',
        WifiBand.ghz6 => '6GHz',
      };
}

final wifiAnalysisRepositoryProvider =
    Provider<WifiAnalysisRepository>((ref) {
  return WifiAnalysisRepositoryImpl(
    const MethodChannel(AppConstants.channelNetwork),
    ref.watch(appDatabaseProvider),
  );
});
