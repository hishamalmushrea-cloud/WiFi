import '../../errors/result.dart';
import '../entities/access_point.dart';
import '../entities/channel_analysis.dart';
import '../repositories/wifi_analysis_repository.dart';

/// مسح نقاط الوصول المحيطة (يتطلب صلاحية الموقع).
class ScanAccessPointsUseCase {
  ScanAccessPointsUseCase(this._repo);
  final WifiAnalysisRepository _repo;

  Future<Result<List<AccessPoint>>> call() => _repo.scanAccessPoints();
}

/// تحليل القنوات والتداخل لنقاط وصول معطاة.
class AnalyzeChannelsUseCase {
  AnalyzeChannelsUseCase(this._repo);
  final WifiAnalysisRepository _repo;

  Future<Result<WifiAnalysisResult>> call(List<AccessPoint> aps) =>
      _repo.analyze(aps);
}

/// توصية أفضل قناة لنطاق معيّن.
class RecommendChannelUseCase {
  RecommendChannelUseCase(this._repo);
  final WifiAnalysisRepository _repo;

  Future<Result<ChannelRecommendation?>> call(WifiBand band) =>
      _repo.recommendChannel(band);
}

/// مراقبة نقاط الوصول (بث حيّ).
class WatchAccessPointsUseCase {
  WatchAccessPointsUseCase(this._repo);
  final WifiAnalysisRepository _repo;
  Stream<List<AccessPoint>> call() => _repo.watchAccessPoints();
}
