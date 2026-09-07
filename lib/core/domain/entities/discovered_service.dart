import 'package:freezed_annotation/freezed_annotation.dart';

part 'discovered_service.freezed.dart';

/// خدمة مكتشفة على الشبكة المحلية (mDNS/Bonjour أو UPnP).
///
/// تُثري بصمة الجهاز: جهاز يعلن عن `_airplay._tcp` هو غالباً
/// جهاز Apple، و`_googlecast._tcp` جهاز Chromecast/تلفاز…
@freezed
class DiscoveredService with _$DiscoveredService {
  const factory DiscoveredService({
    required String name,
    required String type,
    String? host,
    String? ip,
    int? port,
    @Default('mdns') String source,
    @Default(<String, String>{}) Map<String, String> attributes,
  }) = _DiscoveredService;
}
