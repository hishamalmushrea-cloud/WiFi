import '../../errors/result.dart';
import '../entities/heatmap.dart';

/// عقد مسوحات المواقع والخرائط الحرارية.
abstract class SurveyRepository {
  Future<Result<SiteSurvey>> createSurvey(String name, {String? floor});

  Future<Result<void>> addSample(int surveyId, SignalSample sample);

  Stream<List<SiteSurvey>> watchSurveys();

  Future<Result<SiteSurvey?>> getSurvey(int id);

  Future<Result<void>> deleteSurvey(int id);

  /// يولّد بيانات خريطة حرارية من عينات المسح.
  Future<Result<List<SignalSample>>> generateHeatmap(int surveyId);

  /// تصدير تقرير مسح PDF، يُعاد مسار الملف.
  Future<Result<String>> exportPdfReport(int surveyId);
}
