/// أدوات التواريخ بالعربية.
///
/// نعتمد صيغاً رقمية فقط (لا أسماء أشهر) حتى لا نحتاج تهيئة
/// locale لـ intl، ونبني الزمن النسبي العربي يدوياً لعبارات
/// «منذ دقيقة / منذ ساعتين» الأقرب للاستخدام الأمني.
class DateUtilsAr {
  DateUtilsAr._();

  /// صيغة «yyyy/MM/dd HH:mm» ثابتة ومفهومة محلياً ودولياً.
  static String formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static String formatTime(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }

  /// زمن نسبي عربي: «الآن»، «منذ ٥ دقائق»، «منذ ٣ ساعات»…
  static String timeAgo(DateTime dt, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(dt);
    if (diff.inSeconds < 45) return 'الآن';
    if (diff.inMinutes < 1) return 'منذ ${diff.inSeconds} ثانية';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return m == 1 ? 'منذ دقيقة' : 'منذ $m دقائق';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return h == 1 ? 'منذ ساعة' : 'منذ $h ساعات';
    }
    if (diff.inDays < 30) {
      final d = diff.inDays;
      return d == 1 ? 'منذ يوم' : 'منذ $d أيام';
    }
    final months = (diff.inDays / 30).floor();
    return months <= 1 ? 'منذ شهر' : 'منذ $months أشهر';
  }
}
