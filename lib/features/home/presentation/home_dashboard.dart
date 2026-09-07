import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/security.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/common_ui.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/modern_stat_card.dart';
import '../../../core/presentation/widgets/responsive_layout.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../devices/presentation/device_providers.dart';
import '../../network_scan/presentation/network_scan_page.dart';
import '../../network_scan/presentation/scan_providers.dart';
import '../../router_control/presentation/router_dashboard_page.dart';
import '../../router_control/presentation/router_providers.dart';
import '../../router_control/presentation/router_selection_screen.dart';
import '../../security/presentation/security_dashboard_page.dart';
import '../../security/presentation/security_providers.dart';
import '../../settings/presentation/settings_page.dart';
import '../../speed_test/presentation/speed_test_page.dart';
import '../../speed_test/presentation/speed_test_providers.dart';
import '../../wifi_analysis/presentation/wifi_analysis_page.dart';

/// لوحة التحكم الرئيسية: إحصاءات + إجراءات سريعة + آخر التنبيهات.
class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesStreamProvider);
    final activeAlerts = ref.watch(activeAlertsProvider);
    final speedHistory = ref.watch(speedHistoryProvider);
    final scan = ref.watch(networkScanProvider);

    final onlineCount = devices.valueOrNull
            ?.where((d) => d.isOnline)
            .length ??
        0;
    final totalCount = devices.valueOrNull?.length ?? 0;
    final alertCount = activeAlerts.valueOrNull?.length ?? 0;
    final lastSpeed = speedHistory.valueOrNull?.isNotEmpty == true
        ? '${speedHistory.valueOrNull!.first.downloadMbps.toStringAsFixed(0)} ${AppStrings.mbps}'
        : '—';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings_rounded),
            tooltip: AppStrings.settings,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(networkScanProvider.notifier).startScan(),
          child: ListView(
            padding: context.responsivePadding.copyWith(bottom: 100),
            children: [
              // ترويسة ترحيب.
              Text(AppStrings.welcomeSubtitle,
                  style: context.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.lg),

              // بطاقات الإحصاء (شبكة متجاوبة).
              ResponsiveGrid(
                aspectRatio: 1.15,
                itemCount: 4,
                itemBuilder: (context, i) {
                  switch (i) {
                    case 0:
                      return ModernStatCard(
                        icon: Icons.devices_other_rounded,
                        value: '$onlineCount',
                        label: AppStrings.statOnlineDevices,
                        subtitle: 'من $totalCount إجمالي',
                        gradient: AppColors.gradientPrimary,
                        glowColor: AppColors.glowPrimary,
                      );
                    case 1:
                      return ModernStatCard(
                        icon: Icons.shield_rounded,
                        value: '${ref.watch(securityDashboardProvider).score?.score ?? "—"}',
                        label: AppStrings.statSecurityScore,
                        gradient: AppColors.gradientSuccess,
                        glowColor: AppColors.glowAccent,
                      );
                    case 2:
                      return ModernStatCard(
                        icon: Icons.speed_rounded,
                        value: lastSpeed,
                        label: AppStrings.statLastSpeed,
                        gradient: AppColors.gradientAccent,
                        glowColor: AppColors.glowAccent,
                      );
                    case 3:
                      return ModernStatCard(
                        icon: Icons.notifications_active_rounded,
                        value: '$alertCount',
                        label: AppStrings.statAlerts,
                        gradient: alertCount > 0
                            ? AppColors.gradientWarning
                            : AppColors.gradientPrimary,
                        glowColor: alertCount > 0
                            ? AppColors.glowError
                            : AppColors.glowPrimary,
                      );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // الإجراءات السريعة.
              SectionHeader(title: AppStrings.quickActions),
              const SizedBox(height: AppSpacing.md),
              ResponsiveGrid(
                aspectRatio: 1.0,
                mobileColumns: 2,
                tabletColumns: 3,
                desktopColumns: 4,
                itemCount: 6,
                itemBuilder: (context, i) {
                  void open(Widget page) => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => page));
                  final routerConnected = ref.watch(routerProvider).isConnected;
                  final actions = <QuickActionData>[
                    QuickActionData(
                        Icons.wifi_find_rounded,
                        AppStrings.actionScanNetwork,
                        AppColors.gradientPrimary,
                        AppColors.glowPrimary,
                        () => open(const NetworkScanPage())),
                    QuickActionData(
                        Icons.speed_rounded,
                        AppStrings.actionSpeedTest,
                        AppColors.gradientAccent,
                        AppColors.glowAccent,
                        () => open(const SpeedTestPage())),
                    QuickActionData(
                        Icons.analytics_rounded,
                        AppStrings.actionWifiAnalysis,
                        AppColors.gradientSuccess,
                        AppColors.glowAccent,
                        () => open(const WifiAnalysisPage())),
                    QuickActionData(
                        Icons.security_rounded,
                        AppStrings.actionSecurity,
                        AppColors.gradientWarning,
                        AppColors.glowError,
                        () => open(const SecurityDashboardPage())),
                    QuickActionData(
                        Icons.router_rounded,
                        AppStrings.actionRouter,
                        AppColors.gradientPrimary,
                        AppColors.glowPrimary,
                        () => open(routerConnected
                            ? const RouterDashboardPage()
                            : const RouterSelectionScreen())),
                    QuickActionData(
                        Icons.map_rounded,
                        AppStrings.actionWardriving,
                        AppColors.gradientAccent,
                        AppColors.glowAccent,
                        () => _comingSoon(context)),
                  ];
                  final a = actions[i];
                  return QuickActionTile(
                    icon: a.icon,
                    label: a.label,
                    gradient: a.gradient,
                    glowColor: a.glow,
                    onTap: a.onTap,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // آخر التنبيهات.
              SectionHeader(title: AppStrings.recentAlerts),
              const SizedBox(height: AppSpacing.md),
              activeAlerts.when(
                loading: () => const ShimmerCard(),
                error: (e, _) => ErrorView(
                    onRetry: () =>
                        ref.read(securityDashboardProvider.notifier).evaluate()),
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return const GlassCard(
                      child: Row(
                        children: [
                          Icon(Icons.verified_rounded,
                              color: AppColors.success),
                          SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(AppStrings.emptyAlerts)),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: alerts.take(5).map((alert) {
                      final color = _severityColor(alert.severity);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: GlassCard(
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: color),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(alert.title,
                                        style: context.textTheme.titleSmall),
                                    if (alert.description != null)
                                      Text(alert.description!,
                                          style: context.textTheme.bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              // مؤشر فحص جارٍ.
              if (scan.isScanning) ...[
                const SizedBox(height: AppSpacing.lg),
                GlassCard(
                  child: Column(
                    children: [
                      Text(AppStrings.scanning, style: context.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.md),
                      LinearProgressIndicator(value: scan.progress),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${scan.scanned} / ${scan.total} • ${scan.devices.length} جهاز',
                        style: context.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ستتوفر في التحديث القادم')),
    );
  }

}

/// يحوّل شدة التهديد في طبقة المجال إلى لون عرض موحّد.
Color _severityColor(ThreatSeverity severity) {
  switch (severity) {
    case ThreatSeverity.critical:
      return AppColors.error;
    case ThreatSeverity.high:
      return const Color(0xFFF97316);
    case ThreatSeverity.medium:
      return AppColors.warning;
    case ThreatSeverity.low:
      return AppColors.accent;
  }
}

class QuickActionData {
  const QuickActionData(
      this.icon, this.label, this.gradient, this.glowColor, this.onTap);
  final IconData icon;
  final String label;
  final Gradient gradient;
  final Color glowColor;
  final VoidCallback onTap;
}
