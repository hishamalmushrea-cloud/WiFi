import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_tools.freezed.dart';

/// نتيجة فحص Ping واحدة.
@freezed
class PingResult with _$PingResult {
  const PingResult._();

  const factory PingResult({
    required String host,
    required int sentCount,
    required int receivedCount,
    double? minMs,
    double? avgMs,
    double? maxMs,
    @Default([]) List<double> rttSamples,
  }) = _PingResult;

  /// نسبة الفقدان (0–100).
  double get packetLoss => sentCount == 0 ? 100 : (1 - receivedCount / sentCount) * 100;
}

/// قفزة في مسار Traceroute.
@freezed
class TracerouteHop with _$TracerouteHop {
  const factory TracerouteHop({
    required int hop,
    required String ip,
    String? hostname,
    double? rttMs,
    @Default(false) bool timedOut,
  }) = _TracerouteHop;
}

/// سجل DNS واحد.
@freezed
class DnsRecord with _$DnsRecord {
  const factory DnsRecord({
    int? id,
    required String domain,
    required String recordType,
    required String value,
    int? ttl,
    required DateTime queriedAt,
  }) = _DnsRecord;
}

/// نتيجة استعلام WHOIS.
@freezed
class WhoisResult with _$WhoisResult {
  const factory WhoisResult({
    required String query,
    String? registrar,
    String? registrant,
    DateTime? created,
    DateTime? expires,
    String? nameServers,
    String? country,
    String? rawText,
  }) = _WhoisResult;
}

/// نتيجة حاسبة الشبكة الفرعية.
@freezed
class SubnetInfo with _$SubnetInfo {
  const SubnetInfo._();

  const factory SubnetInfo({
    required String ipAddress,
    required int prefixLength,
    required String networkAddress,
    required String broadcastAddress,
    required String subnetMask,
    required String firstHost,
    required String lastHost,
    required int usableHosts,
  }) = _SubnetInfo;

  String get cidr => '$networkAddress/$prefixLength';
}

/// هدف Wake-on-LAN.
@freezed
class WakeOnLanTarget with _$WakeOnLanTarget {
  const factory WakeOnLanTarget({
    required String mac,
    required String ip,
    String? label,
    int? port,
  }) = _WakeOnLanTarget;
}

/// نتيجة فحص ترويسات HTTP.
@freezed
class HttpHeaderInfo with _$HttpHeaderInfo {
  const factory HttpHeaderInfo({
    required String url,
    required int statusCode,
    required Map<String, String> headers,
    @Default([]) List<String> securityHeadersMissing,
    String? server,
    @Default(false) bool isHttps,
  }) = _HttpHeaderInfo;
}

/// معلومات شهادة SSL/TLS.
@freezed
class SslCertificateInfo with _$SslCertificateInfo {
  const factory SslCertificateInfo({
    required String host,
    String? issuer,
    String? subject,
    DateTime? validFrom,
    DateTime? validTo,
    String? protocol,
    String? cipher,
    @Default(false) bool isExpired,
    @Default(false) bool isSelfSigned,
  }) = _SslCertificateInfo;
}
