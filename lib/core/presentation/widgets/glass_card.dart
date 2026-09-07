import 'dart:ui';

import 'package:flutter/material.dart';

import '../../extensions/context_ext.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// بطاقة زجاجية (Glassmorphism): طبقة ضبابية شفافة بحدود لامعة.
///
/// أساس كل البطاقات في التطبيق. تقبل تدرجاً لونياً اختيارياً
/// (للبطاقات المميزة) وتلوّن نفسها تلقائياً حسب الثيم.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius = AppSpacing.radiusLg,
    this.gradient,
    this.glowColor,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// تدرج لوني يغطي البطاقة (يخفي المظهر الزجاجي الشفاف جزئياً).
  final Gradient? gradient;

  /// لون توهج حول البطاقة (ظل ملوّن).
  final Color? glowColor;

  /// عند التمرير يحوّل البطاقة إلى زر تفاعلي.
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    final border = Border.all(
      color: borderColor ??
          (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      width: 1,
    );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      // ignore: deprecated_member_use
                      Colors.white.withOpacity(AppSpacing.glassFillOpacity + 0.02),
                      // ignore: deprecated_member_use
                      Colors.white.withOpacity(AppSpacing.glassFillOpacity - 0.03),
                    ]
                  : [
                      // ignore: deprecated_member_use
                      Colors.white.withOpacity(0.7),
                      // ignore: deprecated_member_use
                      Colors.white.withOpacity(0.5),
                    ],
            ),
        border: border,
        boxShadow: glowColor == null
            ? null
            : [
                BoxShadow(
                  color: glowColor!,
                  blurRadius: AppSpacing.glowBlur,
                  spreadRadius: AppSpacing.glowSpread,
                ),
              ],
      ),
      child: child,
    );

    // الضبابية فوق المحتوى الشفاف تعطي تأثير الزجاج.
    final blurred = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSpacing.glassBlur,
          sigmaY: AppSpacing.glassBlur,
        ),
        child: content,
      ),
    );

    if (onTap == null) return blurred;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        splashColor: AppColors.primary.withOpacity(0.12),
        child: blurred,
      ),
    );
  }
}
