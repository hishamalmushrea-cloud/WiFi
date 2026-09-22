import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../localization/app_strings.dart';
import '../../platform/root_status.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../providers/root_status_provider.dart';

/// بوابة الميزات المتقدمة (تتطلب Root/Jailbreak).
///
/// تعرض المحتوى فقط عند توفر صلاحيات الجذر؛ وإلا تعرض بطاقة
/// تشرح أن الميزة مقفلة مع زر إعادة الفحص — تطبيقاً صارماً
/// لمبدأ «التدهور الآمن» ومنع الوصول لميزة لا تعمل.
class RootRequiredGate extends ConsumerWidget {
  const RootRequiredGate({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(rootStatusProvider);

    if (status.isRooted) return child;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: AppColors.gradientWarning,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glowError,
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.lock_rounded,
                size: 48, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(AppStrings.requiresRoot,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '«$title» — ${AppStrings.requiresRootBody}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkTextSecondary,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          // شارة توضح وضع الفحص الحالي.
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Text(
              status.state == RootState.checking
                  ? AppStrings.rootChecking
                  : (status.state == RootState.unknown
                      ? AppStrings.rootRecheck
                      : AppStrings.rootStatusNone),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: status.state == RootState.checking
                ? null
                : () => ref.read(rootStatusProvider.notifier).check(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(AppStrings.rootCheckButton),
          ),
        ],
      ),
    );
  }
}
