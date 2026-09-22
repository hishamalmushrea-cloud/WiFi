import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'glass_card.dart';

/// بطاقة زجاجية تفاعلية مع حركة ضغط/تمرير.
///
/// تكبر قليلاً عند التحويم (سطح المكتب/الويب) وتصغر عند اللمس،
/// مع توهّم يظهر عند التحويم — إحساس «عنصر حيّ» بدل بطاقة جامدة.
class InteractiveGlassCard extends StatefulWidget {
  const InteractiveGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.gradient,
    this.glowColor,
    this.padding,
    this.borderRadius = 20,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? glowColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  State<InteractiveGlassCard> createState() => _InteractiveGlassCardState();
}

class _InteractiveGlassCardState extends State<InteractiveGlassCard> {
  bool _pressed = false;
  bool _hovering = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // مقياس الضغط 0.97، والتحويم 1.02 — حركة خفيفة بصرية.
    final scale = _pressed
        ? 0.97
        : _hovering
            ? 1.02
            : 1.0;

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: GlassCard(
            gradient: widget.gradient,
            glowColor: _hovering
                ? (widget.glowColor ?? AppColors.glowPrimary)
                : widget.glowColor,
            padding: widget.padding ?? const EdgeInsets.all(16),
            borderRadius: widget.borderRadius,
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
