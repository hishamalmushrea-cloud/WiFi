import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/mac_utils.dart';

part 'device.freezed.dart';

/// نوع الجهاز المكتشف — يقود الأيقونة والتسمية في الواجهة.
enum DeviceType {
  unknown,
  router,
  phone,
  laptop,
  desktop,
  tablet,
  tv,
  camera,
  printer,
  iot,
  nas,
  gameConsole,
  wearable,
  smartHome,
}

/// طريقة اتصال الجهاز بالشبكة.
enum ConnectionType { wifi, ethernet, unknown }

/// جهاز مكتشف على الشبكة المحلية.
///
/// كيان المجال المركزي: يُبنى من صف قاعدة البيانات في طبقة البيانات
/// ويستهلكه كل من الفحص والأمان والتحكم بالراوتر. منطق العرض
/// (هل هو متصل؟ الاسم المعروض) مشتق هنا لا في الويدجت.
@freezed
class Device with _$Device {
  const Device._();

  const factory Device({
    required int id,
    required String ip,
    required String mac,
    String? name,
    String? vendor,
    String? os,
    @Default(DeviceType.unknown) DeviceType type,
    String? fingerprint,
    String? hostname,
    @Default(ConnectionType.unknown) ConnectionType connectionType,
    int? signalStrength,
    int? throughputKbps,
    @Default(false) bool isBlocked,
    int? speedLimitKbps,
    @Default(0) int dataUsageBytes,
    required DateTime firstSeen,
    required DateTime lastSeen,
    @Default(false) bool isFavorite,
    @Default(false) bool isKnown,
    String? notes,
  }) = _Device;

  /// نافذة «الاتصال»: جهاز رأيناه خلال آخر 3 دقائق يُعدّ متصلاً.
  /// السبب: فحص LAN لا يبقي اتصالاً حياً، فحداثة الظهور هي الدليل.
  static const Duration onlineWindow = Duration(minutes: 3);

  bool get isOnline =>
      DateTime.now().difference(lastSeen) < onlineWindow;

  /// الاسم الأكثر إنسانية المتاح: اسم المستخدم ثم المضيف ثم المصنّع.
  String get displayName => name ?? hostname ?? vendor ?? 'جهاز غير معروف';

  /// هل يستخدم هذا الجهاز عنوان MAC عشوائياً؟
  /// (تقوم به الهواتف الحديثة لإخفاء هويتها) — يفيد تحليل الأمان
  /// لأن الجهاز ذا الـ MAC العشوائي قد يكون زائراً لا جهازاً دائماً.
  bool get isRandomMac => MacUtils.isLocallyAdministered(mac);
}

/// نقطة في السجل التاريخي لحالة جهاز عبر الزمن.
@freezed
class DeviceHistoryEntry with _$DeviceHistoryEntry {
  const factory DeviceHistoryEntry({
    required int id,
    required int deviceId,
    required DateTime timestamp,
    required bool isOnline,
    int? rssi,
    ConnectionType? connectionType,
    int? throughputKbps,
    String? ipAddress,
  }) = _DeviceHistoryEntry;
}
