import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// عداد دائري متحرك لاختبار السرعة.
///
/// يرسم قوساً متدرجاً يمثل النسبة من الحد الأقصى، مع قيمة
/// حيّة في المنتصف وحركة سلسة عند تغيّر القيمة (Tween).
class SpeedGauge extends StatelessWidget {
  const SpeedGauge({
    super.key,
    required this.value,
    required this.maxValue,
    this.label = '',
    this.unit = '',
    this.size = 220,
    this.gradient,
  });

  final double value;
  final double maxValue;
  final String label;
  final String unit;
  final double size;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final clamped = (value / maxValue).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: clamped),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return CustomPaint(
            painter: _GaugePainter(
              progress: t,
              gradient: gradient ?? AppColors.gradientAccent,
              trackColor:
                  // ignore: deprecated_member_use
                  Colors.white.withOpacity(0.08),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.toStringAsFixed(value >= 100 ? 0 : 1),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.accent,
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

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.gradient,
    required this.trackColor,
  });

  final double progress;
  final Gradient gradient;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 16.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    // الحلقة الخلفية (دائرة كاملة).
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    // القوس الأمامي (متدرّج) بزاوية 270° نبدأ من أسفل اليسار.
    const startAngle = math.pi * 0.75; // 135°
    const sweepTotal = math.pi * 1.5; // 270°

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    canvas.drawArc(rect, startAngle, sweepTotal * progress, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
