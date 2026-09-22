import '../../errors/result.dart';
import '../entities/heatmap.dart';
import '../repositories/survey_repository.dart';

class CreateSurveyUseCase {
  CreateSurveyUseCase(this._repo);
  final SurveyRepository _repo;
  Future<Result<SiteSurvey>> call(String name, {String? floor}) =>
      _repo.createSurvey(name, floor: floor);
}

class AddSignalSampleUseCase {
  AddSignalSampleUseCase(this._repo);
  final SurveyRepository _repo;
  Future<Result<void>> call(int surveyId, SignalSample sample) =>
      _repo.addSample(surveyId, sample);
}

class WatchSurveysUseCase {
  WatchSurveysUseCase(this._repo);
  final SurveyRepository _repo;
  Stream<List<SiteSurvey>> call() => _repo.watchSurveys();
}

class GenerateHeatmapUseCase {
  GenerateHeatmapUseCase(this._repo);
  final SurveyRepository _repo;
  Future<Result<List<SignalSample>>> call(int surveyId) =>
      _repo.generateHeatmap(surveyId);
}

class ExportSurveyPdfUseCase {
  ExportSurveyPdfUseCase(this._repo);
  final SurveyRepository _repo;
  Future<Result<String>> call(int surveyId) => _repo.exportPdfReport(surveyId);
}

class DeleteSurveyUseCase {
  DeleteSurveyUseCase(this._repo);
  final SurveyRepository _repo;
  Future<Result<void>> call(int id) => _repo.deleteSurvey(id);
}
