import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/speed_test_result.dart';
import '../../../core/domain/repositories/speed_test_repository.dart';
import '../data/speed_test_repository_impl.dart';

/// حالة اختبار السرعة الحيّة.
class SpeedTestState {
  const SpeedTestState({
    this.phase = SpeedTestPhase.idle,
    this.percent = 0,
    this.currentMbps = 0,
    this.currentPingMs = 0,
    this.result,
    this.error,
  });

  final SpeedTestPhase phase;
  final double percent;
  final double currentMbps;
  final double currentPingMs;
  final SpeedTestResult? result;
  final String? error;

  bool get isRunning =>
      phase != SpeedTestPhase.idle && phase != SpeedTestPhase.done;

  SpeedTestState copyWith({
    SpeedTestPhase? phase,
    double? percent,
    double? currentMbps,
    double? currentPingMs,
    SpeedTestResult? result,
    String? error,
  }) =>
      SpeedTestState(
        phase: phase ?? this.phase,
        percent: percent ?? this.percent,
        currentMbps: currentMbps ?? this.currentMbps,
        currentPingMs: currentPingMs ?? this.currentPingMs,
        result: result ?? this.result,
        error: error,
      );
}

class SpeedTestNotifier extends StateNotifier<SpeedTestState> {
  SpeedTestNotifier(this._repo) : super(const SpeedTestState());

  final SpeedTestRepository _repo;

  Future<void> run() async {
    state = const SpeedTestState(phase: SpeedTestPhase.ping);

    final result = await _repo.runTest(
      onProgress: (progress) {
        state = SpeedTestState(
          phase: progress.phase,
          percent: progress.percent,
          currentMbps: progress.currentMbps,
          currentPingMs: progress.currentPingMs,
        );
      },
    );

    result.when(
      onSuccess: (data) => state = SpeedTestState(
        phase: SpeedTestPhase.done,
        percent: 100,
        currentMbps: data.downloadMbps,
        currentPingMs: data.pingMs,
        result: data,
      ),
      onFailure: (failure) => state = SpeedTestState(
        phase: SpeedTestPhase.done,
        error: failure.message,
      ),
    );
  }

  void reset() => state = const SpeedTestState();
}

final speedTestProvider =
    StateNotifierProvider<SpeedTestNotifier, SpeedTestState>(
  (ref) => SpeedTestNotifier(ref.watch(speedTestRepositoryProvider)),
);

/// سجل السرعات (بثّ من قاعدة البيانات).
final speedHistoryProvider =
    StreamProvider<List<SpeedTestResult>>((ref) {
  return ref.watch(speedTestRepositoryProvider).watchHistory();
});

/// أعلى سرعة مسجّلة.
final peakSpeedProvider = FutureProvider<SpeedTestResult?>((ref) async {
  final result = await ref.watch(speedTestRepositoryProvider).getPeak();
  return result.dataOrNull;
});
