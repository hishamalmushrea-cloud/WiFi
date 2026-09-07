import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

part 'app_database.g.dart';
part 'tables/app_tables.dart';

/// قاعدة بيانات التطبيق المركزية (Drift / SQLite).
///
/// التصميم:
///  - 15 جدولاً مع علاقات ومفاتيح أجنبية (مُعرَّفة في [tables/app_tables.dart]).
///  - وضع WAL للأداء عند الكتابة المتزامنة مع المراقبة الخلفية.
///  - أساس تشفير SQLCipher مُجهَّز: نسخة sqlite3 المستخدمة هي
///    نسخة SQLCipher، ويعمل المفتاح في PHASE 3 عبر Secure Storage
///    (قبلها تعمل كنُسخة عادية — SQLCipher لا يشفّر بلا مفتاح).
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
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
          // PHASE 3: تُنشأ الفهارس (Indexes) هنا عبر customStatement
          // للحقول كثيفة الاستعلامات (mac, timestamp, deviceId…).
        },
        beforeOpen: (details) async {
          // المفاتيح الأجنبية مسؤوليتنا تفعيلها عند كل فتح.
          await customStatement('PRAGMA foreign_keys = ON;');
        },
        onUpgrade: (migrator, from, to) async {
          // PHASE 3: استراتيجية الترحيل التدريجي عند تغيّر المخطط.
          AppLogger.info(
            'ترحيل قاعدة البيانات من الإصدار $from إلى $to',
            tag: 'Database',
          );
        },
      );
}

/// ينشئ اتصالاً كسولاً (Lazy) يُهيّأ عند أول استخدام فعلي.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // على Android نوجّه محمّل sqlite3 لنسخة SQLCipher.
    // بدون ضبط PRAGMA key تتصرف كـ sqlite3 عادية، لذا آمن في المرحلة الحالية.
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, '${AppConstants.appNameEn.toLowerCase()}.db'));

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // وضع WAL: أداء أفضل وكتابة متزامنة مع القراءة (مراقبة الخلفية).
        db.execute('PRAGMA journal_mode = WAL;');
        db.execute('PRAGMA foreign_keys = ON;');
        db.execute('PRAGMA synchronous = NORMAL;');
        // ── PHASE 3 ─────────────────────────────────────────────
        // بعد توليد مفتاح AES وتخزينه في Secure Storage:
        //   db.execute("PRAGMA key = '$cipherKey';");
      },
    );
  });
}
