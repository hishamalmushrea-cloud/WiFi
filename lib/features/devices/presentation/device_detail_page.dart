import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/date_time_ext.dart';
import '../../../core/domain/entities/device.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/common_ui.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/modern_device_card.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../security/data/security_repository_impl.dart';
import 'device_providers.dart';

/// صفحة تفاصيل جهاز: معلومات، سجل تاريخي، وإجراءات تحكم.
class DeviceDetailPage extends ConsumerWidget {
  const DeviceDetailPage({super.key, required this.deviceId});

  final int deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesStreamProvider);
    final historyAsync = ref.watch(deviceHistoryProvider(deviceId));
    final actions = ref.read(deviceActionsProvider);

    final device = devicesAsync.valueOrNull
        ?.where((d) => d.id == deviceId)
        .cast<Device?>()
        .firstWhere((d) => d != null, orElse: () => null);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(device?.displayName ?? AppStrings.deviceDetails),
          bottom: const TabBar(
            tabs: [
              Tab(text: AppStrings.information),
              Tab(text: AppStrings.labelHistory),
              Tab(text: AppStrings.actions),
            ],
          ),
        ),
        body: SafeArea(
          child: devicesAsync.when(
            loading: () => const ShimmerCard(),
            error: (e, _) => ErrorView(
                onRetry: () => ref.invalidate(devicesStreamProvider)),
            data: (_) {
              if (device == null) {
                return const EmptyState(
                  icon: Icons.devices_other_rounded,
                  title: AppStrings.deviceUnknown,
                );
              }
              return TabBarView(
                children: [
                  // ── التبويب 1: المعلومات ──
                  ListView(
                    padding: context.responsivePadding,
                    children: [
                      GlassCard(
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusLg),
                              ),
                              child: Icon(
                                deviceTypeIcon(device.type),
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(device.displayName,
                                      style: context.textTheme.titleLarge),
                                  Text(
                                    device.isOnline
                                        ? AppStrings.online
                                        : AppStrings.offline,
                                    style: TextStyle(
                                      color: device.isOnline
                                          ? AppColors.success
                                          : AppColors.darkTextTertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      InfoTile(
                          icon: Icons.lan_rounded,
                          label: AppStrings.deviceIp,
                          value: device.ip,
                          copyable: true,
                          onCopy: () => _copy(context, device.ip)),
                      const SizedBox(height: AppSpacing.sm),
                      InfoTile(
                          icon: Icons.memory_rounded,
                          label: AppStrings.deviceMac,
                          value: device.mac,
                          copyable: true,
                          onCopy: () => _copy(context, device.mac)),
                      const SizedBox(height: AppSpacing.sm),
                      InfoTile(
                          icon: Icons.business_rounded,
                          label: AppStrings.deviceVendor,
                          value: device.vendor ?? AppStrings.unknown),
                      const SizedBox(height: AppSpacing.sm),
                      InfoTile(
                          icon: Icons.settings_ethernet_rounded,
                          label: AppStrings.deviceType,
                          value: device.type.name),
                      if (device.os != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        InfoTile(
                            icon: Icons.devices_rounded,
                            label: AppStrings.deviceOs,
                            value: device.os!),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      InfoTile(
                          icon: Icons.history_rounded,
                          label: AppStrings.deviceFirstSeen,
                          value: device.firstSeen.formatted),
                      const SizedBox(height: AppSpacing.sm),
                      InfoTile(
                          icon: Icons.schedule_rounded,
                          label: AppStrings.deviceLastSeen,
                          value: '${device.lastSeen.formatted} (${device.lastSeen.ago})'),
                    ],
                  ),

                  // ── التبويب 2: السجل التاريخي ──
                  historyAsync.when(
                    loading: () => const ShimmerCard(),
                    error: (e, _) => ErrorView(
                        onRetry: () =>
                            ref.invalidate(deviceHistoryProvider(deviceId))),
                    data: (history) {
                      if (history.isEmpty) {
                        return const EmptyState(
                          icon: Icons.history_rounded,
                          title: AppStrings.noHistory,
                          message: AppStrings.deviceSeenNote,
                        );
                      }
                      return ListView.separated(
                        padding: context.responsivePadding,
                        itemCount: history.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final h = history[i];
                          return GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Icon(
                                  h.isOnline
                                      ? Icons.link_rounded
                                      : Icons.link_off_rounded,
                                  color: h.isOnline
                                      ? AppColors.success
                                      : AppColors.darkTextTertiary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    h.isOnline
                                        ? AppStrings.connected
                                        : AppStrings.disconnected,
                                    style: context.textTheme.bodyMedium,
                                  ),
                                ),
                                Text(h.timestamp.ago,
                                    style: context.textTheme.labelSmall),
                                if (h.rssi != null) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Text('${h.rssi} dBm',
                                      style: context.textTheme.labelSmall),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // ── التبويب 3: الإجراءات ──
                  ListView(
                    padding: context.responsivePadding,
                    children: [
                      _ActionTile(
                        icon: device.isBlocked
                            ? Icons.lock_open_rounded
                            : Icons.block_rounded,
                        label: device.isBlocked
                            ? AppStrings.deviceUnblock
                            : AppStrings.deviceBlock,
                        color: AppColors.error,
                        onTap: () => actions.toggleBlocked(device),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ActionTile(
                        icon: device.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        label: device.isFavorite
                            ? AppStrings.deviceUnfavorite
                            : AppStrings.deviceFavorite,
                        color: AppColors.warning,
                        onTap: () => actions.toggleFavorite(device),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ActionTile(
                        icon: Icons.verified_user_rounded,
                        label: AppStrings.deviceKnown,
                        color: AppColors.success,
                        onTap: () => actions.markKnown(device),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ActionTile(
                        icon: Icons.bug_report_rounded,
                        label: AppStrings.vulnerabilities,
                        color: AppColors.warning,
                        onTap: () async {
                          final result = await ref
                              .read(securityRepositoryProvider)
                              .scanVulnerabilities(device.id);
                          if (!context.mounted) return;
                          result.when(
                            onSuccess: (vulns) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(vulns.isEmpty
                                      ? AppStrings.noVulnerabilities
                                      : AppStrings.vulnerabilitiesFound(vulns.length)),
                                ),
                              );
                            },
                            onFailure: (f) =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(f.message)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ActionTile(
                        icon: Icons.drive_file_rename_outline_rounded,
                        label: AppStrings.deviceRename,
                        color: AppColors.accent,
                        onTap: () => _renameDialog(context, ref, device),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ActionTile(
                        icon: Icons.delete_outline_rounded,
                        label: AppStrings.delete,
                        color: AppColors.error,
                        onTap: () async {
                          await actions.remove(device);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.copy)),
    );
  }

  Future<void> _renameDialog(
      BuildContext context, WidgetRef ref, Device device) async {
    final controller = TextEditingController(text: device.name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deviceRename),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text(AppStrings.save)),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(deviceActionsProvider).rename(device, result);
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: context.textTheme.titleSmall)),
          const Icon(Icons.chevron_left_rounded,
              color: AppColors.darkTextTertiary),
        ],
      ),
    );
  }
}
