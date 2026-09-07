import 'package:flutter/material.dart';

import '../../extensions/context_ext.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// شريط تقدّم مُصمّم بعنوان ونسبة مئوية (للفحص والاختبار).
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.progress,
    this.label,
    this.gradient = AppColors.gradientPrimary,
  });

  final double progress; // 0–1
  final String? label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(label!, style: context.textTheme.bodySmall),
              ),
              Text('${pct.toStringAsFixed(0)}%',
                  style: context.textTheme.labelMedium
                      ?.copyWith(color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Stack(
            children: [
              Container(
                height: 10,
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.08),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0, 1)),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) => FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(gradient: gradient),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// مؤشر نبض دائري حول أيقونة (للحالة النشطة/الجارية).
class PulsingIndicator extends StatefulWidget {
  const PulsingIndicator({
    super.key,
    required this.child,
    this.color = AppColors.success,
    this.size = 56,
  });

  final Widget child;
  final Color color;
  final double size;

  @override
  State<PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // الحلقة النابضة.
              Container(
                width: widget.size * (0.7 + _controller.value * 0.4),
                height: widget.size * (0.7 + _controller.value * 0.4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // ignore: deprecated_member_use
                  color: widget.color.withOpacity((1 - _controller.value) * 0.3),
                ),
              ),
              widget.child,
            ],
          );
        },
      ),
    );
  }
}
