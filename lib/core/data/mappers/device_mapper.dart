import '../../database/app_database.dart';
import '../../domain/entities/device.dart';
import '../../utils/mac_utils.dart';

/// تحويل صفوف Drift ↔ كيانات المجال للأجهزة وسجلها.
///
/// السبب: طبقة العرض/المجال لا تعرف شيئاً عن Drift، فنعزل
/// شكل التخزين هنا. النصوص/الأرقام الحرة في الجدول (نوع الجهاز،
/// نوع الاتصال) تُحوَّل إلى enums آمنة في الكيان.
class DeviceMapper {
  const DeviceMapper._();

  static Device toEntity(DeviceRow r) => Device(
        id: r.id,
        ip: r.ip,
        mac: MacUtils.pretty(r.mac) ?? r.mac,
        name: r.name,
        vendor: r.vendor,
        os: r.os,
        type: _parseType(r.deviceType),
        fingerprint: r.fingerprint,
        hostname: r.hostname,
        connectionType: _parseConnection(r.connectionType),
        signalStrength: r.signalStrength,
        throughputKbps: r.throughput,
        isBlocked: r.isBlocked,
        speedLimitKbps: r.speedLimitKbps,
        dataUsageBytes: r.dataUsageBytes,
        firstSeen: r.firstSeen,
        lastSeen: r.lastSeen,
        isFavorite: r.isFavorite,
        isKnown: r.isKnown,
        notes: r.notes,
      );

  static DevicesCompanion toCompanion(Device d) => DevicesCompanion(
        id: d.id == 0 ? const Value.absent() : Value(d.id),
        ip: Value(d.ip),
        mac: Value(MacUtils.normalize(d.mac) ?? d.mac),
        name: Value(d.name),
        vendor: Value(d.vendor),
        os: Value(d.os),
        deviceType: Value(d.type.name),
        fingerprint: Value(d.fingerprint),
        hostname: Value(d.hostname),
        connectionType: Value(d.connectionType.name),
        signalStrength: Value(d.signalStrength),
        throughput: Value(d.throughputKbps),
        isBlocked: Value(d.isBlocked),
        speedLimitKbps: Value(d.speedLimitKbps),
        dataUsageBytes: Value(d.dataUsageBytes),
        firstSeen: Value(d.firstSeen),
        lastSeen: Value(d.lastSeen),
        isFavorite: Value(d.isFavorite),
        isKnown: Value(d.isKnown),
        notes: Value(d.notes),
      );

  static DeviceHistoryEntry toHistoryEntity(DeviceHistoryRow r) =>
      DeviceHistoryEntry(
        id: r.id,
        deviceId: r.deviceId,
        timestamp: r.timestamp,
        isOnline: r.isOnline,
        rssi: r.rssi,
        connectionType:
            r.connectionType == null ? null : _parseConnection(r.connectionType!),
        throughputKbps: r.throughput,
        ipAddress: r.ipAddress,
      );

  static DeviceType _parseType(String raw) => DeviceType.values
      .firstWhere((t) => t.name == raw, orElse: () => DeviceType.unknown);

  static ConnectionType _parseConnection(String raw) =>
      ConnectionType.values
          .firstWhere((t) => t.name == raw, orElse: () => ConnectionType.unknown);
}
