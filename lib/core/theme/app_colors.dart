import 'package:flutter/material.dart';

/// لوحة ألوان NetControl — مطابقة لمواصفات نظام التصميم حرفياً.
class AppColors {
  AppColors._();

  // ── الألوان الأساسية ─────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Violet
  static const Color accent = Color(0xFF06B6D4); // Cyan

  // ── حالات النظام ─────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // ── الوضع الداكن ─────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF151B2B);
  static const Color darkSurfaceElevated = Color(0xFF1C2333);
  static const Color darkBorder = Color(0xFF2A3244);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // ── الوضع الفاتح ─────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF1F5F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  // ── تدرجات لونية جاهزة (تُستخدم في البطاقات والأزرار) ────────
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient gradientSuccess = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
  );

  static const LinearGradient gradientWarning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );

  static const LinearGradient gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  );

  /// تدرج خلفي شبكي (Mesh-like) لشاشات الإقلاع واللوحات الرئيسية.
  static const LinearGradient gradientBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F1629), Color(0xFF0A0E1A)],
  );

  // ── توهجات ملونة للظلال ──────────────────────────────────────
  static const Color glowPrimary = Color(0x666366F1);
  static const Color glowAccent = Color(0x5506B6D4);
  static const Color glowError = Color(0x55EF4444);

  /// لون حالة حسب شدة التنبيه — موحّد بين كل الشاشات.
  static Color severityColor(Severity severity) {
    switch (severity) {
      case Severity.critical:
        return error;
      case Severity.high:
        return const Color(0xFFF97316);
      case Severity.medium:
        return warning;
      case Severity.low:
        return accent;
    }
  }
}

/// شدة الحدث الأمني — موجودة هنا لأن الألوان تعتمدها مباشرة
/// وستُعاد كـ enum في Domain Layer بالمرحلة 4.
enum Severity { low, medium, high, critical }
