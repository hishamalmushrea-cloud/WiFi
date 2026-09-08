// DAOs الخاصة بنتائج الفحص والثغرات والنشاط والـ DNS والشبكات
// المحفوظة ونقاط الوصول وتحليل القنوات.
part of '../app_database.dart';

// ════════════════════════════════════════════════════════════════
//  نتائج فحص المنافذ
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [PortScanResults])
class PortScanDao extends DatabaseAccessor<AppDatabase>
    with _$PortScanDaoMixin {
  PortScanDao(super.db);

  /// يُستبدل كل نتائج الجهاز عند إعادة فحصه حتى لا تتراكم منافذ
  /// مغلقة قديمة فوق الجديدة.
  Future<void> replaceForDevice(int deviceId, List<PortScanResultsCompanion> rows) {
    return transaction(() async {
      await (delete(portScanResults)..where((t) => t.deviceId.equals(deviceId))).go();
      await batch((b) => b.insertAll(portScanResults, rows));
    });
  }

  Stream<List<PortScanResultRow>> watchForDevice(int deviceId) =>
      (select(portScanResults)
            ..where((t) => t.deviceId.equals(deviceId))
            ..orderBy([(t) => OrderingTerm(expression: t.port)]))
          .watch();

  Future<List<PortScanResultRow>> getOpenForDevice(int deviceId) =>
      (select(portScanResults)
            ..where((t) => t.deviceId.equals(deviceId) & t.state.equals('open'))
            ..orderBy([(t) => OrderingTerm(expression: t.port)]))
          .get();

  Future<int> insert(PortScanResultsCompanion row) =>
      into(portScanResults).insert(row);
}

// ════════════════════════════════════════════════════════════════
//  الثغرات المكتشفة
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [Vulnerabilities])
class VulnerabilityDao extends DatabaseAccessor<AppDatabase>
    with _$VulnerabilityDaoMixin {
  VulnerabilityDao(super.db);

  Stream<List<VulnerabilityRow>> watchAll() =>
      (select(vulnerabilities)
            ..orderBy([(t) => OrderingTerm(expression: t.detectedAt, mode: OrderingMode.desc)]))
          .watch();

  Stream<List<VulnerabilityRow>> watchForDevice(int deviceId) =>
      (select(vulnerabilities)
            ..where((t) => t.deviceId.equals(deviceId))
            ..orderBy([(t) => OrderingTerm(expression: t.detectedAt, mode: OrderingMode.desc)]))
          .watch();

  Future<int> insert(VulnerabilitiesCompanion vuln) =>
      into(vulnerabilities).insert(vuln);

  Future<void> resolve(int id) =>
      (update(vulnerabilities)..where((t) => t.id.equals(id)))
          .write(const VulnerabilitiesCompanion(isResolved: Value(true)));

  Future<void> replaceForDevice(int deviceId, List<VulnerabilitiesCompanion> rows) {
    return transaction(() async {
      await (delete(vulnerabilities)..where((t) => t.deviceId.equals(deviceId))).go();
      await batch((b) => b.insertAll(vulnerabilities, rows));
    });
  }
}

// ════════════════════════════════════════════════════════════════
//  الجدول الزمني للنشاط
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [ActivityTimeline])
class ActivityTimelineDao extends DatabaseAccessor<AppDatabase>
    with _$ActivityTimelineDaoMixin {
  ActivityTimelineDao(super.db);

  Future<int> insert(ActivityTimelineCompanion entry) =>
      into(activityTimeline).insert(entry);

  Stream<List<ActivityTimelineRow>> watch({int limit = 300}) =>
      (select(activityTimeline)
            ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)])
            ..limit(limit))
          .watch();

  Future<void> clearOlderThan(DateTime cutoff) =>
      (delete(activityTimeline)..where((t) => t.startTime.isSmallerThanValue(cutoff)))
          .go();
}

// ════════════════════════════════════════════════════════════════
//  سجلات DNS
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [DnsRecords])
class DnsRecordDao extends DatabaseAccessor<AppDatabase>
    with _$DnsRecordDaoMixin {
  DnsRecordDao(super.db);

  Future<int> insert(DnsRecordsCompanion record) =>
      into(dnsRecords).insert(record);

  Future<List<DnsRecordRow>> getForDomain(String domain) =>
      (select(dnsRecords)..where((t) => t.domain.equals(domain))).get();

  Stream<List<DnsRecordRow>> watchAll({int limit = 200}) =>
      (select(dnsRecords)
            ..orderBy([(t) => OrderingTerm(expression: t.queriedAt, mode: OrderingMode.desc)])
            ..limit(limit))
          .watch();
}

// ════════════════════════════════════════════════════════════════
//  الشبكات المحفوظة
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [SavedNetworks])
class SavedNetworkDao extends DatabaseAccessor<AppDatabase>
    with _$SavedNetworkDaoMixin {
  SavedNetworkDao(super.db);

  Stream<List<SavedNetworkRow>> watchAll() =>
      (select(savedNetworks)
            ..orderBy([(t) => OrderingTerm(expression: t.savedAt, mode: OrderingMode.desc)]))
          .watch();

  Future<int> insert(SavedNetworksCompanion network) =>
      into(savedNetworks).insert(network);

  /// استبدال كامل للصف (اسم مختلف عن update المولّدة لتفادي التصادم).
  Future<bool> replaceRow(SavedNetworkRow network) =>
      update(savedNetworks).replace(network);

  Future<int> deleteById(int id) =>
      (delete(savedNetworks)..where((t) => t.id.equals(id))).go();

  Future<void> touchLastUsed(int id) =>
      (update(savedNetworks)..where((t) => t.id.equals(id)))
          .write(SavedNetworksCompanion(lastUsed: Value(DateTime.now())));
}

// ════════════════════════════════════════════════════════════════
//  نقاط الوصول (تحليل WiFi / Wardriving)
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [AccessPoints])
class AccessPointDao extends DatabaseAccessor<AppDatabase>
    with _$AccessPointDaoMixin {
  AccessPointDao(super.db);

  /// إدراج/تحديث حسب BSSID (القيد الفريد الطبيعي، لا المفتاح الأساسي).
  ///
  /// السبب: insertOnConflictUpdate يحسب التعارض على المفتاح الأساسي
  /// فقط، لكن لكل نقطة وصول صف ثابت يميّزه BSSID، فنكتب الاستعلام
  /// صراحةً ليُحدَّث الصف القائم عند تكرار BSSID في كل مسحة.
  Future<void> upsert(AccessPointsCompanion ap) async {
    final bssid = ap.bssid.value;
    final existing = await (select(accessPoints)
          ..where((t) => t.bssid.equals(bssid)))
        .getSingleOrNull();
    if (existing == null) {
      await into(accessPoints).insert(ap);
    } else {
      // يحدّث فقط الحقول الـ Present الواردة في المسحة، دون مسح بقية البيانات.
      await (update(accessPoints)..where((t) => t.bssid.equals(bssid)))
          .write(ap);
    }
  }

  Future<void> upsertMany(List<AccessPointsCompanion> aps) async {
    for (final ap in aps) {
      await upsert(ap);
    }
  }

  Stream<List<AccessPointRow>> watchAll() =>
      (select(accessPoints)
            ..orderBy([(t) => OrderingTerm(expression: t.rssi, mode: OrderingMode.desc)]))
          .watch();

  Future<List<AccessPointRow>> getByBand(String band) =>
      (select(accessPoints)..where((t) => t.band.equals(band))).get();

  Future<int> clear() => delete(accessPoints).go();
}

// ════════════════════════════════════════════════════════════════
//  تحليل القنوات (نتائج دورية لتقييم الازدحام)
// ════════════════════════════════════════════════════════════════
@DriftAccessor(tables: [ChannelAnalysis])
class ChannelAnalysisDao extends DatabaseAccessor<AppDatabase>
    with _$ChannelAnalysisDaoMixin {
  ChannelAnalysisDao(super.db);

  /// كل دورة تحليل تستبدل نتائج النطاق السابقة (تقييم لحظي).
  Future<void> replaceForBand(String band, List<ChannelAnalysisCompanion> rows) {
    return transaction(() async {
      await (delete(channelAnalysis)..where((t) => t.band.equals(band))).go();
      await batch((b) => b.insertAll(channelAnalysis, rows));
    });
  }

  Future<List<ChannelAnalysisRow>> getLatestForBand(String band) =>
      (select(channelAnalysis)
            ..where((t) => t.band.equals(band))
            ..orderBy([(t) => OrderingTerm(expression: t.channel)]))
          .get();

  Stream<List<ChannelAnalysisRow>> watchLatest() {
    // آخر تحليل لكل قناة — نُبسّطه بعرض أحدث سجل شامل للنطاقين.
    return (select(channelAnalysis)
          ..orderBy([(t) => OrderingTerm(expression: t.analyzedAt, mode: OrderingMode.desc)])
          ..limit(60))
        .watch();
  }
}
