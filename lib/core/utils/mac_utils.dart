/// أدوات عناوين MAC.
class MacUtils {
  MacUtils._();

  /// أول 3 بايتات (OUI) تحدّد المصنّع — نستخدمها في lookup.
  /// مثال: "A4:83:E7:11:22:33" → "A483E7".
  static String? oui(String mac) {
    final clean = normalize(mac);
    if (clean == null || clean.length != 12) return null;
    return clean.substring(0, 6);
  }

  /// يطبّع العنوان بإزالة الفواصل/النقطتين وجعله أحرفاً كبيرة.
  static String? normalize(String mac) {
    final clean = mac
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('.', '')
        .trim()
        .toUpperCase();
    if (clean.length != 12) return null;
    if (!RegExp(r'^[0-9A-F]{12}$').hasMatch(clean)) return null;
    return clean;
  }

  /// تنسيق عرض قياسي "AA:BB:CC:DD:EE:FF".
  static String? pretty(String mac) {
    final clean = normalize(mac);
    if (clean == null) return null;
    return List.generate(6, (i) => clean.substring(i * 2, i * 2 + 2)).join(':');
  }

  /// البت الثاني من أول بايت: 1 = عنوان محلي/عشوائي (MAC randomization)
  /// وهو ما تفعله الهواتف الحديثة لإخفاء هويتها.
  static bool isLocallyAdministered(String mac) {
    final clean = normalize(mac);
    if (clean == null) return false;
    final firstOctet = int.tryParse(clean.substring(0, 2), radix: 16) ?? 0;
    return (firstOctet & 0x02) != 0;
  }

  /// عنوان البث (ff:ff:ff:ff:ff:ff) المستخدم في Wake-on-LAN.
  static const String broadcastMac = 'FF:FF:FF:FF:FF:FF';
}
