import 'package:flutter/material.dart';

import '../../extensions/context_ext.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'glass_card.dart';

/// بطاقة إحصاء حديثة: أيقونة متوهجة، قيمة كبيرة، تسمية، شريط تقدم.
///
/// تُستخدم في لوحة التحكم (أجهزة متصلة، مؤشر الأمان، السرعة…).
class ModernStatCard extends StatelessWidget {
  const ModernStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.gradient = AppColors.gradientPrimary,
    this.glowColor = AppColors.glowPrimary,
    this.progress,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;
  final Color glowColor;

  /// نسبة اختيارية 0–1 لشريط التقدم أسفل البطاقة.
  final double? progress;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      glowColor: glowColor,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // الأيقونة في مربع متدرّج متوهّج.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: context.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, fontSize: 26),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: context.textTheme.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: context.textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 5,
                backgroundColor:
                    // ignore: deprecated_member_use
                    Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
