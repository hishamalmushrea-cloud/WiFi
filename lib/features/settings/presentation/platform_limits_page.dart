import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../../core/domain/entities/platform_capabilities.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// شاشة "دعم المنصات وقيود iOS".
///
/// خريطة صادقة لما يعمل بالكامل وما يتدهور وما هو مستحيل على كل
/// منصة — ليعرف المستخدم قبل الاستخدام سبب اختلاف السلوك بين
/// Android وiOS (قيود Apple على واجهات الشبكة).
class PlatformLimitsPage extends StatelessWidget {
  const PlatformLimitsPage({super.key});

  bool get _isIOS => Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text(AppStrings.platformLimitsTitle)),
        body: SafeArea(
          child: ListView(
            padding: context.responsivePadding.copyWith(bottom: 100),
            children: [
              // ── شرح مبدئي ──
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.balance_rounded,
                            color: AppColors.accent),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            AppStrings.platformLimitsIntroTitle,
                            style: context.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.platformLimitsIntro,
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── مفتاح الألوان ──
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Legend(
                        color: AppColors.success,
                        label: AppStrings.supportFull),
                    _Legend(
                        color: AppColors.warning,
                        label: AppStrings.supportPartial),
                    _Legend(
                        color: AppColors.error,
                        label: AppStrings.supportUnavailable),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── القدرات: المقيّدة أولاً ──
              Text(
                AppStrings.platformLimitsLimitedSection,
                style: context.textTheme.titleSmall
                    ?.copyWith(color: AppColors.warning),
              ),
              const SizedBox(height: AppSpacing.sm),
              ..._capabilities(
                context,
                PlatformCapabilities.all
                    .where((c) => c.isLimitedOnIos)
                    .toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.platformLimitsFullSection,
                style: context.textTheme.titleSmall
                    ?.copyWith(color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.sm),
              ..._capabilities(
                context,
                PlatformCapabilities.all
                    .where((c) => !c.isLimitedOnIos)
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _capabilities(BuildContext context, List<PlatformCapability> items) {
    return [
      for (final c in items) ...[
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.title, style: context.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(c.description, style: context.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _SupportBadge(
                    label: 'Android',
                    level: c.android,
                    highlighted: !_isIOS,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _SupportBadge(
                    label: 'iOS',
                    level: c.ios,
                    highlighted: _isIOS,
                  ),
                ],
              ),
              if (c.iosNote != null && _isIOS) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        c.iosNote!,
                        style: context.textTheme.labelSmall
                            ?.copyWith(color: AppColors.darkTextSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: context.textTheme.labelSmall),
      ],
    );
  }
}

class _SupportBadge extends StatelessWidget {
  const _SupportBadge({
    required this.label,
    required this.level,
    required this.highlighted,
  });

  final String label;
  final SupportLevel level;
  final bool highlighted;

  Color get _color => switch (level) {
        SupportLevel.full => AppColors.success,
        SupportLevel.partial => AppColors.warning,
        SupportLevel.unavailable => AppColors.error,
      };

  IconData get _icon => switch (level) {
        SupportLevel.full => Icons.check_circle_rounded,
        SupportLevel.partial => Icons.remove_circle_rounded,
        SupportLevel.unavailable => Icons.cancel_rounded,
      };

  String get _text => switch (level) {
        SupportLevel.full => AppStrings.supportFull,
        SupportLevel.partial => AppStrings.supportPartial,
        SupportLevel.unavailable => AppStrings.supportUnavailable,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: highlighted ? _color : _color.withOpacity(0.4),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            '$label · $_text',
            style: context.textTheme.labelSmall?.copyWith(color: _color),
          ),
        ],
      ),
    );
  }
}
