import 'dart:convert';

import '../../database/app_database.dart';
import '../../domain/entities/heatmap.dart';

/// تحويلات مسوحات المواقع. عينات الإشارة تُسلسل JSON في عمود واحد.
class SurveyMapper {
  const SurveyMapper._();

  static SiteSurvey toEntity(WifiSurveyRow r) {
    List<SignalSample> samples = const [];
    if (r.samplesJson != null && r.samplesJson!.isNotEmpty) {
      try {
        final list = jsonDecode(r.samplesJson!) as List<dynamic>;
        samples = list
            .map((e) => SignalSample(
                  rssi: e['rssi'] as int? ?? -100,
                  x: (e['x'] as num?)?.toDouble(),
                  y: (e['y'] as num?)?.toDouble(),
                  latitude: (e['lat'] as num?)?.toDouble(),
                  longitude: (e['lng'] as num?)?.toDouble(),
                  capturedAt: DateTime.tryParse(e['at'] as String? ?? '') ??
                      DateTime.now(),
                  bssid: e['bssid'] as String?,
                  ssid: e['ssid'] as String?,
                ))
            .toList();
      } catch (_) {
        samples = const [];
      }
    }

    return SiteSurvey(
      id: r.id,
      name: r.name,
      floor: r.floor,
      imagePath: r.imageUrl,
      latitude: r.latitude,
      longitude: r.longitude,
      samples: samples,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  static WifiSurveysCompanion toCompanion(SiteSurvey s) =>
      WifiSurveysCompanion(
        id: s.id == null ? const Value.absent() : Value(s.id!),
        name: Value(s.name),
        floor: Value(s.floor),
        imageUrl: Value(s.imagePath),
        latitude: Value(s.latitude),
        longitude: Value(s.longitude),
        samplesJson: Value(_encodeSamples(s.samples)),
        createdAt: Value(s.createdAt),
        updatedAt: Value(s.updatedAt),
      );

  static String _encodeSamples(List<SignalSample> samples) {
    return jsonEncode(samples
        .map((e) => {
              'rssi': e.rssi,
              'x': e.x,
              'y': e.y,
              'lat': e.latitude,
              'lng': e.longitude,
              'at': e.capturedAt.toIso8601String(),
              'bssid': e.bssid,
              'ssid': e.ssid,
            })
        .toList());
  }
}
