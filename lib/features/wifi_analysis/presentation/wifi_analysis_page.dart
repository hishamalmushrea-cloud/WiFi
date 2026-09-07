import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/access_point.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_progress_bar.dart';
import '../../../core/presentation/widgets/channel_graph.dart';
import '../../../core/presentation/widgets/common_ui.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'wifi_analysis_providers.dart';

/// صفحة تحليل الواي فاي: مسح النقاط + رسم القنوات + التوصية.
class WifiAnalysisPage extends ConsumerWidget {
  const WifiAnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wifiAnalysisProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text(AppStrings.wifiAnalysisTitle)),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(wifiAnalysisProvider.notifier).scanAndAnalyze(),
          child: ListView(
            padding: context.responsivePadding.copyWith(bottom: 100),
            children: [
              FilledButton.icon(
                onPressed: state.scanning
                    ? null
                    : () => ref
                        .read(wifiAnalysisProvider.notifier)
                        .scanAndAnalyze(),
                icon: state.scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering_rounded),
                label: Text(state.scanning ? AppStrings.scanning : AppStrings.start),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (state.accessPoints.isEmpty && !state.scanning)
                EmptyState(
                  icon: Icons.wifi_find_rounded,
                  title: AppStrings.noApNearby,
                  message: AppStrings.permissionLocationBody,
                  actionLabel: AppStrings.start,
                  onAction: () => ref
                      .read(wifiAnalysisProvider.notifier)
                      .scanAndAnalyze(),
                ),

              if (state.accessPoints.isNotEmpty) ...[
                // التوصية.
                if (state.result?.recommendations.isNotEmpty == true)
                  GlassCard(
                    glowColor: AppColors.glowAccent,
                    child: Row(
                      children: [
                        const Icon(Icons.recommend_rounded,
                            color: AppColors.success, size: 32),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.recommendedChannel,
                                  style: context.textTheme.titleSmall),
                              Text(
                                state.result!.recommendations
                                    .map((r) =>
                                        'قناة ${r.bestChannel}')
                                    .join(' • '),
                                style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                SectionHeader(title: AppStrings.channelGraph),
                const SizedBox(height: AppSpacing.sm),
                GlassCard(
                  child: ChannelGraph(
                    accessPoints: state.accessPoints,
                    recommendedChannel:
                        state.result?.recommendations.firstOrNull?.bestChannel,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                SectionHeader(title: AppStrings.apList),
                const SizedBox(height: AppSpacing.sm),
                ...state.accessPoints.map((ap) => _ApTile(ap: ap)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _ApTile extends StatelessWidget {
  const _ApTile({required this.ap});
  final AccessPoint ap;

  Color get _securityColor {
    switch (ap.security) {
      case WifiSecurity.wpa3:
      case WifiSecurity.wpa2:
        return AppColors.success;
      case WifiSecurity.wpa:
      case WifiSecurity.wpaEnterprise:
        return AppColors.warning;
      case WifiSecurity.wep:
        return AppColors.error;
      case WifiSecurity.open:
        return AppColors.error;
      case WifiSecurity.unknown:
        return AppColors.darkTextTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.wifi_rounded, color: _securityColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ap.displaySsid, style: context.textTheme.titleSmall),
                  Text(
                    'CH ${ap.channel} • ${ap.rssi} dBm • ${ap.security.name.toUpperCase()}',
                    style: context.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${ap.signalPercent}%',
                      style: context.textTheme.labelMedium
                          ?.copyWith(color: AppColors.accent)),
                  const SizedBox(height: 4),
                  AppProgressBar(
                    progress: ap.signalPercent / 100,
                    gradient: LinearGradient(colors: [
                      _securityColor,
                      _securityColor,
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
