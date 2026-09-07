import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/device.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/common_ui.dart';
import '../../../core/presentation/widgets/modern_device_card.dart';
import '../../../core/presentation/widgets/responsive_layout.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_spacing.dart';
import '../../network_scan/presentation/scan_providers.dart';
import 'device_detail_page.dart';
import 'device_providers.dart';

/// صفحة الأجهزة: بحث + فلاتر + شبكة متجاوبة من بطاقات الأجهزة.
class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(filteredDevicesProvider);
    final query = ref.watch(deviceQueryProvider);
    final scanState = ref.watch(networkScanProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // شريط البحث.
            Padding(
              padding: context.responsivePadding.copyWith(bottom: 0),
              child: TextField(
                onChanged: (v) =>
                    ref.read(deviceQueryProvider.notifier).setSearch(v),
                decoration: InputDecoration(
                  hintText: AppStrings.searchHintDots(AppStrings.search),
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // شرائح الفلاتر.
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  FilterChipX(
                    label: AppStrings.filterAll,
                    selected: query.filter == DeviceFilter.all,
                    onTap: () => ref
                        .read(deviceQueryProvider.notifier)
                        .setFilter(DeviceFilter.all),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilterChipX(
                    icon: Icons.circle,
                    label: AppStrings.filterOnline,
                    selected: query.filter == DeviceFilter.online,
                    onTap: () => ref
                        .read(deviceQueryProvider.notifier)
                        .setFilter(DeviceFilter.online),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilterChipX(
                    icon: Icons.star,
                    label: AppStrings.filterFavorites,
                    selected: query.filter == DeviceFilter.favorites,
                    onTap: () => ref
                        .read(deviceQueryProvider.notifier)
                        .setFilter(DeviceFilter.favorites),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilterChipX(
                    icon: Icons.block,
                    label: AppStrings.filterBlocked,
                    selected: query.filter == DeviceFilter.blocked,
                    onTap: () => ref
                        .read(deviceQueryProvider.notifier)
                        .setFilter(DeviceFilter.blocked),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // الشبكة.
            Expanded(
              child: devices.when(
                loading: () => const _GridShimmer(),
                error: (e, _) => ErrorView(
                  onRetry: () =>
                      ref.read(networkScanProvider.notifier).startScan(),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.devices_other_rounded,
                      title: AppStrings.emptyDevices,
                      message: scanState.isScanning
                          ? AppStrings.scanning
                          : AppStrings.scanStart,
                      actionLabel: AppStrings.scanStart,
                      onAction: () => ref
                          .read(networkScanProvider.notifier)
                          .startScan(),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final bp = ResponsiveLayout.breakpointOf(
                          constraints.maxWidth);
                      final columns = switch (bp) {
                        Breakpoint.desktop => 5,
                        Breakpoint.tablet => 3,
                        Breakpoint.mobile => 2,
                      };
                      return GridView.builder(
                        padding: context.responsivePadding
                            .copyWith(bottom: 100),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.92,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final device = list[i];
                          return ModernDeviceCard(
                            device: device,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeviceDetailPage(deviceId: device.id),
                              ),
                            ),
                            onToggleFavorite: () => ref
                                .read(deviceActionsProvider)
                                .toggleFavorite(device),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.read(networkScanProvider.notifier).startScan(),
        icon: scanState.isScanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.wifi_find_rounded),
        label: Text(scanState.isScanning
            ? '${scanState.scanned}/${scanState.total}'
            : AppStrings.scanNetworkTitle),
      ),
    );
  }
}

class _GridShimmer extends StatelessWidget {
  const _GridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: context.responsivePadding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ShimmerCard(),
    );
  }
}
