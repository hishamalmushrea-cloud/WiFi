import '../../errors/result.dart';
import '../entities/speed_test_result.dart';

/// عقد اختبار السرعة وسجلّه.
abstract class SpeedTestRepository {
  /// قائمة خوادم الاختبار المتاحة (أو خوادم افتراضية).
  Future<Result<List<SpeedTestServer>>> getServers();

  /// اختبار سرعة كامل.
  ///
  /// [onProgress] يبث التقدّم الحيّ (مرحلة + قيمة حالية) للواجهة.
  Future<Result<SpeedTestResult>> runTest({
    SpeedTestServer? server,
    void Function(SpeedTestProgress progress)? onProgress,
  });

  Stream<List<SpeedTestResult>> watchHistory({int limit});

  Future<Result<SpeedTestResult?>> getLatest();

  Future<Result<SpeedTestResult?>> getPeak();

  Future<Result<void>> saveResult(SpeedTestResult result);

  Future<Result<void>> clearHistory();
}
