import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/access_point.dart';
import '../../../core/domain/entities/channel_analysis.dart';
import '../../../core/domain/repositories/wifi_analysis_repository.dart';
import '../data/wifi_analysis_repository_impl.dart';

/// حالة مسح وتحليل الواي فاي.
class WifiAnalysisState {
  const WifiAnalysisState({
    this.scanning = false,
    this.accessPoints = const [],
    this.result,
    this.error,
  });

  final bool scanning;
  final List<AccessPoint> accessPoints;
  final WifiAnalysisResult? result;
  final String? error;

  List<AccessPoint> forBand(WifiBand band) =>
      accessPoints.where((a) => a.band == band).toList();

  WifiAnalysisState copyWith({
    bool? scanning,
    List<AccessPoint>? accessPoints,
    WifiAnalysisResult? result,
    String? error,
  }) =>
      WifiAnalysisState(
        scanning: scanning ?? this.scanning,
        accessPoints: accessPoints ?? this.accessPoints,
        result: result ?? this.result,
        error: error,
      );
}

class WifiAnalysisNotifier extends StateNotifier<WifiAnalysisState> {
  WifiAnalysisNotifier(this._repo) : super(const WifiAnalysisState());

  final WifiAnalysisRepository _repo;

  /// دورة كاملة: مسح نقاط الوصول ثم تحليل القنوات.
  Future<void> scanAndAnalyze() async {
    state = state.copyWith(scanning: true, error: null);

    final scanResult = await _repo.scanAccessPoints();
    final aps = scanResult.dataOrNull ?? const <AccessPoint>[];

    if (aps.isEmpty) {
      state = state.copyWith(
        scanning: false,
        accessPoints: const [],
      );
      return;
    }

    final analysisResult = await _repo.analyze(aps);
    state = state.copyWith(
      scanning: false,
      accessPoints: aps,
      result: analysisResult.dataOrNull,
    );
  }

  /// يعيد التحليل على نفس النقاط دون مسح جديد (تغيير الفلتر).
  Future<void> reanalyze() async {
    if (state.accessPoints.isEmpty) return;
    final result = await _repo.analyze(state.accessPoints);
    state = state.copyWith(result: result.dataOrNull);
  }
}

final wifiAnalysisProvider =
    StateNotifierProvider<WifiAnalysisNotifier, WifiAnalysisState>(
  (ref) => WifiAnalysisNotifier(ref.watch(wifiAnalysisRepositoryProvider)),
);

/// نقاط الوصول المباشرة من البث (لمركز المراقبة الحي).
final liveAccessPointsProvider = StreamProvider<List<AccessPoint>>((ref) {
  return ref.watch(wifiAnalysisRepositoryProvider).watchAccessPoints();
});

/// توصية أفضل قناة لنطاق معيّن.
final channelRecommendationProvider =
    FutureProvider.family<ChannelRecommendation?, WifiBand>((ref, band) async {
  final result =
      await ref.watch(wifiAnalysisRepositoryProvider).recommendChannel(band);
  return result.dataOrNull;
});
