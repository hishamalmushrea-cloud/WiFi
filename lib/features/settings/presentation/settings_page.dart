import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/app_settings.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/providers/root_status_provider.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/app_lock_service.dart';
import '../data/settings_repository_impl.dart';
import 'platform_limits_page.dart';
import 'settings_providers.dart';

/// صفحة الإعدادات بأقسامها (مظهر، أمان، مراقبة، تكاملات، عن التطبيق).
///
/// الوصول إليها عبر زر في اللوحة الرئيسية؛ تُربط لاحقاً في شريط علوي.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final appInfo = ref.watch(_appInfoProvider);
    final root = ref.watch(rootStatusProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: SafeArea(
        child: ListView(
          padding: context.responsivePadding.copyWith(bottom: 100),
          children: [
            // ── المظهر ──
            _SectionTitle(AppStrings.settingsAppearance),
            GlassCard(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: settings.themeMode,
                    onChanged: (m) => notifier.setThemeMode(ThemeMode.dark),
                    title: const Text(AppStrings.settingsThemeDark),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: settings.themeMode,
                    onChanged: (m) => notifier.setThemeMode(ThemeMode.light),
                    title: const Text(AppStrings.settingsThemeLight),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: settings.themeMode,
                    onChanged: (m) => notifier.setThemeMode(ThemeMode.system),
                    title: const Text(AppStrings.settingsThemeSystem),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── الأمان ──
            _SectionTitle(AppStrings.settingsSecurity),
            GlassCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: settings.appLockEnabled,
                    onChanged: (enabled) => _onAppLockToggle(
                      context: context,
                      ref: ref,
                      enabled: enabled,
                    ),
                    title: const Text(AppStrings.settingsAppLock),
                    secondary: const Icon(Icons.fingerprint_rounded,
                        color: AppColors.accent),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      root.isRooted
                          ? Icons.verified_rounded
                          : Icons.shield_outlined,
                      color: root.isRooted
                          ? AppColors.success
                          : AppColors.darkTextSecondary,
                    ),
                    title: const Text(AppStrings.rootStatusTitle),
                    subtitle: Text(
                      root.isRooted
                          ? AppStrings.rootAvailable
                          : AppStrings.rootNotAvailable,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.balance_rounded,
                        color: AppColors.accent),
                    title: const Text(AppStrings.settingsPlatformLimits),
                    subtitle: Text(AppStrings.settingsPlatformLimitsHint),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PlatformLimitsPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── المراقبة ──
            _SectionTitle(AppStrings.settingsMonitoring),
            GlassCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: settings.backgroundMonitoring,
                    onChanged: notifier.setBackgroundMonitoring,
                    title: const Text(AppStrings.settingsBackgroundScan),
                    secondary: const Icon(Icons.travel_explore_rounded,
                        color: AppColors.primary),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: settings.newDeviceAlerts,
                    onChanged: notifier.setNewDeviceAlerts,
                    title: const Text(AppStrings.settingsNewDeviceAlert),
                    secondary: const Icon(Icons.notifications_active_rounded,
                        color: AppColors.warning),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── التكاملات ──
            _SectionTitle(AppStrings.settingsIntegrations),
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.cloud_upload_rounded,
                    color: AppColors.secondary),
                title: const Text(AppStrings.settingsWigleToken),
                subtitle: Text(settings.isWigleConfigured
                    ? AppStrings.wigleKeySet
                    : AppStrings.wigleKeyMissing),
                trailing: const Icon(Icons.edit_rounded),
                onTap: () => _wigleDialog(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── عن التطبيق ──
            _SectionTitle(AppStrings.settingsAbout),
            GlassCard(
              child: appInfo.when(
                loading: () => const ShimmerBox(height: 40),
                error: (_, __) => const ListTile(
                    leading: Icon(Icons.info_outline_rounded),
                    title: const Text(AppStrings.appName),
                    subtitle: Text(AppStrings.appVersion)),
                data: (info) => ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(info.appName),
                  subtitle: Text(
                      '${AppStrings.settingsVersion}: ${info.version} (${info.buildNumber})'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// تفعيل القفل: نتحقق أولاً من قدرة الجهاز على المصادقة (وجود
  /// قفل شاشة) — وإلا نرفض التفعيل مع شرح السبب بدل تعطيل مستخدم
  /// يفعّل خياراً لن يعمل.
  Future<void> _onAppLockToggle({
    required BuildContext context,
    required WidgetRef ref,
    required bool enabled,
  }) async {
    if (!enabled) {
      await ref.read(settingsProvider.notifier).setAppLock(false);
      return;
    }

    final available = await ref.read(appLockServiceProvider).isAvailable();
    if (!available) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.appLockUnavailable)),
          );
      }
      return;
    }
    await ref.read(settingsProvider.notifier).setAppLock(true);
  }

  Future<void> _wigleDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: ref.read(settingsProvider).wigleApiToken ?? '',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.settingsWigleToken),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: AppStrings.wigleKeyHint,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setWigleToken(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          right: AppSpacing.xs, bottom: AppSpacing.sm, top: AppSpacing.sm),
      child: Text(title,
          style: context.textTheme.titleMedium
              ?.copyWith(color: AppColors.accent)),
    );
  }
}

/// يجلب معلومات الإصدار عند الطلب.
final _appInfoProvider = FutureProvider<AppInfo>((ref) async {
  final result = await ref.watch(settingsRepositoryProvider).getAppInfo();
  return result.when(
    onSuccess: (info) => info,
    onFailure: (_) => const AppInfo(
        appName: AppStrings.appName,
        version: '1.0.0',
        buildNumber: '1',
        packageName: 'com.netcontrol.app'),
  );
});
