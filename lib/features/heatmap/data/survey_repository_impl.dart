import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/database/app_database.dart';
import '../../../core/data/mappers/survey_mapper.dart';
import '../../../core/domain/entities/heatmap.dart';
import '../../../core/domain/repositories/survey_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/app_logger.dart';

/// تنفيذ مستودع مسوحات المواقع والخرائط الحرارية.
///
/// العينات تُحفظ كـ JSON ضمن صف المسح (عمود samplesJson) لتُقرأ
/// دفعة واحدة، والخريطة الحرارية نفسها تُرسم في طبقة العرض من
/// نفس النقاط. تصدير PDF ينتج تقريراً نصياً كاملاً هنا.
class SurveyRepositoryImpl implements SurveyRepository {
  SurveyRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<Result<SiteSurvey>> createSurvey(String name, {String? floor}) {
    return guard(() async {
      final now = DateTime.now();
      final companion = WifiSurveysCompanion(
        name: Value(name),
        floor: Value(floor),
        samplesJson: const Value('[]'),
        createdAt: Value(now),
        updatedAt: Value(now),
      );
      final id = await _db.wifiSurveyDao.insert(companion);
      return SiteSurvey(
        id: id,
        name: name,
        floor: floor,
        samples: const [],
        createdAt: now,
        updatedAt: now,
      );
    });
  }

  @override
  Future<Result<void>> addSample(int surveyId, SignalSample sample) {
    return guard(() async {
      final row = await _db.wifiSurveyDao.getById(surveyId);
      if (row == null) throw const NotFoundException('المسح غير موجود');
      final survey = SurveyMapper.toEntity(row);
      final updated = survey.copyWith(
        samples: [...survey.samples, sample],
        updatedAt: DateTime.now(),
      );
      await _db.wifiSurveyDao
          .update(SurveyMapper.toCompanion(updated).copyWith(id: Value(surveyId)));
    });
  }

  @override
  Stream<List<SiteSurvey>> watchSurveys() => _db.wifiSurveyDao
      .watchAll()
      .map((rows) => rows.map(SurveyMapper.toEntity).toList());

  @override
  Future<Result<SiteSurvey?>> getSurvey(int id) async {
    return guard(() async {
      final row = await _db.wifiSurveyDao.getById(id);
      return row == null ? null : SurveyMapper.toEntity(row);
    });
  }

  @override
  Future<Result<void>> deleteSurvey(int id) =>
      guard(() => _db.wifiSurveyDao.deleteById(id));

  @override
  Future<Result<List<SignalSample>>> generateHeatmap(int surveyId) {
    return guard(() async {
      final row = await _db.wifiSurveyDao.getById(surveyId);
      if (row == null) throw const NotFoundException('المسح غير موجود');
      // العينات نفسها تُرسَم كخريطة حرارية في الواجهة؛ نعيدها مرتّبة.
      return SurveyMapper.toEntity(row).samples
        ..sort((a, b) => a.rssi.compareTo(b.rssi));
    });
  }

  @override
  Future<Result<String>> exportPdfReport(int surveyId) {
    return guard(() async {
      final row = await _db.wifiSurveyDao.getById(surveyId);
      if (row == null) throw const NotFoundException('المسح غير موجود');
      final survey = SurveyMapper.toEntity(row);

      final pdf = pw.Document();
      final weakest = survey.weakestSpot;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('تقرير مسح الموقع: ${survey.name}',
                  style: pw.TextStyle(fontSize: 22)),
            ),
            pw.SizedBox(height: 12),
            pw.Text('الطابق: ${survey.floor ?? "غير محدد"}'),
            pw.Text('عدد نقاط القياس: ${survey.samples.length}'),
            pw.Text('متوسط قوة الإشارة: ${survey.averageRssi.toStringAsFixed(1)} dBm'),
            if (weakest != null)
              pw.Text('أضعف نقطة: ${weakest.rssi} dBm'),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headers: ['#', 'الإشارة (dBm)', 'الوقت'],
              data: [
                for (var i = 0; i < survey.samples.length; i++)
                  [
                    i + 1,
                    survey.samples[i].rssi,
                    survey.samples[i].capturedAt.toLocal().toString(),
                  ],
              ],
            ),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'survey_$surveyId.pdf'));
      await file.writeAsBytes(await pdf.save());
      AppLogger.info('صُدّر تقرير PDF: ${file.path}', tag: 'Survey');
      return file.path;
    });
  }
}

final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  return SurveyRepositoryImpl(ref.watch(appDatabaseProvider));
});
