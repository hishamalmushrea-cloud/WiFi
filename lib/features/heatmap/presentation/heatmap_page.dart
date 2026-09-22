import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/heatmap.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/heatmap_widget.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../heatmap/data/survey_repository_impl.dart';

/// قائمة مسوحات المواقع المحفوظة + زر إنشاء مسح جديد.
class HeatmapPage extends ConsumerWidget {
  const HeatmapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text(AppStrings.toolSiteSurvey)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _createSurvey(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text(AppStrings.newSurvey),
        ),
        body: SafeArea(
          child: _SurveyList(onOpen: (id, name) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SurveyDetailPage(surveyId: id, surveyName: name),
            ));
          }),
        ),
      ),
    );
  }

  Future<void> _createSurvey(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: AppStrings.defaultSurveyName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.surveyNameTitle),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text(AppStrings.done)),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final result =
        await ref.read(surveyRepositoryProvider).createSurvey(name);
    result.when(
      onSuccess: (survey) {
        if (!context.mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              SurveyDetailPage(surveyId: survey.id!, surveyName: name),
        ));
      },
      onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
    );
  }
}

class _SurveyList extends ConsumerWidget {
  const _SurveyList({required this.onOpen});
  final void Function(int id, String name) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<SiteSurvey>>(
      stream: ref.read(surveyRepositoryProvider).watchSurveys(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final surveys = snapshot.data ?? const <SiteSurvey>[];
        if (surveys.isEmpty) {
          return const EmptyState(
            icon: Icons.map_outlined,
            title: AppStrings.noSurveys,
            message: AppStrings.noSurveysHint,
          );
        }
        return ListView.separated(
          padding: context.responsivePadding.copyWith(bottom: 100),
          itemCount: surveys.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final s = surveys[i];
            return GlassCard(
              onTap: () => onOpen(s.id!, s.name),
              child: Row(
                children: [
                  const Icon(Icons.map_rounded, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: context.textTheme.titleSmall),
                        Text(AppStrings.samplesCountN(s.samples.length),
                            style: context.textTheme.labelSmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded,
                      color: AppColors.darkTextTertiary),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// شاشة مسح واحد: خريطة تفاعلية، النقر عليها يضيف نقطة قياس.
class SurveyDetailPage extends ConsumerStatefulWidget {
  const SurveyDetailPage({
    super.key,
    required this.surveyId,
    required this.surveyName,
  });

  final int surveyId;
  final String surveyName;

  @override
  ConsumerState<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends ConsumerState<SurveyDetailPage> {
  List<SignalSample> _samples = const [];
  bool _saving = false;

  void _addSample(Offset localPosition, Size size) {
    // موضع نسبي على الخريطة (0–1).
    final x = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final y = (localPosition.dy / size.height).clamp(0.0, 1.0);

    // قوة إشارة تجريبية: أقرب للمركز أقوى (محاكاة تغطية نقطة وصول وسطية).
    // في النسخة النهائية تُقرأ RSSI الحقيقية من مسح WiFi الأصلي.
    final distance =
        (((x - 0.5) * (x - 0.5) + (y - 0.5) * (y - 0.5))) * 2;
    final rssi = (-42 - distance * 70).clamp(-95, -40).round();

    setState(() {
      _samples = [
        ..._samples,
        SignalSample(
          rssi: rssi,
          x: x,
          y: y,
          capturedAt: DateTime.now(),
        ),
      ];
    });
  }

  Future<void> _persistSample(SignalSample sample) async {
    await ref.read(surveyRepositoryProvider).addSample(widget.surveyId, sample);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.surveyName),
          actions: [
            IconButton(
              tooltip: AppStrings.export,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              onPressed: _exportPdf,
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: context.responsivePadding,
            children: [
              Text(
                AppStrings.heatmapHint,
                style: context.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  const height = 320.0;
                  return GestureDetector(
                    onTapDown: (details) {
                      _addSample(details.localPosition, Size(width, height));
                      final last = _samples.last;
                      _persistSample(last);
                    },
                    child: HeatmapWidget(
                      samples: _samples,
                      height: height,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Metric(
                        label: AppStrings.metricSamples,
                        value: '${_samples.length}'),
                    _Metric(
                        label: AppStrings.metricAvgSignal,
                        value: _samples.isEmpty
                            ? '—'
                            : '${(_samples.map((s) => s.rssi).reduce((a, b) => a + b) / _samples.length).round()} dBm'),
                    _Metric(
                        label: AppStrings.metricWeakest,
                        value: _samples.isEmpty
                            ? '—'
                            : '${_samples.map((s) => s.rssi).reduce((a, b) => a < b ? a : b)} dBm'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _saving = true);
    final result =
        await ref.read(surveyRepositoryProvider).exportPdfReport(widget.surveyId);
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      onSuccess: (path) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.reportSaved(path))),
      ),
      onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: context.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.accent)),
        Text(label, style: context.textTheme.labelSmall),
      ],
    );
  }
}
