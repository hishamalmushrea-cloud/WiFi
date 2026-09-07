import 'package:flutter/material.dart';

import '../../domain/entities/heatmap.dart';
import '../../theme/app_colors.dart';

/// خريطة حرارية لقوة الإشارة فوق مخطط طابق.
///
/// ترسم كل عينة إشارة كتوهج دائري نصف شفاف لونه حسب القوة
/// (أخضر قوي → أحمر ضعيف)، فتتداخل التوهجات لتكوّن خريطة
/// حرارية بصرية فوق صورة المسح (أو خلفية فارغة).
class HeatmapWidget extends StatelessWidget {
  const HeatmapWidget({
    super.key,
    required this.samples,
    this.backgroundImage,
    this.height = 320,
  });

  final List<SignalSample> samples;
  final Widget? backgroundImage;
  final double height;

  static Color _colorForRssi(int rssi) {
    if (rssi >= -55) return AppColors.success;
    if (rssi >= -67) return AppColors.accent;
    if (rssi >= -75) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            if (backgroundImage != null)
              Positioned.fill(child: backgroundImage!)
            else
              // خلفية شبكية رمادية لمخطط طابق فارغ.
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.darkSurface),
                ),
              ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    painter: _HeatmapPainter(samples: samples),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({required this.samples});
  final List<SignalSample> samples;

  @override
  void paint(Canvas canvas, Size size) {
    for (final sample in samples) {
      if (sample.x == null || sample.y == null) continue;
      final center = Offset(sample.x! * size.width, sample.y! * size.height);
      // نصف القطر يتناسب مع قوة الإشارة (أقوى = تغطية أوسع).
      final radius = (sample.rssi + 100) / 60 * size.width * 0.22;
      final color = HeatmapWidget._colorForRssi(sample.rssi);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            // ignore: deprecated_member_use
            color.withOpacity(0.55),
            // ignore: deprecated_member_use
            color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);

      // نقطة القياس.
      canvas.drawCircle(
        center,
        4,
        Paint()..color = Colors.white.withOpacity(0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) =>
      oldDelegate.samples != samples;
}
