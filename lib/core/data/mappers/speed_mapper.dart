import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../domain/entities/speed_test_result.dart';

/// تحويلات نتائج اختبار السرعة.
class SpeedTestMapper {
  const SpeedTestMapper._();

  static SpeedTestResult toEntity(SpeedTestRow r) => SpeedTestResult(
        id: r.id,
        downloadMbps: r.downloadMbps ?? 0,
        uploadMbps: r.uploadMbps ?? 0,
        pingMs: r.pingMs ?? 0,
        jitterMs: r.jitterMs ?? 0,
        serverName: r.serverName,
        serverLocation: r.serverLocation,
        serverUrl: r.serverUrl,
        isp: r.isp,
        connectionType: r.connectionType,
        testType: _parseType(r.testType),
        timestamp: r.timestamp,
      );

  static SpeedTestsCompanion toCompanion(SpeedTestResult t) =>
      SpeedTestsCompanion(
        downloadMbps: Value(t.downloadMbps),
        uploadMbps: Value(t.uploadMbps),
        pingMs: Value(t.pingMs),
        jitterMs: Value(t.jitterMs),
        serverName: Value(t.serverName),
        serverLocation: Value(t.serverLocation),
        serverUrl: Value(t.serverUrl),
        isp: Value(t.isp),
        connectionType: Value(t.connectionType),
        testType: Value(t.testType.name),
        timestamp: Value(t.timestamp),
      );

  static SpeedTestType _parseType(String raw) => SpeedTestType.values
      .firstWhere((t) => t.name == raw, orElse: () => SpeedTestType.standard);
}
