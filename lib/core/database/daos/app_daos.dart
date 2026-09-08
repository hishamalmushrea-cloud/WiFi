// DAOs الخاصة ببيانات التطبيق والأجهزة والأمان والسرعة والراوتر.
// كل DAO ضمن مكتبة قاعدة البيانات ليصل لصفوف الجداول المولّدة.
part of '../app_database.dart';

// ════════════════════════════════════════════════════════════════
//  الأجهزة + سجلها التاريخي
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [Devices, DeviceHistory])
class DeviceDao extends DatabaseAccessor<AppDatabase>
    with _$DeviceDaoMixin {
  DeviceDao(super.db);

  /// كل الأجهزة مرتّبة الأحدث ظهوراً أولاً.
  Stream<List<DeviceRow>> watchAll() =>
      (select(devices)..orderBy([(t) => OrderingTerm(expression: t.lastSeen, mode: OrderingMode.desc)]))
          .watch();

  Future<List<DeviceRow>> getAll() =>
      (select(devices)..orderBy([(t) => OrderingTerm(expression: t.lastSeen, mode: OrderingMode.desc)]))
          .get();

  Future<DeviceRow?> getById(int id) {
    return (select(devices)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<DeviceRow?> getByMac(String mac) {
    return (select(devices)..where((t) => t.mac.equals(mac))).getSingleOrNull();
  }

  Future<int> insertDevice(DevicesCompanion device) =>
      into(devices).insert(device);

  Future<bool> updateDevice(DeviceRow device) =>
      update(devices).replace(device);

  Future<int> deleteDevice(int id) =>
      (delete(devices)..where((t) => t.id.equals(id))).go();

  /// إدراج أو تحديث حسب MAC (المفتاح الفريد الطبيعي) — يستخدمه
  /// ماسح الشبكة عند كل دورة فحص لتحديث الأجهزة القائمة.
  Future<int> upsertByMac(DevicesCompanion device) async {
    final mac = device.mac.value;
    final existing = await getByMac(mac);
    if (existing == null) {
      return into(devices).insert(device);
    }
    // نُبقي الحقول التي لم ترِد في الدفعة (Absent) على حالها:
    // copyWith يستبدل القيم المُمرّرة فقط، فلا تُمسح بيانات قديمة.
    final updated = existing.copyWith(
      ip: device.ip.valueIfPresent,
      name: device.name.valueIfPresent,
      vendor: device.vendor.valueIfPresent,
      os: device.os.valueIfPresent,
      deviceType: device.deviceType.valueIfPresent,
      fingerprint: device.fingerprint.valueIfPresent,
      hostname: device.hostname.valueIfPresent,
      connectionType: device.connectionType.valueIfPresent,
      signalStrength: device.signalStrength.valueIfPresent,
      throughput: device.throughput.valueIfPresent,
      lastSeen: device.lastSeen.valueIfPresent,
    );
    await update(devices).replace(updated);
    return existing.id;
  }

  Future<void> setBlocked(int id, bool blocked) =>
      (update(devices)..where((t) => t.id.equals(id)))
          .write(DevicesCompanion(isBlocked: Value(blocked)));

  Future<void> setFavorite(int id, bool favorite) =>
      (update(devices)..where((t) => t.id.equals(id)))
          .write(DevicesCompanion(isFavorite: Value(favorite)));

  Future<void> rename(int id, String name) =>
      (update(devices)..where((t) => t.id.equals(id)))
          .write(DevicesCompanion(name: Value(name)));

  /// الأجهزة التي شوهدت خلال [window] — تُحسب «متصلة» على أساسها
  /// لأن اتصال LAN بلا ICMP يُعرف حداثةً من آخر ظهور.
  Future<List<DeviceRow>> getRecent({Duration window = const Duration(minutes: 3)}) {
    final threshold = DateTime.now().subtract(window);
    return (select(devices)..where((t) => t.lastSeen.isBiggerThanValue(threshold)))
        .get();
  }

  Stream<List<DeviceRow>> watchFavorites() =>
      (select(devices)..where((t) => t.isFavorite.equals(true))).watch();

  // ── السجل التاريخي ──
  Future<int> addHistory(DeviceHistoryCompanion entry) =>
      into(deviceHistory).insert(entry);

  Stream<List<DeviceHistoryRow>> watchHistory(int deviceId) =>
      (select(deviceHistory)
            ..where((t) => t.deviceId.equals(deviceId))
            ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
            ..limit(200))
          .watch();

  Future<void> clearHistoryOlderThan(DateTime cutoff) =>
      (delete(deviceHistory)..where((t) => t.timestamp.isSmallerThanValue(cutoff)))
          .go();
}

// ════════════════════════════════════════════════════════════════
//  التنبيهات الأمنية
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [SecurityAlerts])
class SecurityAlertDao extends DatabaseAccessor<AppDatabase>
    with _$SecurityAlertDaoMixin {
  SecurityAlertDao(super.db);

  Stream<List<SecurityAlertRow>> watchAll() =>
      (select(securityAlerts)
            ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
          .watch();

  Stream<List<SecurityAlertRow>> watchActive() =>
      (select(securityAlerts)
            ..where((t) => t.isResolved.equals(false))
            ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
          .watch();

  Future<int> insert(SecurityAlertsCompanion alert) =>
      into(securityAlerts).insert(alert);

  Future<void> resolve(int id) =>
      (update(securityAlerts)..where((t) => t.id.equals(id))).write(
        SecurityAlertsCompanion(
          isResolved: const Value(true),
          resolvedAt: Value(DateTime.now()),
        ),
      );

  Future<int> resolveAll() =>
      (update(securityAlerts)..where((t) => t.isResolved.equals(false))).write(
        const SecurityAlertsCompanion(
          isResolved: Value(true),
        ),
      );

  Future<int> deleteAll() => delete(securityAlerts).go();
}

// ════════════════════════════════════════════════════════════════
//  اختبارات السرعة
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [SpeedTests])
class SpeedTestDao extends DatabaseAccessor<AppDatabase>
    with _$SpeedTestDaoMixin {
  SpeedTestDao(super.db);

  Stream<List<SpeedTestRow>> watchAll({int limit = 100}) =>
      (select(speedTests)
            ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
            ..limit(limit))
          .watch();

  Future<List<SpeedTestRow>> getAll({int limit = 100}) =>
      (select(speedTests)
            ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
            ..limit(limit))
          .get();

  Future<SpeedTestRow?> getLatest() =>
      (select(speedTests)
            ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insert(SpeedTestsCompanion test) => into(speedTests).insert(test);

  Future<SpeedTestRow?> getPeakDownload() =>
      (select(speedTests)
            ..where((t) => t.downloadMbps.isNotNull())
            ..orderBy([(t) => OrderingTerm(expression: t.downloadMbps, mode: OrderingMode.desc)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> clear() => delete(speedTests).go();
}

// ════════════════════════════════════════════════════════════════
//  أحداث الشبكة
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [NetworkEvents])
class NetworkEventDao extends DatabaseAccessor<AppDatabase>
    with _$NetworkEventDaoMixin {
  NetworkEventDao(super.db);

  Stream<List<NetworkEventRow>> watch({int limit = 200}) =>
      (select(networkEvents)
            ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
            ..limit(limit))
          .watch();

  Future<int> insert(NetworkEventsCompanion event) =>
      into(networkEvents).insert(event);

  Future<void> clearOlderThan(DateTime cutoff) =>
      (delete(networkEvents)..where((t) => t.timestamp.isSmallerThanValue(cutoff)))
          .go();
}

// ════════════════════════════════════════════════════════════════
//  إعدادات الراوترات
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [RouterSettings])
class RouterSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$RouterSettingsDaoMixin {
  RouterSettingsDao(super.db);

  Stream<List<RouterSettingRow>> watchAll() => select(routerSettings).watch();

  Future<List<RouterSettingRow>> getAll() => select(routerSettings).get();

  Future<RouterSettingRow?> getActive() =>
      (select(routerSettings)..where((t) => t.isActive.equals(true)))
          .getSingleOrNull();

  Future<int> insert(RouterSettingsCompanion router) =>
      into(routerSettings).insert(router);

  /// استبدال كامل للصف (اسم مختلف عن update المولّدة لتفادي التصادم).
  Future<bool> replaceRow(RouterSettingRow router) =>
      update(routerSettings).replace(router);

  /// يفعّل راوتراً واحداً فقط ويلغي تفعيل الباقي.
  Future<void> setActive(int id) async {
    await update(routerSettings)
        .write(const RouterSettingsCompanion(isActive: Value(false)));
    await (update(routerSettings)..where((t) => t.id.equals(id)))
        .write(RouterSettingsCompanion(isActive: const Value(true)));
  }

  Future<int> deleteById(int id) =>
      (delete(routerSettings)..where((t) => t.id.equals(id))).go();
}

// ════════════════════════════════════════════════════════════════
//  مسوحات المواقع (الخرائط الحرارية)
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [WifiSurveys])
class WifiSurveyDao extends DatabaseAccessor<AppDatabase>
    with _$WifiSurveyDaoMixin {
  WifiSurveyDao(super.db);

  Stream<List<WifiSurveyRow>> watchAll() =>
      (select(wifiSurveys)
            ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
          .watch();

  Future<WifiSurveyRow?> getById(int id) =>
      (select(wifiSurveys)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insert(WifiSurveysCompanion survey) =>
      into(wifiSurveys).insert(survey);

  /// استبدال كامل للصف (اسم مختلف عن update المولّدة لتفادي التصادم).
  Future<bool> replaceRow(WifiSurveyRow survey) =>
      update(wifiSurveys).replace(survey);

  /// تحديث جزئي للمسح بالمعرّف عبر Companion (الحقول Absent تبقى على حالها).
  Future<int> updateById(WifiSurveysCompanion survey, int id) =>
      (update(wifiSurveys)..where((t) => t.id.equals(id))).write(survey);

  Future<int> deleteById(int id) =>
      (delete(wifiSurveys)..where((t) => t.id.equals(id))).go();
}

// ════════════════════════════════════════════════════════════════
//  بيانات Wardriving
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [WardrivingData])
class WardrivingDao extends DatabaseAccessor<AppDatabase>
    with _$WardrivingDaoMixin {
  WardrivingDao(super.db);

  /// إدراج دفعي سريع أثناء المسح على الطريق.
  Future<void> insertMany(List<WardrivingDataCompanion> rows) =>
      batch((b) => b.insertAll(wardrivingData, rows, mode: InsertMode.insertOrReplace));

  /// إدراج نقطة وصول واحدة أو تحديثها إن كان الـ BSSID مسجّلاً.
  Future<void> upsert(WardrivingDataCompanion row) =>
      into(wardrivingData).insertOnConflictUpdate(row);

  Stream<List<WardrivingDatumRow>> watchAll() =>
      (select(wardrivingData)
            ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
            ..limit(2000))
          .watch();

  Future<List<WardrivingDatumRow>> getUnuploaded() =>
      (select(wardrivingData)..where((t) => t.uploaded.equals(false))).get();

  Future<void> markUploaded(List<int> ids) =>
      (update(wardrivingData)..where((t) => t.id.isIn(ids)))
          .write(const WardrivingDataCompanion(uploaded: Value(true)));

  /// عدد نقاط الواي فاي المسجّلة إجمالاً (إحصائية Wardriving).
  Future<int> count() async {
    final countExpr = wardrivingData.id.count();
    final query = selectOnly(wardrivingData)..addColumns([countExpr]);
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<int> clear() => delete(wardrivingData).go();
}
