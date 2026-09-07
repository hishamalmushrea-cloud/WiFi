import 'package:drift/drift.dart';

/// جداول قاعدة بيانات NetControl (15 جدولاً).
///
/// نسمّي صفوف Drift بـ «...Row» لتمييزها عن كيانات Domain Layer
/// التي ستبنى في PHASE 4 وتحمل أسماء الأعمال (Device، Alert…).
part of '../app_database.dart';

// ════════════════════════════════════════════════════════════════
//  1) الأجهزة المكتشفة على الشبكة
// ════════════════════════════════════════════════════════════════
@DataClassName('DeviceRow')
@TableIndex(name: 'idx_devices_last_seen', columns: {#lastSeen})
@TableIndex(name: 'idx_devices_blocked', columns: {#isBlocked})
class Devices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ip => text()();
  TextColumn get mac => text().unique()();
  TextColumn get name => text().nullable()();
  TextColumn get vendor => text().nullable()();
  TextColumn get os => text().nullable()();
  TextColumn get deviceType => text().withDefault(const Constant('unknown'))();
  TextColumn get fingerprint => text().nullable()();
  TextColumn get hostname => text().nullable()();
  TextColumn get connectionType => text().withDefault(const Constant('ethernet'))();
  IntColumn get signalStrength => integer().nullable()();
  IntColumn get throughput => integer().nullable()();
  BoolColumn get isBlocked => boolean().withDefault(const Constant(false))();
  IntColumn get speedLimitKbps => integer().nullable()();
  IntColumn get dataUsageBytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get firstSeen => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSeen => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isKnown => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
}

// ════════════════════════════════════════════════════════════════
//  2) السجل التاريخي لكل جهاز (حالة الاتصال والإشارة عبر الزمن)
// ════════════════════════════════════════════════════════════════
@DataClassName('DeviceHistoryRow')
@TableIndex(name: 'idx_history_device_time', columns: {#deviceId, #timestamp})
class DeviceHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  // نستخدم حذف متتالٍ (cascade) حتى لا تتراكم سجول يتيمة.
  IntColumn get deviceId =>
      integer().references(Devices, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isOnline => boolean()();
  IntColumn get rssi => integer().nullable()();
  TextColumn get connectionType => text().nullable()();
  IntColumn get throughput => integer().nullable()();
  TextColumn get ipAddress => text().nullable()();
}

// ════════════════════════════════════════════════════════════════
//  3) التنبيهات الأمنية
// ════════════════════════════════════════════════════════════════
@DataClassName('SecurityAlertRow')
@TableIndex(name: 'idx_alerts_timestamp', columns: {#timestamp})
@TableIndex(name: 'idx_alerts_resolved', columns: {#isResolved})
class SecurityAlerts extends Table {
  IntColumn get id => integer().autoIncrement()();
  // arp_spoofing | rogue_dhcp | evil_twin | deauth | intruder …
  TextColumn get type => text()();
  // low | medium | high | critical
  TextColumn get severity => text().withDefault(const Constant('medium'))();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get sourceIp => text().nullable()();
  TextColumn get sourceMac => text().nullable()();
  TextColumn get targetIp => text().nullable()();
  TextColumn get targetMac => text().nullable()();
  TextColumn get details => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
}

// ════════════════════════════════════════════════════════════════
//  4) نتائج اختبارات السرعة
// ════════════════════════════════════════════════════════════════
@DataClassName('SpeedTestRow')
@TableIndex(name: 'idx_speed_tests_time', columns: {#timestamp})
class SpeedTests extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get downloadMbps => real().nullable()();
  RealColumn get uploadMbps => real().nullable()();
  RealColumn get pingMs => real().nullable()();
  RealColumn get jitterMs => real().nullable()();
  TextColumn get serverName => text().nullable()();
  TextColumn get serverLocation => text().nullable()();
  TextColumn get serverUrl => text().nullable()();
  TextColumn get isp => text().nullable()();
  TextColumn get connectionType => text().nullable()();
  // standard | video | dns
  TextColumn get testType => text().withDefault(const Constant('standard'))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

// ════════════════════════════════════════════════════════════════
//  5) أحداث الشبكة (اتصال/انفصال/انقطاع/تغير سرعة)
// ════════════════════════════════════════════════════════════════
@DataClassName('NetworkEventRow')
@TableIndex(name: 'idx_events_time', columns: {#timestamp})
@TableIndex(name: 'idx_events_device', columns: {#deviceId})
class NetworkEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  // device_connected | device_disconnected | outage | speed_change
  TextColumn get eventType => text()();
  IntColumn get deviceId =>
      integer().nullable().references(Devices, #id, onDelete: KeyAction.setNull)();
  TextColumn get details => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get severity => text().withDefault(const Constant('low'))();
}

// ════════════════════════════════════════════════════════════════
//  6) إعدادات الراوترات المحفوظة (كلمة المرور مشفرة في الخزن الآمن)
// ════════════════════════════════════════════════════════════════
@DataClassName('RouterSettingRow')
class RouterSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get routerType => text()();
  TextColumn get ip => text()();
  TextColumn get username => text().nullable()();
  // مرجع/معرّف للكلمة المشفرة داخل Secure Storage — لا نخزّنها نصاً صريحاً.
  TextColumn get encryptedPassword => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get firmware => text().nullable()();
  TextColumn get macAddress => text().nullable()();
  DateTimeColumn get lastConnected => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
}

// ════════════════════════════════════════════════════════════════
//  7) مسوحات المواقع (للخرائط الحرارية، متعددة الطوابق)
// ════════════════════════════════════════════════════════════════
@DataClassName('WifiSurveyRow')
class WifiSurveys extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get floor => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ════════════════════════════════════════════════════════════════
//  8) بيانات Wardriving (الشبكات + إحداثيات GPS)
// ════════════════════════════════════════════════════════════════
@DataClassName('WardrivingDatumRow')
@TableIndex(name: 'idx_wardriving_bssid', columns: {#bssid})
@TableIndex(name: 'idx_wardriving_time', columns: {#timestamp})
@TableIndex(name: 'idx_wardriving_uploaded', columns: {#uploaded})
class WardrivingData extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ssid => text().nullable()();
  TextColumn get bssid => text()();
  IntColumn get channel => integer().nullable()();
  IntColumn get rssi => integer().nullable()();
  TextColumn get security => text().nullable()();
  TextColumn get capabilities => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get accuracy => real().nullable()();
  RealColumn get altitude => real().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();
}

// ════════════════════════════════════════════════════════════════
//  9) نتائج فحص المنافذ
// ════════════════════════════════════════════════════════════════
@DataClassName('PortScanResultRow')
@TableIndex(name: 'idx_ports_device', columns: {#deviceId})
class PortScanResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deviceId =>
      integer().references(Devices, #id, onDelete: KeyAction.cascade)();
  IntColumn get port => integer()();
  TextColumn get protocol => text().withDefault(const Constant('tcp'))();
  // open | closed | filtered
  TextColumn get state => text()();
  TextColumn get service => text().nullable()();
  TextColumn get version => text().nullable()();
  TextColumn get banner => text().nullable()();
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
}

// ════════════════════════════════════════════════════════════════
// 10) الثغرات المكتشفة لكل جهاز
// ════════════════════════════════════════════════════════════════
@DataClassName('VulnerabilityRow')
@TableIndex(name: 'idx_vulns_device', columns: {#deviceId})
class Vulnerabilities extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deviceId =>
      integer().references(Devices, #id, onDelete: KeyAction.cascade)();
  TextColumn get cveId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get severity => text().withDefault(const Constant('medium'))();
  RealColumn get cvssScore => real().nullable()();
  TextColumn get solution => text().nullable()();
  TextColumn get references => text().nullable()();
  DateTimeColumn get detectedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
}

// ════════════════════════════════════════════════════════════════
// 11) الجدول الزمني لنشاط الاتصالات
// ════════════════════════════════════════════════════════════════
@DataClassName('ActivityTimelineRow')
@TableIndex(name: 'idx_timeline_time', columns: {#startTime})
@TableIndex(name: 'idx_timeline_device', columns: {#deviceId})
class ActivityTimeline extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deviceId =>
      integer().nullable().references(Devices, #id, onDelete: KeyAction.setNull)();
  TextColumn get appName => text().nullable()();
  TextColumn get packageName => text().nullable()();
  TextColumn get destinationIp => text().nullable()();
  TextColumn get destinationHost => text().nullable()();
  IntColumn get port => integer().nullable()();
  TextColumn get protocol => text().nullable()();
  IntColumn get bytesSent => integer().withDefault(const Constant(0))();
  IntColumn get bytesReceived => integer().withDefault(const Constant(0))();
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endTime => dateTime().nullable()();
}

// ════════════════════════════════════════════════════════════════
// 12) سجلات DNS
// ════════════════════════════════════════════════════════════════
@DataClassName('DnsRecordRow')
@TableIndex(name: 'idx_dns_domain', columns: {#domain})
class DnsRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get domain => text()();
  // A | AAAA | MX | NS | TXT | SRV | CNAME
  TextColumn get recordType => text()();
  TextColumn get value => text()();
  IntColumn get ttl => integer().nullable()();
  DateTimeColumn get queriedAt => dateTime().withDefault(currentDateAndTime)();
}

// ════════════════════════════════════════════════════════════════
// 13) الشبكات المحفوظة
// ════════════════════════════════════════════════════════════════
@DataClassName('SavedNetworkRow')
class SavedNetworks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get ssid => text().nullable()();
  TextColumn get subnet => text().nullable()();
  TextColumn get gateway => text().nullable()();
  TextColumn get routerType => text().nullable()();
  DateTimeColumn get savedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUsed => dateTime().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
}

// ════════════════════════════════════════════════════════════════
// 14) نقاط الوصول المكتشفة (تحليل WiFi / Wardriving)
// ════════════════════════════════════════════════════════════════
@DataClassName('AccessPointRow')
@TableIndex(name: 'idx_aps_channel', columns: {#channel})
@TableIndex(name: 'idx_aps_band', columns: {#band})
class AccessPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ssid => text().nullable()();
  TextColumn get bssid => text().unique()();
  IntColumn get channel => integer().nullable()();
  IntColumn get frequency => integer().nullable()();
  IntColumn get rssi => integer().nullable()();
  TextColumn get security => text().nullable()();
  TextColumn get capabilities => text().nullable()();
  TextColumn get vendor => text().nullable()();
  // عرض القناة بالميغاهرتز: 20 | 40 | 80 | 160
  IntColumn get width => integer().nullable()();
  // 2.4GHz | 5GHz | 6GHz
  TextColumn get band => text().nullable()();
  DateTimeColumn get lastSeen => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
}

// ════════════════════════════════════════════════════════════════
// 15) تحليل القنوات (نتيجة دورية لتقييم الازدحام)
// ════════════════════════════════════════════════════════════════
@DataClassName('ChannelAnalysisRow')
@TableIndex(name: 'idx_channel_analysis_band', columns: {#band})
class ChannelAnalysis extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get channel => integer()();
  TextColumn get band => text()();
  IntColumn get apCount => integer().withDefault(const Constant(0))();
  IntColumn get noiseLevel => integer().nullable()();
  IntColumn get interferenceScore => integer().nullable()();
  // نجوم التقييم من 1 إلى 5
  IntColumn get rating => integer().nullable()();
  TextColumn get recommendedAps => text().nullable()();
  DateTimeColumn get analyzedAt => dateTime().withDefault(currentDateAndTime)();
}
