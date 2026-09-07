import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import '../utils/app_logger.dart';

part 'app_database.g.dart';
part 'daos/app_daos.dart';
part 'daos/network_daos.dart';
part 'tables/app_tables.dart';

/// قاعدة بيانات التطبيق المركزية (Drift / SQLCipher).
///
/// الخصائص:
///  - 15 جدولاً + فهارس على الحقول كثيفة الاستعلامات.
///  - تشفير كامل بـ SQLCipher (AES-256) ومفتاح خام يأتي من
///    [SecureStorageService] — لا يمكن فتح نسخة من القاعدة بدونه.
///  - وضع WAL للأداء مع الكتابة الخلفية.
///  - استراتيجية ترحيل بإصدارات متدرجة للمستقبل.
@DriftDatabase(
  tables: [
    Devices,
    DeviceHistory,
    SecurityAlerts,
    SpeedTests,
    NetworkEvents,
    RouterSettings,
    WifiSurveys,
    WardrivingData,
    PortScanResults,
    Vulnerabilities,
    ActivityTimeline,
    DnsRecords,
    SavedNetworks,
    AccessPoints,
    ChannelAnalysis,
  ],
  daos: [
    DeviceDao,
    SecurityAlertDao,
    SpeedTestDao,
    NetworkEventDao,
    RouterSettingsDao,
    WifiSurveyDao,
    WardrivingDao,
    PortScanDao,
    VulnerabilityDao,
    ActivityTimelineDao,
    DnsRecordDao,
    SavedNetworkDao,
    AccessPointDao,
    ChannelAnalysisDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// للاستخدام الإنتاجي: الاتصال المشفّر المُهيّأ بالمفتاح الآمن.
  factory AppDatabase.encrypted(SecureStorageService secure) =>
      AppDatabase(_openConnection(secure));

  /// للاختبارات: تمرير executor وهمي في الذاكرة.
  factory AppDatabase.forTesting(QueryExecutor executor) =>
      AppDatabase(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
          // الفهارس معرّفة عبر @TableIndex فيُنشئها Drift ضمن createAll.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
        onUpgrade: (migrator, from, to) async {
          // خارطة ترحيل متدرجة: كل خطوة تُنفّذ مرة واحدة وبالترتيب.
          // مثال عند إضافة جدول/عمود مستقبلاً:
          //   if (from < 2) { await migrator.addColumn(...); }
          AppLogger.info('ترحيل قاعدة البيانات $from → $to', tag: 'Database');
        },
      );
}

/// اتصال كسول يُهيّأ عند أول استخدام فعلي — ووقتها فقط نقرأ
/// مفتاح التشفير من التخزين الآمن، فيبقى البناء متزامناً للاختبارات.
LazyDatabase _openConnection(SecureStorageService secure) {
  return LazyDatabase(() async {
    // نوجّه محمّل sqlite3 إلى نسخة SQLCipher على أندرويد.
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file =
        File(p.join(dir.path, '${AppConstants.appNameEn.toLowerCase()}.db'));

    // المفتاح الخام يُقرأ (أو يُولّد أول مرة) من الخزن الآمن.
    final keyHex = await secure.getOrCreateDatabaseKey();

    // نفتح على نفس الـ isolate (لا createInBackground) لأن تجاوز
    // محمّل مكتبة SQLCipher (open.overrideFor) يسري على الـ isolate
    // الذي يفتح القاعدة فعلياً. حجم البيانات متواضع ووضع WAL
    // يعوّض أداء الكتابة، فالخيار الأمتن هنا هو الفتح المتزامن.
    return NativeDatabase(
      file,
      setup: (db) {
        // ⚠️ الترتيب مهم: المفتاح يُضبط قبل أي عملية على القاعدة.
        db.execute("PRAGMA key = \"x'$keyHex'\";");
        db.execute('PRAGMA journal_mode = WAL;');
        db.execute('PRAGMA foreign_keys = ON;');
        db.execute('PRAGMA synchronous = NORMAL;');
      },
    );
  });
}

/// مزود قاعدة البيانات — تُغلق تلقائياً عند إلغاء المزوّد.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final secure = ref.watch(secureStorageServiceProvider);
  final db = AppDatabase.encrypted(secure);
  ref.onDispose(db.close);
  return db;
});
