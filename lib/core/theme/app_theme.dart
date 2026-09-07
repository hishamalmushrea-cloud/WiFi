import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// بناء الثيمات (Material 3) — الداكن افتراضياً مع نسخة فاتحة.
///
/// كل الألوان والخطوط والقياسات تأتي من نظام التصميم الموحد
/// حتى لا توجد قياسات حرفية داخل الويدجتس.
class AppTheme {
  AppTheme._();

  // ── الخط: IBM Plex Sans Arabic ───────────────────────────────
  static TextTheme _textTheme(Color textPrimary, Color textSecondary) {
    final base = GoogleFonts.ibmPlexSansArabicTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w800),
      displayMedium: base.displayMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w800),
      headlineLarge: base.headlineLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
      headlineSmall: base.headlineSmall?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(color: textSecondary, fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(color: textPrimary),
      bodyMedium: base.bodyMedium?.copyWith(color: textPrimary),
      bodySmall: base.bodySmall?.copyWith(color: textSecondary),
      labelLarge: base.labelLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
      labelMedium: base.labelMedium?.copyWith(color: textSecondary),
      labelSmall: base.labelSmall?.copyWith(color: textSecondary),
    );
  }

  // ── الثيم الداكن (الافتراضي) ────────────────────────────────
  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        surfaceElevated: AppColors.darkSurfaceElevated,
        border: AppColors.darkBorder,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
      );

  // ── الثيم الفاتح ────────────────────────────────────────────
  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        surfaceElevated: AppColors.lightSurfaceElevated,
        border: AppColors.lightBorder,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceElevated,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      // ملاحظة: surfaceContainerHighest أُضيفت في Flutter 3.22؛
      // نعتمد على surface في 3.19 حتى نرفع الإصدار.
      onSurfaceVariant: textSecondary,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: _textTheme(textPrimary, textSecondary),
      dividerColor: border,
      splashFactory: InkRipple.splashFactory,

      // ── شريط التطبيق ──
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme(textPrimary, textSecondary).titleLarge,
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // ── البطاقات ──
      cardTheme: CardTheme(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: border),
        ),
      ),

      // ── الأزرار ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          textStyle: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      // ── حقول الإدخال ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      // ── شريط التنقل السفلي ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            // ignore: deprecated_member_use — withOpacity متوافق مع Flutter 3.19
            ? AppColors.darkSurface.withOpacity(0.9)
            // ignore: deprecated_member_use
            : AppColors.lightSurface.withOpacity(0.9),
        // ignore: deprecated_member_use
        indicatorColor: AppColors.primary.withOpacity(0.25),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.ibmPlexSansArabic(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        height: 72,
      ),

      // ── قوائم ومربعات حوار ──
      dialogTheme: DialogTheme(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
        ),
      ),

      // ── مؤشر التحميل والشرائح ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0x226366F1),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceElevated,
        contentTextStyle: TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}
