import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/security.dart';
import '../../../core/domain/entities/speed_test_result.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../security/presentation/security_providers.dart';
import '../../speed_test/presentation/speed_test_providers.dart';

/// حدث موحّد في الجدول الزمني.
class TimelineEvent {
  const TimelineEvent({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime timestamp;
}

/// يجمع التنبيهات الأمنية ونتائج السرعة في تدفّق زمني واحد مرتّب.
final activityTimelineProvider = Provider<AsyncValue<List<TimelineEvent>>>((ref) {
  final alerts = ref.watch(securityAlertsProvider);
  final speeds = ref.watch(speedHistoryProvider);

  // ننتظر مصدر البيانات الأول على الأقل.
  if (alerts.isLoading && speeds.isLoading) {
    return const AsyncValue.loading();
  }

  final events = <TimelineEvent>[];

  for (final alert in alerts.valueOrNull ?? <SecurityAlert>[]) {
    events.add(TimelineEvent(
      icon: Icons.warning_amber_rounded,
      color: AppColors.severityColor(
        switch (alert.severity) {
          ThreatSeverity.critical => Severity.critical,
          ThreatSeverity.high => Severity.high,
          ThreatSeverity.medium => Severity.medium,
          ThreatSeverity.low => Severity.low,
        },
      ),
      title: alert.title,
      subtitle: alert.description ?? AppStrings.alertsCenter,
      timestamp: alert.timestamp,
    ));
  }

  for (final test in speeds.valueOrNull ?? <SpeedTestResult>[]) {
    events.add(TimelineEvent(
      icon: Icons.speed_rounded,
      color: AppColors.accent,
      title: '${AppStrings.speedTestTitle}: '
          '${test.downloadMbps.toStringAsFixed(0)} ${AppStrings.mbps}',
      subtitle: '${AppStrings.ping} ${test.pingMs.toStringAsFixed(0)} ${AppStrings.ms}'
          '${test.isp != null ? ' • ${test.isp}' : ''}',
      timestamp: test.timestamp,
    ));
  }

  events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return AsyncValue.data(events.take(200).toList());
});

/// شاشة الجدول الزمني الموحّد للنشاط.
class ActivityTimelinePage extends ConsumerWidget {
  const ActivityTimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(activityTimelineProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text(AppStrings.recentAlerts)),
        body: SafeArea(
          child: events.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(
                onRetry: () => ref.invalidate(activityTimelineProvider)),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.timeline_rounded,
                  title: AppStrings.noActivity,
                  message: AppStrings.noActivityHint,
                );
              }
              return ListView.separated(
                padding: context.responsivePadding.copyWith(bottom: 40),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final e = list[i];
                  return _TimelineTile(event: e, isLast: i == list.length - 1);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.isLast});
  final TimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الخط الزمني العمودي مع نقطة الحدث.
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: event.color.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: event.color, width: 2),
                  ),
                  child: Icon(event.icon, size: 14, color: event.color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.darkBorder),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: context.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(event.subtitle, style: context.textTheme.bodySmall,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(event.timestamp.ago,
                      style: context.textTheme.labelSmall
                          ?.copyWith(color: AppColors.darkTextTertiary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
