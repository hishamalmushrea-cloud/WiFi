import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/speed_test_result.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/speed_gauge.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'speed_test_providers.dart';

/// شاشة اختبار السرعة: عداد متحرك + مراحل + سجل النتائج.
class SpeedTestPage extends ConsumerWidget {
  const SpeedTestPage({super.key});

  String _phaseLabel(SpeedTestPhase phase) {
    return switch (phase) {
      SpeedTestPhase.ping => AppStrings.ping,
      SpeedTestPhase.download => AppStrings.download,
      SpeedTestPhase.upload => AppStrings.upload,
      SpeedTestPhase.done => AppStrings.done,
      SpeedTestPhase.idle => AppStrings.startSpeedTest,
    };
  }

  Gradient _phaseGradient(SpeedTestPhase phase) {
    return switch (phase) {
      SpeedTestPhase.upload => AppColors.gradientSuccess,
      SpeedTestPhase.ping => AppColors.gradientWarning,
      _ => AppColors.gradientAccent,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(speedTestProvider);
    final history = ref.watch(speedHistoryProvider);

    final gaugeValue = state.phase == SpeedTestPhase.upload
        ? state.currentMbps
        : (state.phase == SpeedTestPhase.ping
            ? state.currentPingMs / 2 // مقياس بصري للكمون
            : state.currentMbps);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text(AppStrings.speedTestTitle)),
        body: SafeArea(
          child: ListView(
            padding: context.responsivePadding,
            children: [
              GlassCard(
                glowColor: AppColors.glowAccent,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    SpeedGauge(
                      value: gaugeValue,
                      maxValue: 100,
                      label: _phaseLabel(state.phase),
                      unit: AppStrings.mbps,
                      gradient: _phaseGradient(state.phase),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.result != null) ...[
                      _ResultRow(result: state.result!),
                    ] else if (state.error != null)
                      Text(state.error!,
                          style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: state.isRunning
                            ? null
                            : () => ref.read(speedTestProvider.notifier).run(),
                        icon: state.isRunning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.bolt_rounded),
                        label: Text(state.isRunning
                            ? AppStrings.loading
                            : AppStrings.startSpeedTest),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(AppStrings.speedHistory, style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              history.when(
                loading: () => const ShimmerCard(),
                error: (e, _) => const Text(AppStrings.noHistoryAlt),
                data: (tests) {
                  if (tests.isEmpty) {
                    return const GlassCard(
                      child: Text(AppStrings.speedNoHistory),
                    );
                  }
                  return Column(
                    children: tests.take(10).map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              const Icon(Icons.history_rounded,
                                  color: AppColors.accent, size: 20),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(t.timestamp.ago,
                                    style: context.textTheme.bodyMedium),
                              ),
                              _MiniStat(
                                  label: AppStrings.download,
                                  value:
                                      '${t.downloadMbps.toStringAsFixed(0)} ${AppStrings.mbps}'),
                              const SizedBox(width: AppSpacing.md),
                              _MiniStat(
                                  label: AppStrings.ping,
                                  value:
                                      '${t.pingMs.toStringAsFixed(0)} ${AppStrings.ms}'),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result});
  final SpeedTestResult result;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(
            icon: Icons.download_rounded,
            label: AppStrings.download,
            value: result.downloadMbps.toStringAsFixed(1),
            color: AppColors.accent),
        _Stat(
            icon: Icons.upload_rounded,
            label: AppStrings.upload,
            value: result.uploadMbps.toStringAsFixed(1),
            color: AppColors.success),
        _Stat(
            icon: Icons.network_ping_rounded,
            label: AppStrings.ping,
            value: result.pingMs.toStringAsFixed(0),
            color: AppColors.warning),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: context.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: context.textTheme.labelSmall),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary)),
        Text(label, style: context.textTheme.labelSmall),
      ],
    );
  }
}
