import '../../errors/result.dart';
import '../entities/access_point.dart';
import '../entities/channel_analysis.dart';

/// عقد تحليل شبكات الواي فاي والقنوات.
abstract class WifiAnalysisRepository {
  /// نقاط الوصول المكتشفة لحظياً (بث متكرر أثناء المسح).
  Stream<List<AccessPoint>> watchAccessPoints();

  /// دورة مسح واحدة: يطلب صلاحيات الموقع ثم يقرأ نقاط الوصول.
  Future<Result<List<AccessPoint>>> scanAccessPoints();

  /// يحلّل القنوات والتداخل لنقاط وصول معطاة.
  Future<Result<WifiAnalysisResult>> analyze(List<AccessPoint> accessPoints);

  /// أفضل قناة موصى بها لنطاق.
  Future<Result<ChannelRecommendation?>> recommendChannel(WifiBand band);

  /// نقاط الوصول المحفوظة سابقاً من قاعدة البيانات.
  Future<Result<List<AccessPoint>>> getSavedAccessPoints();
}
