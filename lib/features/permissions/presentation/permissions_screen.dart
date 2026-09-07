import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// شاشة شرح وطلب الصلاحيات قبل الدخول للتطبيق.
///
/// تعرض كل صلاحية مع سببها والميزة التي تغذيها، وتطلبها
/// بوضوح بدل إظهار نافذة النظام مباشرة دون سياق.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  final _granted = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    final service = ref.read(permissionServiceProvider);
    final requirements = service.requirements;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text(AppStrings.permissionsTitle)),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: requirements.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final req = requirements[i];
                    final granted = _granted[req.title] ?? false;
                    return GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (granted ? AppColors.success : AppColors.primary)
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Icon(
                              granted ? Icons.check_circle : Icons.lock_outline,
                              color: granted
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(req.title,
                                    style: context.textTheme.titleSmall),
                                const SizedBox(height: 2),
                                Text(req.body,
                                    style: context.textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text(AppStrings.requiredForLabel(req.requiredFor),
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(color: AppColors.accent)),
                              ],
                            ),
                          ),
                          if (!granted)
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg),
                              ),
                              onPressed: () async {
                                final ok =
                                    await ref.read(permissionServiceProvider).request(req.permission);
                                setState(() => _granted[req.title] = ok);
                              },
                              child: const Text(AppStrings.permissionGrant),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.onContinue,
                    child: const Text(AppStrings.permissionsContinue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
