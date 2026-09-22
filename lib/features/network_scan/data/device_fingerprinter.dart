import '../../../core/domain/entities/device.dart';
import '../../../core/domain/entities/discovered_service.dart';

/// بصمة الأجهزة: استنتاج النوع/النظام من المصنّع والخدمات والمضيف.
///
/// السبب: الماسح يكتشف IP و MAC فقط، بينما يقدّر المستخدم معرفة
/// «هذا الهاتف/التلفاز/الطابعة». نستخدم دلائل متعددة:
///  1) كلمات مفتاحية في اسم المصنّع/المضيف.
///  2) خدمات mDNS/Bonjour المُعلَنة (airplay ⇒ Apple، cast ⇒ تلفاز).
///  3) منافذ مفتوحة مميّزة.
class DeviceFingerprinter {
  const DeviceFingerprinter._();

  /// يستنتج نوع الجهاز من المعطيات المتاحة.
  static DeviceType inferType({
    String? vendor,
    String? hostname,
    List<DiscoveredService> services = const [],
    List<int> openPorts = const [],
  }) {
    final haystack = '${vendor ?? ''} ${hostname ?? ''} '
            '${services.map((s) => s.name).join(' ')}'
        .toLowerCase();
    final types = services.map((s) => s.type).join(' ');

    // أجهزة Apple عبر AirPlay/HomeKit/RAOP.
    if (types.contains('_airplay') ||
        types.contains('_raop') ||
        types.contains('_hap')) {
      if (haystack.contains('tv') || types.contains('_airplay')) {
        return DeviceType.tv;
      }
      return DeviceType.phone;
    }
    if (haystack.contains('chromecast') ||
        types.contains('_googlecast') ||
        haystack.contains('google tv')) {
      return DeviceType.tv;
    }

    // الطابعات.
    if (types.contains('_ipp') ||
        types.contains('_printer') ||
        types.contains('_pdl-datastream') ||
        openPorts.contains(9100) ||
        openPorts.contains(515) ||
        haystack.contains('printer') ||
        haystack.contains('طباعة')) {
      return DeviceType.printer;
    }

    // التخزين الشبكي (NAS).
    if (openPorts.contains(2049) ||
        openPorts.contains(548) ||
        haystack.contains('nas') ||
        haystack.contains('synology') ||
        haystack.contains('qnap')) {
      return DeviceType.nas;
    }

    // كلمات المصنّع/المضيف المميزة.
    bool has(List<String> keys) =>
        keys.any((k) => haystack.contains(k.toLowerCase()));

    if (has(['iphone', 'ipad', 'apple', 'macbook', 'imac'])) {
      if (has(['macbook', 'imac'])) return DeviceType.laptop;
      if (has(['ipad'])) return DeviceType.tablet;
      return DeviceType.phone;
    }
    if (has(['samsung', 'galaxy', 'huawei', 'xiaomi', 'redmi', 'oppo',
        'vivo', 'oneplus', 'pixel', 'honor'])) {
      return DeviceType.phone;
    }
    if (has(['smart-tv', 'smarttv', 'tv ', 'bravia', 'lg tv', 'roku',
        'firetv'])) {
      return DeviceType.tv;
    }
    if (has(['camera', 'cam', 'dahua', 'hikvision', 'wyze'])) {
      return DeviceType.camera;
    }
    if (has(['echo', 'alexa', 'nest', 'homepod', 'smartthings'])) {
      return DeviceType.smartHome;
    }
    if (has(['playstation', 'xbox', 'nintendo', 'steam'])) {
      return DeviceType.gameConsole;
    }
    if (has(['watch', 'band', 'fitbit', 'garmin'])) {
      return DeviceType.wearable;
    }
    if (has(['desktop', 'pc', 'server', 'workstation'])) {
      return DeviceType.desktop;
    }
    if (has(['laptop', 'notebook', 'thinkpad'])) {
      return DeviceType.laptop;
    }
    if (has(['espressif', 'esp32', 'esp8266', 'tasmota', 'sonoff',
        'zigbee', 'mqtt'])) {
      return DeviceType.iot;
    }

    // منافذ مميّزة لأجهزة الحاسب.
    if (openPorts.contains(3389) || openPorts.contains(445)) {
      return DeviceType.desktop;
    }

    return DeviceType.unknown;
  }

  /// تخمين نظام التشغيل من بصمة TTL والخدمات (محدود بدون Root).
  static String? guessOs({
    String? vendor,
    List<DiscoveredService> services = const [],
    int? initialTtl,
  }) {
    final types = services.map((s) => s.type).join(' ');
    if (types.contains('_airplay') ||
        types.contains('_raop') ||
        (vendor ?? '').toLowerCase().contains('apple')) {
      return 'iOS / iPadOS / macOS';
    }
    if (types.contains('_googlecast')) return 'Android / Chrome OS';
    if (initialTtl != null) {
      // بصمة TTL تقريبية: 64 ⇒ Linux/Android/macOS، 128 ⇒ Windows.
      if (initialTtl >= 60 && initialTtl <= 64) return 'Linux / Android';
      if (initialTtl >= 120 && initialTtl <= 128) return 'Windows';
    }
    return null;
  }
}
