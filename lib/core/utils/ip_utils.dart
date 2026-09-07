import 'dart:math' as math;

/// أدوات معالجة عناوين IPv4 وحساب الشبكات الفرعية.
///
/// سبب وجودها: الفحص يحتاج تعداد كل المضيفين في /24،
/// وحاسبة الشبكات الفرعية (ميزة 34/35) تحتاج حسابات CIDR دقيقة.
/// نعتمد على تمثيل صحيح 32-بت بدون إشارة عبر & 0xFFFFFFFF.
class IpUtils {
  IpUtils._();

  /// يحوّل نص مثل "192.168.1.10" إلى قيمة 32-بت.
  /// يرجع null إن كان العنوان غير صالح.
  static int? toInt(String ip) {
    final parts = ip.trim().split('.');
    if (parts.length != 4) return null;
    var value = 0;
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) return null;
      value = (value << 8) | octet;
    }
    return value & 0xFFFFFFFF;
  }

  /// يحوّل قيمة 32-بت إلى نص "a.b.c.d".
  static String fromInt(int value) {
    final v = value & 0xFFFFFFFF;
    return [
      (v >> 24) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 8) & 0xFF,
      v & 0xFF,
    ].join('.');
  }

  /// هل العنوان صالح التنسيق؟
  static bool isValid(String ip) => toInt(ip) != null;

  /// قناع الشبكة من بادئة CIDR (مثلاً /24 → 255.255.255.0).
  static String subnetMask(int prefixLength) {
    final p = prefixLength.clamp(0, 32);
    final mask = p == 0 ? 0 : (0xFFFFFFFF << (32 - p)) & 0xFFFFFFFF;
    return fromInt(mask);
  }

  /// عنوان الشبكة (أول عنوان) لعنوان وبادئة.
  static String networkAddress(String ip, int prefixLength) {
    final value = toInt(ip);
    if (value == null) return ip;
    final mask = (0xFFFFFFFF << (32 - prefixLength.clamp(0, 32))) & 0xFFFFFFFF;
    return fromInt(value & mask);
  }

  /// عنوان البث (آخر عنوان).
  static String broadcastAddress(String ip, int prefixLength) {
    final value = toInt(ip);
    if (value == null) return ip;
    final mask = (0xFFFFFFFF << (32 - prefixLength.clamp(0, 32))) & 0xFFFFFFFF;
    return fromInt((value & mask) | (~mask & 0xFFFFFFFF));
  }

  /// نطاق المضيفين الصالحين (أول/آخر عنوان قابل للاستخدام).
  static ({String first, String last, int count}) hostRange(
      String ip, int prefixLength) {
    final network = toInt(networkAddress(ip, prefixLength))!;
    final broadcast = toInt(broadcastAddress(ip, prefixLength))!;
    // الشبكات /31 و /32 حالة خاصة: لا يوجد عنوان شبكة/بث محجوزان.
    if (prefixLength >= 31) {
      return (first: fromInt(network), last: fromInt(broadcast), count: broadcast - network + 1);
    }
    return (
      first: fromInt(network + 1),
      last: fromInt(broadcast - 1),
      count: broadcast - network - 1,
    );
  }

  /// يعدد كل عناوين المضيفين في شبكة العنوان.
  /// حد أقصى [limit] لمنع محاولة تعداد /8 بالكامل بلا داعٍ.
  static List<String> enumerateHosts(String ip, int prefixLength,
      {int limit = 1024}) {
    final range = _range(ip, prefixLength);
    if (range == null) return const [];
    final (networkStart: start, broadcastEnd: end) = range;
    final count = math.min(end - start + 1, limit);
    return List.generate(count, (i) => fromInt(start + i));
  }

  /// النطاق الخام (البداية والنهاية) لحسابات التعداد.
  static ({int networkStart, int broadcastEnd})? _range(
      String ip, int prefixLength) {
    final value = toInt(ip);
    if (value == null) return null;
    final p = prefixLength.clamp(0, 32);
    final mask = p == 0 ? 0 : (0xFFFFFFFF << (32 - p)) & 0xFFFFFFFF;
    final network = value & mask;
    final broadcast = network | (~mask & 0xFFFFFFFF);
    return (networkStart: network, broadcastEnd: broadcast);
  }

  /// هل العنوان ضمن نطاق خاص (LAN)؟ نستخدمه لتوجيه الفحص محلياً.
  static bool isPrivate(String ip) {
    final v = toInt(ip);
    if (v == null) return false;
    // 10.0.0.0/8
    if (v >= 0x0A000000 && v <= 0x0AFFFFFF) return true;
    // 172.16.0.0/12
    if (v >= 0xAC100000 && v <= 0xAC1FFFFF) return true;
    // 192.168.0.0/16
    if (v >= 0xC0A80000 && v <= 0xC0A8FFFF) return true;
    return false;
  }

  /// تحويل النطاق الخاص من عنوان IP إلى /24 المحلي (الأكثر شيوعاً).
  static int guessPrefix(String ip) => isPrivate(ip) ? 24 : 32;
}
