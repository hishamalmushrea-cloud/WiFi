import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/device.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/app_progress_bar.dart';
import '../../../core/presentation/widgets/common_ui.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/modern_device_card.dart';
import '../../../core/presentation/widgets/network_map_canvas.dart';
import '../../../core/presentation/widgets/responsive_layout.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../devices/presentation/device_detail_page.dart';
import '../../devices/presentation/device_providers.dart';
import 'port_scan_page.dart';
import 'scan_providers.dart';

/// شاشة فحص الشبكة المخصصة: معلومات الشبكة، تقدّم لحظي، خريطة
/// طوبولوجيا، والأجهزة المكتشفة.
class NetworkScanPage extends ConsumerWidget {
  const NetworkScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(networkScanProvider);
    final savedDevices = ref.watch(devicesStreamProvider);
    final notifier = ref.read(networkScanProvider.notifier);

    // الأجهزة المعروضة: نتائج الفحص الحالي، أو المحفوظة عند الفراغ.
    final devices = scan.devices.isNotEmpty
        ? scan.devices
        : (savedDevices.valueOrNull ?? const <Device>[]);
    final gateway = devices
        .where((d) =>
            d.ip.endsWith('.1') || d.type == DeviceType.router)
        .cast<Device?>()
        .firstWhere((d) => d != null, orElse: () => null);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text(AppStrings.scanNetworkTitle)),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: notifier.startScan,
            child: ListView(
              padding: context.responsivePadding.copyWith(bottom: 100),
              children: [
                // معلومات الشبكة.
                if (scan.networkInfo != null)
                  GlassCard(
                    child: Column(
                      children: [
                        _InfoRow(
                            icon: Icons.wifi_rounded,
                            label: AppStrings.lanInfo,
                            value: scan.networkInfo!.wifiName ?? '—'),
                        _InfoRow(
                            icon: Icons.router_rounded,
                            label: AppStrings.gateway,
                            value: scan.networkInfo!.gatewayIp ?? '—'),
                        _InfoRow(
                            icon: Icons.perm_identity_rounded,
                            label: AppStrings.deviceIp,
                            value: scan.networkInfo!.deviceIp ?? '—'),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // زر الفحص + التقدّم.
                FilledButton.icon(
                  onPressed: scan.isScanning ? null : notifier.startScan,
                  icon: scan.isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find_rounded),
                  label: Text(scan.isScanning
                      ? AppStrings.scanning
                      : AppStrings.scanStart),
                ),
                if (scan.isScanning) ...[
                  const SizedBox(height: AppSpacing.lg),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppProgressBar(
                          progress: scan.progress,
                          label:
                              'تم فحص ${scan.scanned} من ${scan.total} عنوان',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'عُثر على ${scan.devices.length} جهاز حتى الآن',
                          style: context.textTheme.labelMedium
                              ?.copyWith(color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ],
                if (scan.phase.name == 'error')
                  ErrorView(
                      message: scan.errorMessage, onRetry: notifier.startScan),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: scan.isScanning
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PortScanPage()),
                          ),
                  icon: const Icon(Icons.radar_rounded),
                  label: const Text(AppStrings.portScanTitle),
                ),
                const SizedBox(height: AppSpacing.xl),

                // الخريطة الطوبولوجية.
                if (devices.isNotEmpty) ...[
                  SectionHeader(title: 'مخطط الشبكة'),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: NetworkMapCanvas(
                      gateway: gateway,
                      devices: devices,
                      size: 300,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                      title:
                          '${AppStrings.devicesTitle} (${devices.length})'),
                  const SizedBox(height: AppSpacing.md),
                  _DevicesGrid(devices: devices),
                ] else if (!scan.isScanning)
                  const EmptyState(
                    icon: Icons.wifi_find_rounded,
                    title: AppStrings.emptyDevices,
                    actionLabel: AppStrings.scanStart,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DevicesGrid extends StatelessWidget {
  const _DevicesGrid({required this.devices});
  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = ResponsiveLayout.breakpointOf(constraints.maxWidth);
        final columns = switch (bp) {
          Breakpoint.desktop => 5,
          Breakpoint.tablet => 3,
          Breakpoint.mobile => 2,
        };
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.92,
          ),
          itemCount: devices.length,
          itemBuilder: (context, i) {
            final device = devices[i];
            return ModernDeviceCard(
              device: device,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeviceDetailPage(deviceId: device.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: context.textTheme.bodySmall),
          const Spacer(),
          Text(value,
              style: context.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
