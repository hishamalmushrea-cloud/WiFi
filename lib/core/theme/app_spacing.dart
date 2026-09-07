/// مقاييس المسافات والزوايا الموحدة.
///
/// سبب التوحيد: المواصفات تشترط زوايا محددة (8/12/16/20/24)
/// ومسافات متسقة، فلا تُكتب أي قيمة ثابتة في الويدجتس.
class AppSpacing {
  AppSpacing._();

  // ── المسافات ─────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  // ── أنصاف الأقطار (الزوايا المستديرة) ───────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusFull = 999;

  // ── حدود الزجاج ──────────────────────────────────────────────
  static const double glassBlur = 24;
  static const double glassBorderOpacity = 0.15;
  static const double glassFillOpacity = 0.08;

  // ── الظلال المتوهجة ──────────────────────────────────────────
  static const double glowSpread = 1;
  static const double glowBlur = 24;

  static List<double> get screenPaddingSteps => const [lg, xl, xxl];
}
