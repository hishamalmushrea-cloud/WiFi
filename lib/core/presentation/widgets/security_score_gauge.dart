import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// عداد نصف دائري لمؤشر الأمان (0–100).
///
/// اللون يتدرّج من الأحمر (حرج) إلى الأخضر (ممتاز) حسب الدرجة،
/// مع كتابة التقدير الحرفي في المنتصف. حركة Tween عند التحديث.
class SecurityScoreGauge extends StatelessWidget {
  const SecurityScoreGauge({
    super.key,
    required this.score,
    this.size = 200,
  });

  final int score;
  final double size;

  Color get _color {
    if (score >= 85) return AppColors.success;
    if (score >= 70) return AppColors.accent;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String get _grade {
    if (score >= 85) return 'ممتاز';
    if (score >= 70) return 'جيد';
    if (score >= 50) return 'متوسط';
    if (score >= 30) return 'ضعيف';
    return 'حرج';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.62,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return CustomPaint(
            painter: _ScorePainter(progress: t, color: _color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(t * 100).round()}',
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w800,
                      color: _color,
                    ),
                  ),
                  Text(
                    _grade,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkTextSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScorePainter extends CustomPainter {
  _ScorePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = size.width / 2 - strokeWidth;

    // خلفية نصف دائرية.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      // ignore: deprecated_member_use
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159,
      false,
      track,
    );

    // القوس الملوّن.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScorePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
