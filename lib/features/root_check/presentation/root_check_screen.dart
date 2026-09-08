import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/platform/root_status.dart';
import '../../../core/presentation/providers/root_status_provider.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// شاشة فحص صلاحيات الجذر (Root/Jailbreak).
///
/// تعرض حالة الفحص بشكل بصري واضح وتشرح الفرق بين الميزات
/// المتاحة (96) والمقفلة (30) تطبيقاً لمبدأ التدهور الآمن.
class RootCheckScreen extends ConsumerWidget {
  const RootCheckScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(rootStatusProvider);
    final notifier = ref.read(rootStatusProvider.notifier);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                _RootHeader(state: status.state),
                const SizedBox(height: AppSpacing.xxl),
                GlassCard(
                  child: Column(
                    children: [
                      _FeatureCount(
                          available: status.availableFeatures,
                          locked: status.lockedFeatures,
                          isRooted: status.isRooted),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        status.isRooted
                            ? AppStrings.rootAvailableBody
                            : AppStrings.rootUnavailableBody,
                        style: context.body(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (status.evidence.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.scanGuides,
                            style: context.titleSmall()),
                        const SizedBox(height: AppSpacing.sm),
                        ...status.evidence.map((e) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Text('• $e',
                                  style: context.labelSmall()),
                            )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: status.state == RootState.checking
                      ? null
                      : () => notifier.check(),
                  icon: const Icon(Icons.verified_user_rounded),
                  label: Text(status.state == RootState.checking
                      ? AppStrings.rootChecking
                      : AppStrings.rootCheckButton),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: onContinue,
                  child: const Text(AppStrings.continueWithoutRoot),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _CtxStyle on BuildContext {
  TextStyle? body() => textTheme.bodyMedium?.copyWith(height: 1.6);
  TextStyle? titleSmall() => textTheme.titleSmall;
  TextStyle? labelSmall() =>
      textTheme.labelSmall?.copyWith(color: AppColors.darkTextTertiary);
}

class _RootHeader extends StatelessWidget {
  const _RootHeader({required this.state});
  final RootState state;

  ({IconData icon, Color color, String title, Gradient gradient}) get _visual =>
      switch (state) {
        RootState.granted => (
            icon: Icons.verified_rounded,
            color: AppColors.success,
            title: AppStrings.rootAvailable,
            gradient: AppColors.gradientSuccess,
          ),
        RootState.notGranted => (
            icon: Icons.shield_outlined,
            color: AppColors.primary,
            title: AppStrings.rootUnavailable,
            gradient: AppColors.gradientPrimary,
          ),
        RootState.checking => (
            icon: Icons.hourglass_top_rounded,
            color: AppColors.accent,
            title: AppStrings.rootChecking,
            gradient: AppColors.gradientAccent,
          ),
        RootState.unknown => (
            icon: Icons.help_outline_rounded,
            color: AppColors.warning,
            title: AppStrings.rootUnavailable,
            gradient: AppColors.gradientWarning,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final v = _visual;
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: v.gradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: v.color.withOpacity(0.4), blurRadius: 30)],
          ),
          child: state == RootState.checking
              ? const Padding(
                  padding: EdgeInsets.all(34),
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                )
              : Icon(v.icon, size: 56, color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(v.title, style: context.textTheme.headlineSmall,
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _FeatureCount extends StatelessWidget {
  const _FeatureCount({
    required this.available,
    required this.locked,
    required this.isRooted,
  });
  final int available;
  final int locked;
  final bool isRooted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CountBox(
          value: available.toString(),
          label: AppStrings.featureAvailable,
          color: AppColors.success,
        ),
        Container(width: 1, height: 44, color: AppColors.darkBorder),
        _CountBox(
          value: locked.toString(),
          label: AppStrings.featureAdvanced,
          color: locked == 0 ? AppColors.darkTextTertiary : AppColors.warning,
        ),
      ],
    );
  }
}

class _CountBox extends StatelessWidget {
  const _CountBox({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: context.textTheme.headlineMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w800)),
        Text(label,
            style: context.textTheme.labelSmall
                ?.copyWith(color: AppColors.darkTextSecondary)),
      ],
    );
  }
}
