import '../../database/app_database.dart';
import '../../domain/entities/network_tools.dart';

/// تحويلات سجلات DNS المخزّنة.
class ToolsMapper {
  const ToolsMapper._();

  static DnsRecord toDnsEntity(DnsRecordRow r) => DnsRecord(
        id: r.id,
        domain: r.domain,
        recordType: r.recordType,
        value: r.value,
        ttl: r.ttl,
        queriedAt: r.queriedAt,
      );

  static DnsRecordsCompanion toDnsCompanion(DnsRecord r) =>
      DnsRecordsCompanion(
        domain: Value(r.domain),
        recordType: Value(r.recordType),
        value: Value(r.value),
        ttl: Value(r.ttl),
        queriedAt: Value(r.queriedAt),
      );
}
