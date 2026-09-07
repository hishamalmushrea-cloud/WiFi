import '../../errors/result.dart';
import '../entities/speed_test_result.dart';
import '../repositories/speed_test_repository.dart';

/// تشغيل اختبار سرعة كامل مع بثّ التقدّم.
class RunSpeedTestUseCase {
  RunSpeedTestUseCase(this._repo);
  final SpeedTestRepository _repo;

  Future<Result<SpeedTestResult>> call({
    SpeedTestServer? server,
    void Function(SpeedTestProgress)? onProgress,
  }) =>
      _repo.runTest(server: server, onProgress: onProgress);
}

class GetSpeedServersUseCase {
  GetSpeedServersUseCase(this._repo);
  final SpeedTestRepository _repo;
  Future<Result<List<SpeedTestServer>>> call() => _repo.getServers();
}

class WatchSpeedHistoryUseCase {
  WatchSpeedHistoryUseCase(this._repo);
  final SpeedTestRepository _repo;
  Stream<List<SpeedTestResult>> call({int limit = 100}) =>
      _repo.watchHistory(limit: limit);
}

class GetPeakSpeedUseCase {
  GetPeakSpeedUseCase(this._repo);
  final SpeedTestRepository _repo;
  Future<Result<SpeedTestResult?>> call() => _repo.getPeak();
}
