import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../domain/entities/security.dart';
import '../../domain/entities/vulnerability.dart';

/// تحويلات التنبيهات الأمنية والثغرات والمنافذ.
class SecurityMapper {
  const SecurityMapper._();

  // ── التنبيهات ──
  static SecurityAlert toAlertEntity(SecurityAlertRow r) => SecurityAlert(
        id: r.id,
        type: _parseAlertType(r.type),
        severity: _parseSeverity(r.severity),
        title: r.title,
        description: r.description,
        sourceIp: r.sourceIp,
        sourceMac: r.sourceMac,
        targetIp: r.targetIp,
        targetMac: r.targetMac,
        details: r.details,
        timestamp: r.timestamp,
        isResolved: r.isResolved,
        resolvedAt: r.resolvedAt,
      );

  static SecurityAlertsCompanion toAlertCompanion(SecurityAlert a) =>
      SecurityAlertsCompanion(
        type: Value(a.type.name),
        severity: Value(a.severity.name),
        title: Value(a.title),
        description: Value(a.description),
        sourceIp: Value(a.sourceIp),
        sourceMac: Value(a.sourceMac),
        targetIp: Value(a.targetIp),
        targetMac: Value(a.targetMac),
        details: Value(a.details),
        timestamp: Value(a.timestamp),
        isResolved: Value(a.isResolved),
        resolvedAt: Value(a.resolvedAt),
      );

  // ── الثغرات ──
  static Vulnerability toVulnerabilityEntity(VulnerabilityRow r) =>
      Vulnerability(
        id: r.id,
        deviceId: r.deviceId,
        cveId: r.cveId,
        title: r.title,
        description: r.description,
        severity: _parseSeverity(r.severity),
        cvssScore: r.cvssScore,
        solution: r.solution,
        references: r.references?.split('\n'),
        detectedAt: r.detectedAt,
        isResolved: r.isResolved,
      );

  static VulnerabilitiesCompanion toVulnerabilityCompanion(Vulnerability v) =>
      VulnerabilitiesCompanion(
        deviceId: Value(v.deviceId ?? 0),
        cveId: Value(v.cveId),
        title: Value(v.title),
        description: Value(v.description),
        severity: Value(v.severity.name),
        cvssScore: Value(v.cvssScore),
        solution: Value(v.solution),
        references: Value(v.references?.join('\n')),
        detectedAt: Value(v.detectedAt),
        isResolved: Value(v.isResolved),
      );

  // ── نتائج المنافذ ──
  static PortScanResult toPortEntity(PortScanResultRow r) => PortScanResult(
        id: r.id,
        deviceId: r.deviceId,
        port: r.port,
        protocol: r.protocol == 'udp' ? PortProtocol.udp : PortProtocol.tcp,
        state: _parsePortState(r.state),
        service: r.service,
        version: r.version,
        banner: r.banner,
        scannedAt: r.scannedAt,
      );

  static PortScanResultsCompanion toPortCompanion(
    PortScanResult p,
    int deviceId,
  ) =>
      PortScanResultsCompanion(
        deviceId: Value(deviceId),
        port: Value(p.port),
        protocol: Value(p.protocol == PortProtocol.udp ? 'udp' : 'tcp'),
        state: Value(_portStateString(p.state)),
        service: Value(p.service),
        version: Value(p.version),
        banner: Value(p.banner),
        scannedAt: Value(p.scannedAt),
      );

  // ── تحويلات النصوص إلى enums ──
  static ThreatSeverity _parseSeverity(String raw) =>
      ThreatSeverity.values
          .firstWhere((s) => s.name == raw, orElse: () => ThreatSeverity.medium);

  static SecurityAlertType _parseAlertType(String raw) =>
      SecurityAlertType.values
          .firstWhere((t) => t.name == raw, orElse: () => SecurityAlertType.other);

  static PortState _parsePortState(String raw) => switch (raw) {
        'open' => PortState.open,
        'filtered' => PortState.filtered,
        _ => PortState.closed,
      };

  static String _portStateString(PortState s) => switch (s) {
        PortState.open => 'open',
        PortState.filtered => 'filtered',
        PortState.closed => 'closed',
      };
}
