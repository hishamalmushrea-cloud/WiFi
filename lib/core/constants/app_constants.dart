import 'package:flutter/widgets.dart';

/// ثوابت التطبيق المركزية.
///
/// سبب وجود هذا الملف: منع أي قيم سحرية (magic numbers/strings)
/// متناثرة في الكود — كل القيم القابلة للتعديل في مكان واحد.
class AppConstants {
  AppConstants._();

  // ── هوية التطبيق ─────────────────────────────────────────────
  static const String appName = 'نت كونترول';
  static const String appNameEn = 'NetControl';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String packageName = 'com.netcontrol.app';

  // ── قيم الشبكة ───────────────────────────────────────────────
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 30);
  static const Duration scanTimeout = Duration(seconds: 20);

  /// عدد الخيوط المتزامنة عند فحص المنافذ — يوازن بين السرعة
  /// وعدم إغراق الشبكة المحلية بالحزم.
  static const int portScanConcurrency = 64;

  /// حجم دفعة فحص الأجهزة في الشبكة المحلية (ping متزامن).
  static const int lanScanBatchSize = 32;

  // ── أسماء قنوات الجسر الأصلية (Method Channels) ─────────────
  // تُستخدم في PHASE 11 بين Dart و Kotlin/Swift.
  static const String channelRootCheck = 'com.netcontrol.app/root_check';
  static const String channelNetwork = 'com.netcontrol.app/network';
  static const String channelArp = 'com.netcontrol.app/arp';
  static const String channelPacketCapture = 'com.netcontrol.app/packet_capture';

  // ── مفاتيح التخزين المحلي (SharedPreferences) ────────────────
  static const String keyThemeMode = 'settings.theme_mode';
  static const String keyLocale = 'settings.locale';
  static const String keyOnboardingComplete = 'settings.onboarding_complete';
  static const String keyAppLockEnabled = 'security.app_lock_enabled';
  static const String keyWigleApiToken = 'integrations.wigle_api_token';
  static const String keyLastAutoScan = 'scan.last_auto_scan';
  static const String keyBackgroundMonitoring = 'settings.background_monitoring';
  static const String keyNewDeviceAlerts = 'settings.new_device_alerts';

  // ── مفاتيح Secure Storage (قيم حساسة) ───────────────────────
  static const String keyDbCipherKey = 'security.db_cipher_key';
  static const String keyRouterCredsPrefix = 'router.credentials.';

  // ── قيود التصميم المتجاوب (Responsive Breakpoints) ──────────
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 1200;
  static const double maxContentWidth = 1400;

  static const int mobileGridColumns = 2;
  static const int tabletGridColumns = 3;
  static const int desktopGridColumns = 5;

  // ── نطاقات تردد WiFi ─────────────────────────────────────────
  static const List<int> channels24GHz = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
  static const List<int> channels5GHz = [
    36, 40, 44, 48, 52, 56, 60, 64,
    100, 104, 108, 112, 116, 120, 124, 128,
    132, 136, 140, 144, 149, 153, 157, 161, 165,
  ];
  static const List<int> channels6GHz = [
    1, 5, 9, 13, 17, 21, 25, 29, 33, 37, 41, 45, 49,
    53, 57, 61, 65, 69, 73, 77, 81, 85, 89, 93,
  ];

  // ── المنافذ الشائعة لفحص سريع ذكي ───────────────────────────
  static const Map<int, String> commonPorts = {
    20: 'FTP-DATA',
    21: 'FTP',
    22: 'SSH',
    23: 'Telnet',
    25: 'SMTP',
    53: 'DNS',
    67: 'DHCP',
    68: 'DHCP',
    80: 'HTTP',
    110: 'POP3',
    123: 'NTP',
    135: 'RPC',
    137: 'NetBIOS',
    138: 'NetBIOS',
    139: 'NetBIOS',
    143: 'IMAP',
    161: 'SNMP',
    192: 'SNMP',
    443: 'HTTPS',
    445: 'SMB',
    515: 'Printer',
    548: 'AFP',
    554: 'RTSP',
    631: 'IPP/طباعة',
    993: 'IMAPS',
    995: 'POP3S',
    1080: 'SOCKS',
    1433: 'MSSQL',
    1883: 'MQTT',
    2049: 'NFS',
    3000: 'Dev Server',
    3306: 'MySQL',
    3389: 'RDP',
    5060: 'SIP',
    5222: 'XMPP',
    5353: 'mDNS',
    5432: 'PostgreSQL',
    5900: 'VNC',
    6379: 'Redis',
    8080: 'HTTP-Proxy',
    8443: 'HTTPS-Alt',
    8888: 'HTTP-Alt',
    9100: 'Printer RAW',
    27017: 'MongoDB',
  };

  // ── روابط خارجية ─────────────────────────────────────────────
  static const String macVendorApiUrl = 'https://api.macvendors.com/';
  static const String wigleApiBase = 'https://api.wigle.net/api/v2/';

  // ── إعدادات اختبار السرعة ────────────────────────────────────
  static const Duration speedTestDuration = Duration(seconds: 15);
  static const int pingSampleCount = 30;
}

/// نطاقات الشاشة لاستخدامها مع LayoutBuilder في كل التخطيطات.
enum ScreenSize {
  mobile,
  tablet,
  desktop;

  static ScreenSize of(Size size) {
    if (size.width >= AppConstants.breakpointTablet) return ScreenSize.desktop;
    if (size.width >= AppConstants.breakpointMobile) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }
}
