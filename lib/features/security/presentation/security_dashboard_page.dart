import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/security.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/common_ui.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/security_score_gauge.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'security_providers.dart';

/// لوحة الأمان: مؤشر الدرجة + فحوصات + التهديدات المكتشفة.
class SecurityDashboardPage extends ConsumerWidget {
  const SecurityDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(securityDashboardProvider);
    final notifier = ref.read(securityDashboardProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(AppStrings.securityDashboard),
        actions: [
          IconButton(
            onPressed: () => ref.read(securityDashboardProvider.notifier).resolveAll(),
            icon: const Icon(Icons.done_all_rounded),
            tooltip: AppStrings.resolveAll,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: notifier.evaluate,
          child: ListView(
            padding: context.responsivePadding.copyWith(bottom: 100),
            children: [
              // زر التقييم.
              FilledButton.icon(
                onPressed: state.loading ? null : notifier.evaluate,
                icon: const Icon(Icons.security_rounded),
                label: Text(state.loading ? AppStrings.loading : AppStrings.runSecurityScan),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (state.loading && state.score == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.huge),
                    child: CircularProgressIndicator(),
                  ),
                ),

              if (state.score != null) ...[
                // المؤشر.
                GlassCard(
                  glowColor: AppColors.glowPrimary,
                  child: Center(
                    child: SecurityScoreGauge(score: state.score!.score),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                SectionHeader(title: AppStrings.securityChecks),
                const SizedBox(height: AppSpacing.sm),
                ...state.score!.checks.map((check) => _CheckTile(check: check)),

                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: AppStrings.recentAlerts),
                const SizedBox(height: AppSpacing.sm),

                if (state.detectedThreats.isEmpty &&
                    state.score!.activeAlerts.isEmpty)
                  const GlassCard(
                    child: Row(
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.success),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(AppStrings.emptyAlerts)),
                      ],
                    ),
                  ),
                ...state.detectedThreats.map((alert) => _AlertTile(
                      alert: alert,
                      onResolve: () => alert.id != null
                          ? notifier.resolveAlert(alert.id!)
                          : null,
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.check});
  final SecurityCheck check;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              check.passed ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: check.passed ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(check.title, style: context.textTheme.titleSmall),
                  if (check.recommendation != null && !check.passed)
                    Text(check.recommendation!,
                        style: context.textTheme.bodySmall
                            ?.copyWith(color: AppColors.warning)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, this.onResolve});
  final SecurityAlert alert;
  final VoidCallback? onResolve;

  Color get _color {
    switch (alert.severity) {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: _color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(alert.title, style: context.textTheme.titleSmall),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: _color.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    _severityLabel(alert.severity),
                    style: TextStyle(
                        color: _color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (alert.description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(alert.description!, style: context.textTheme.bodySmall),
            ],
            if (onResolve != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onResolve,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(AppStrings.markResolved),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _severityLabel(ThreatSeverity s) {
    switch (s) {
      case ThreatSeverity.critical:
        return AppStrings.threatCritical;
      case ThreatSeverity.high:
        return AppStrings.threatHigh;
      case ThreatSeverity.medium:
        return AppStrings.threatMedium;
      case ThreatSeverity.low:
        return AppStrings.threatLow;
    }
  }
}
