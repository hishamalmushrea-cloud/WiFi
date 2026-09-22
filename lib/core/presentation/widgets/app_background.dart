import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// خلفية التطبيق: تدرج داكن مع هالات ضوئية ناعمة (Mesh-like).
///
/// تُلتف بها كل الشاشات لتوحيد العمق البصري؛ الهالات الثابتة
/// تعطي إحساس الزجاج المتوهج دون أي تكلفة رسم متحرك مستمر.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.gradientBackground : null,
        color: isDark ? null : AppColors.lightBackground,
      ),
      child: Stack(
        children: [
          // هالة علوية يمين (Indigo)
          Positioned(
            top: -120,
            right: -80,
            child: _Glow(
              // ignore: deprecated_member_use
              color: AppColors.primary.withOpacity(0.28),
              size: 320,
            ),
          ),
          // هالة سفلية يمنى (Cyan)
          Positioned(
            bottom: -140,
            left: -100,
            child: _Glow(
              // ignore: deprecated_member_use
              color: AppColors.accent.withOpacity(0.18),
              size: 360,
            ),
          ),
          // محتوى فوق الهالات
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}


