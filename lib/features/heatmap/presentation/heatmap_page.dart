import 'dart:io' show Platform;

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
import '../../../core/utils/rssi_utils.dart';
import '../data/signal_sampler.dart';
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
            Navigator.of(context).push(MaterialPageRoute<void>(
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
        Navigator.of(context).push(MaterialPageRoute<void>(
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

  /// مصدر قراءة الإشارة — الافتراضي: تلقائي على Android، يدوي على iOS.
  SignalSourceMode _mode =
      defaultModeForPlatform(isIOS: Platform.isIOS);

  void _setMode(SignalSourceMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
  }

  Future<void> _addSampleAt(Offset localPosition, Size size) async {
    // موضع نسبي على الخريطة (0–1).
    final x = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final y = (localPosition.dy / size.height).clamp(0.0, 1.0);

    switch (_mode) {
      case SignalSourceMode.auto:
        final rssi =
            await ref.read(signalSamplerProvider).readConnectedRssi();
        if (!mounted) return;
        if (rssi == null) {
          _hint(AppStrings.heatmapAutoUnavailable);
          return;
        }
        _commit(rssi, x, y);
      case SignalSourceMode.manual:
        final rssi = await _askManualRssi();
        if (rssi == null) return;
        _commit(rssi, x, y);
      case SignalSourceMode.demo:
        // محاكاة معلَنة: أقرب للمركز أقوى. لأغراض العرض فقط.
        final distance =
            (((x - 0.5) * (x - 0.5) + (y - 0.5) * (y - 0.5))) * 2;
        final rssi = (-42 - distance * 70).clamp(-95, -40).round();
        _commit(rssi, x, y, persist: false);
    }
  }

  void _commit(int rssi, double x, double y, {bool persist = true}) {
    final sample = SignalSample(
      rssi: rssi,
      x: x,
      y: y,
      capturedAt: DateTime.now(),
    );
    setState(() => _samples = [..._samples, sample]);
    // عينات الوضع التجريبي لا تُحفظ — قيم غير حقيقية.
    if (persist) _persistSample(sample);
  }

  void _hint(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// حوار إدخال يدوي: منزلق dBm مع تصنيف الجودة لحظياً.
  Future<int?> _askManualRssi() {
    int value = -60;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppStrings.heatmapManualTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value dBm',
                style: ctx.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                _qualityLabel(RssiUtils.qualityOf(value)),
                style: ctx.textTheme.bodySmall
                    ?.copyWith(color: _qualityColor(RssiUtils.qualityOf(value))),
              ),
              Slider(
                value: value.toDouble(),
                min: -95,
                max: -35,
                divisions: 60,
                label: '$value',
                onChanged: (v) =>
                    setDialogState(() => value = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, value),
              child: const Text(AppStrings.add),
            ),
          ],
        ),
      ),
    );
  }

  String _qualityLabel(RssiQuality q) => switch (q) {
        RssiQuality.excellent => AppStrings.rssiExcellent,
        RssiQuality.good => AppStrings.rssiGood,
        RssiQuality.fair => AppStrings.rssiFair,
        RssiQuality.weak => AppStrings.rssiWeak,
        RssiQuality.veryPoor => AppStrings.rssiVeryPoor,
      };

  Color _qualityColor(RssiQuality q) => switch (q) {
        RssiQuality.excellent => AppColors.success,
        RssiQuality.good => AppColors.accent,
        RssiQuality.fair => AppColors.warning,
        RssiQuality.weak => AppColors.error,
        RssiQuality.veryPoor => AppColors.error,
      };

  Future<void> _persistSample(SignalSample sample) async {
    await ref.read(surveyRepositoryProvider).addSample(widget.surveyId, sample);
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = _mode == SignalSourceMode.demo;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.surveyName),
          actions: [
            // التصدير متاح للبيانات الحقيقية فقط.
            if (!isDemo)
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
              // ── اختيار مصدر القياس ──
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: Text(AppStrings.heatmapModeAuto),
                    selected: _mode == SignalSourceMode.auto,
                    onSelected: (_) => _setMode(SignalSourceMode.auto),
                  ),
                  ChoiceChip(
                    label: Text(AppStrings.heatmapModeManual),
                    selected: _mode == SignalSourceMode.manual,
                    onSelected: (_) => _setMode(SignalSourceMode.manual),
                  ),
                  ChoiceChip(
                    label: Text(AppStrings.heatmapModeDemo),
                    selected: isDemo,
                    onSelected: (_) => _setMode(SignalSourceMode.demo),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                switch (_mode) {
                  SignalSourceMode.auto => AppStrings.heatmapAutoHint,
                  SignalSourceMode.manual => AppStrings.heatmapManualHint,
                  SignalSourceMode.demo => AppStrings.heatmapDemoHint,
                },
                style: context.textTheme.bodySmall,
              ),

              // ── بانر الوضع التجريبي (إفصاح صريح) ──
              if (isDemo) ...[
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  borderColor: AppColors.warning,
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          AppStrings.heatmapDemoBanner,
                          style: context.textTheme.bodySmall
                              ?.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  const height = 320.0;
                  return GestureDetector(
                    onTapDown: (details) {
                      _addSampleAt(
                          details.localPosition, Size(width, height));
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
