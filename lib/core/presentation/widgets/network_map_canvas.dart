import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/device.dart';
import '../../localization/app_strings.dart';
import '../../theme/app_colors.dart';
import 'modern_device_card.dart' show deviceTypeIcon;

/// مخطط طوبولوجيا الشبكة: الراوتر في المنتصف والأجهزة حوله.
///
/// يرسم خطوط ربط دائرية ويوزّع الأجهزة بشكل زخرفي على محيط دائرة.
class NetworkMapCanvas extends StatelessWidget {
  const NetworkMapCanvas({
    super.key,
    required this.gateway,
    required this.devices,
    this.size = 320,
  });

  final Device? gateway;
  final List<Device> devices;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MapPainter(
          onlineCount: devices.where((d) => d.isOnline).length,
        ),
        child: Stack(
          children: [
            // الراوتر في المركز.
            Center(child: _NodeChip(
              icon: Icons.router_rounded,
              label: gateway?.displayName ?? AppStrings.routerLabel,
              color: AppColors.primary,
            )),
            // الأجهزة موزّعة على المحيط.
            ...List.generate(math.min(devices.length, 8), (i) {
              final device = devices[i];
              final angle = (i / math.min(devices.length, 8)) * 2 * math.pi - math.pi / 2;
              final radius = size * 0.38;
              final dx = size / 2 + radius * math.cos(angle) - 30;
              final dy = size / 2 + radius * math.sin(angle) - 30;
              return Positioned(
                left: dx,
                top: dy,
                child: _NodeChip(
                  icon: deviceTypeIcon(device.type),
                  label: device.displayName,
                  color: device.isOnline ? AppColors.success : AppColors.darkTextTertiary,
                  small: true,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.onlineCount});
  final int onlineCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.38;

    // دوائر مساعدة.
    for (final r in [radius]) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.darkBorder
          ..strokeWidth = 1,
      );
    }
    // خطوط ربط من المركز لكل موقع متوقع.
    final linePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 1;
    final count = math.max(onlineCount, 1);
    for (var i = 0; i < count && i < 8; i++) {
      final angle = (i / math.min(count, 8)) * 2 * math.pi - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, point, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.onlineCount != onlineCount;
}

class _NodeChip extends StatelessWidget {
  const _NodeChip({
    required this.icon,
    required this.label,
    required this.color,
    this.small = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: small ? 44 : 60,
          height: small ? 44 : 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.darkSurface,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: 12),
            ],
          ),
          child: Icon(icon, color: color, size: small ? 20 : 28),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 70,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.darkTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
