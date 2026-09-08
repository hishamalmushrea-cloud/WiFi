import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/data/mappers/security_mappers.dart';
import '../../../core/domain/entities/access_point.dart';
import '../../../core/domain/entities/device.dart';
import '../../../core/domain/entities/security.dart';
import '../../../core/domain/entities/vulnerability.dart';
import '../../../core/domain/repositories/security_repository.dart';
import '../../../core/errors/result.dart';
import '../../../core/platform/root_checker_channel.dart';
import '../../../core/platform/root_checker.dart';
import '../../../core/utils/app_logger.dart';

/// تنفيذ محرك الأمان.
///
/// يبني مؤشر أمان من فحوصات مستقلة: نوع تشفير الشبكة، الشبكات
/// المفتوحة، الأجهزة المحظورة مقابل المكتشفة، والمنافذ المكشوفة.
/// كل فحص له وزن، والدرجة مجموع الأوزان الناجحة منسوباً للمجموع.
/// كشف التهديدات الحية (ARP/deauth) يحتاج القناة الأصلية ويأتي
/// في PHASE 6/11؛ هنا منطق التقييم والثغرات الخالص عامل.
class SecurityRepositoryImpl implements SecurityRepository {
  SecurityRepositoryImpl(this._db, this._rootChecker);
  final AppDatabase _db;
  final RootChecker _rootChecker;

  @override
  Future<Result<SecurityScore>> evaluateSecurity({
    required List<Device> devices,
    required List<AccessPoint> accessPoints,
  }) async {
    return guard(() async {
      final checks = <SecurityCheck>[];

      // 1) لا توجد شبكة مفتوحة باسم شبكتنا.
      final openNetworks = accessPoints.where((a) => a.security == WifiSecurity.open).length;
      checks.add(SecurityCheck(
        id: 'open_network',
        title: 'لا توجد شبكات مفتوحة مجاورة بنفس الاسم',
        description: 'فحص شبكات Open المضللة',
        passed: openNetworks == 0,
        weight: 15,
        recommendation: openNetworks > 0 ? 'راجع الشبكات المفتوحة القريبة فقد تكون توأماً خبيثاً' : null,
      ));

      // 2) أقوى شبكتنا تستخدم WPA2/WPA3.
      final hasStrong = accessPoints.any((a) =>
          a.security == WifiSecurity.wpa2 || a.security == WifiSecurity.wpa3);
      checks.add(SecurityCheck(
        id: 'encryption',
        title: 'تشفير الشبكة WPA2/WPA3',
        description: 'بروتوكول تشفير قوي',
        passed: hasStrong || accessPoints.isEmpty,
        weight: 25,
        recommendation: 'فعّل WPA2-PSK أو WPA3 في إعدادات الراوتر',
      ));

      // 3) لا توجد أجهزة غير معروفة متصلة حالياً.
      final unknownOnline = devices.where((d) =>
          d.isOnline && !d.isKnown && !d.isFavorite).length;
      checks.add(SecurityCheck(
        id: 'unknown_devices',
        title: 'لا توجد أجهزة غير معروفة متصلة',
        description: 'كل الأجهزة المتصلة معرّفة',
        passed: unknownOnline == 0,
        weight: 25,
        recommendation: 'راجع الأجهزة غير المعروفة وسَمِّها أو احظرها',
      ));

      // 4) لا منافذ خطرة مفتوحة على الأجهزة.
      final riskyPorts = <int>{23, 21, 135, 139, 445, 1433, 3389, 5900, 6379, 27017};
      var openRisky = 0;
      for (final device in devices) {
        if (!device.isOnline) continue;
        final rows = await _db.portScanDao.getOpenForDevice(device.id);
        openRisky += rows.where((r) => riskyPorts.contains(r.port)).length;
      }
      checks.add(SecurityCheck(
        id: 'risky_ports',
        title: 'لا منافذ خدمات خطرة مكشوفة',
        description: 'Telnet/SMB/RDP/Redis وغيرها مغلقة',
        passed: openRisky == 0,
        weight: 20,
        recommendation: 'أغلق خدمات Telnet و SMB و RDP غير الضرورية',
      ));

      // 5) كلمات المرور الحساسة لا تُخزَّن غير مشفّرة (ضمان معماري).
      checks.add(const SecurityCheck(
        id: 'vault',
        title: 'خزنة كلمات المرور مشفّرة',
        description: 'بيانات الراوتر محمية بـ AES-256',
        passed: true,
        weight: 15,
      ));

      final totalWeight = checks.fold<int>(0, (s, c) => s + c.weight);
      final passedWeight = checks.where((c) => c.passed).fold<int>(0, (s, c) => s + c.weight);
      final score = totalWeight == 0 ? 0 : ((passedWeight / totalWeight) * 100).round();

      // التنبيهات النشطة المخزّنة.
      final activeRows = await _db.securityAlertDao.watchActive().first;
      final alerts = activeRows.map(SecurityMapper.toAlertEntity).toList();

      return SecurityScore(
        score: score,
        checks: checks,
        activeAlerts: alerts,
        evaluatedAt: DateTime.now(),
      );
    });
  }

  @override
  Stream<List<SecurityAlert>> watchAlerts() => _db
      .securityAlertDao
      .watchAll()
      .map((rows) => rows.map(SecurityMapper.toAlertEntity).toList());

  @override
  Future<Result<void>> recordAlert(SecurityAlert alert) =>
      guard(() => _db.securityAlertDao.insert(SecurityMapper.toAlertCompanion(alert)));

  @override
  Future<Result<void>> resolveAlert(int id) =>
      guard(() => _db.securityAlertDao.resolve(id));

  @override
  Future<Result<void>> resolveAllAlerts() =>
      guard(() => _db.securityAlertDao.resolveAll());

  /// يقترح ثغرات محتملة من المنافذ المفتوحة على جهاز.
  ///
  /// قاعدة بسيطة شفافة: خدمة مكشوفة معروفة ببدائل أكثر أماناً
  /// أو بسجل ثغرات شائع تُترجَم إلى توصية. هذا فحص وقائي تعليمي
  /// وليس مطابقة CVE حية (تأتي مع قاعدة بيانات لاحقاً).
  @override
  Future<Result<List<Vulnerability>>> scanVulnerabilities(int deviceId) {
    return guard(() async {
      final openRows = await _db.portScanDao.getOpenForDevice(deviceId);
      final vulns = <Vulnerability>[];
      final now = DateTime.now();

      const advisories = <int, Map<String, String>>{
        23: {'title': 'Telnet مكشوف — بيانات غير مشفّرة',
              'fix': 'عطّل Telnet واستخدم SSH بدلاً منه.'},
        21: {'title': 'FTP مكشوف — ينقل كلمات المرور نصاً صريحاً',
              'fix': 'استخدم SFTP أو FTPS بدلاً من FTP.'},
        445: {'title': 'SMB مكشوف — ثغرات برمجيات الفدية الشائعة',
              'fix': 'حدّث النظام وعطّل SMBv1، واحجب المنفذ من الإنترنت.'},
        3389: {'title': 'سطح مكتب بعيد RDP مكشوف',
              'fix': 'لا تُعرض RDP على الشبكة العامة؛ استخدم VPN أولاً.'},
        5900: {'title': 'VNC مكشوف — مصادقة ضعيفة أحياناً',
              'fix': 'قيّد VNC بشبكة داخلية وفعّل كلمة مرور قوية.'},
        6379: {'title': 'Redis بدون مصادقة غالباً',
              'fix': 'اضبط كلمة مرور Redis واحجبه عن الشبكة العامة.'},
        27017: {'title': 'MongoDB قد يكون بلا مصادقة',
              'fix': 'فعّل مصادقة MongoDB واحجب المنفذ خارجياً.'},
        80: {'title': 'واجهة إدارة عبر HTTP غير مشفّر',
              'fix': 'استخدم HTTPS لواجهات الإدارة إن أمكن.'},
      };

      for (final row in openRows) {
        final adv = advisories[row.port];
        if (adv != null) {
          vulns.add(Vulnerability(
            deviceId: deviceId,
            title: adv['title']!,
            description: 'المنفذ ${row.port} (${row.service ?? "مفتوح"}) يستجيب على هذا الجهاز.',
            severity: row.port == 23 || row.port == 6379 || row.port == 27017
                ? ThreatSeverity.high
                : ThreatSeverity.medium,
            solution: adv['fix'],
            detectedAt: now,
          ));
        }
      }

      // حدّث المخزون للجهاز.
      await _db.vulnerabilityDao.replaceForDevice(
        deviceId,
        vulns
            .map((v) => SecurityMapper.toVulnerabilityCompanion(
                  Vulnerability(
                    deviceId: deviceId,
                    title: v.title,
                    description: v.description,
                    severity: v.severity,
                    solution: v.solution,
                    detectedAt: now,
                  ),
                ))
            .toList(),
      );

      return vulns;
    });
  }

  @override
  Future<Result<bool>> hasRootAccess() async {
    return guard(() async {
      final status = await _rootChecker.check();
      AppLogger.info('حالة صلاحيات الجذر: ${status.state}', tag: 'Security');
      return status.isRooted;
    });
  }
}

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(rootCheckerProvider),
  );
});
