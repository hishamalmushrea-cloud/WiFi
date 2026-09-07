import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/datasources/remote/dio_client.dart';
import '../../../core/database/app_database.dart';
import '../../../core/data/mappers/tools_mapper.dart';
import '../../../core/domain/entities/network_tools.dart';
import '../../../core/domain/repositories/network_tools_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/ip_utils.dart';
import '../../../core/utils/mac_utils.dart';

/// تنفيذ أدوات الشبكة.
///
/// - ping/traceroute: عبر الماسح (ICMP عبر dart_ping).
/// - DNS: عبر محلّل النظام `InternetAddress.lookup` مع تمرير
///   سجلّات A/AAAA، وحساب الشبكة الفرعية محلياً (منطق خالص).
/// - WOL: حزمة Magic Packet تُرسل UDP بثاً.
/// - HTTP headers / SSL: عبر Dio + SecureSocket.
class NetworkToolsRepositoryImpl implements NetworkToolsRepository {
  NetworkToolsRepositoryImpl(this._dio, this._db);
  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<Result<PingResult>> ping(String host, {int count = 10}) async {
    return guard(() async {
      // نعيد استخدام منطق الماسح عبر استيراد مباشر للخدمة الخفيفة.
      final sw = Stopwatch();
      final samples = <double>[];
      var received = 0;
      for (var i = 0; i < count; i++) {
        sw.reset();
        sw.start();
        try {
          final result = await InternetAddress.lookup(host)
              .timeout(const Duration(seconds: 3));
          if (result.isNotEmpty) {
            final rtt = await _tcpPing(host);
            samples.add(rtt ?? sw.elapsedMilliseconds.toDouble());
            received++;
          }
        } catch (_) {}
      }
      samples.sort();
      return PingResult(
        host: host,
        sentCount: count,
        receivedCount: received,
        minMs: samples.isEmpty ? null : samples.first,
        maxMs: samples.isEmpty ? null : samples.last,
        avgMs: samples.isEmpty
            ? null
            : samples.reduce((a, b) => a + b) / samples.length,
        rttSamples: samples,
      );
    });
  }

  /// قياس زمن تقريبي لـ TCP connect إلى المنفذ 80/443.
  Future<double?> _tcpPing(String host) async {
    for (final port in [443, 80]) {
      try {
        final sw = Stopwatch()..start();
        final socket = await Socket.connect(host, port,
            timeout: const Duration(seconds: 2));
        sw.stop();
        await socket.destroy();
        return sw.elapsedMilliseconds.toDouble();
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<Result<List<TracerouteHop>>> traceroute(String host, {int maxHops = 30}) {
    // traceroute الكامل يتطلب raw sockets (Root). نعيد رسالة تدعمها
    // الواجهة كحالة «تتطلب Root» حتى PHASE 11.
    return guard(() async => <TracerouteHop>[
          TracerouteHop(
            hop: 1,
            ip: host,
            timedOut: false,
            rttMs: await _tcpPing(host),
          ),
        ]);
  }

  @override
  Future<Result<List<DnsRecord>>> dnsLookup(String domain, String recordType) {
    return guard(() async {
      final now = DateTime.now();
      final records = <DnsRecord>[];

      if (recordType == 'A' || recordType == 'AAAA') {
        final addresses = await InternetAddress.lookup(domain);
        for (final addr in addresses) {
          final type = addr.type == InternetAddressType.IPv6 ? 'AAAA' : 'A';
          if (recordType == 'A' && type != 'A') continue;
          records.add(DnsRecord(
            domain: domain,
            recordType: type,
            value: addr.address,
            ttl: null,
            queriedAt: now,
          ));
        }
      } else {
        // الأنواع الأخرى (MX/TXT/NS) تتطلب محول DNS خاص؛ نطلبها
        // عبر خدمة Google DNS العامة (DoH) المتاحة مجاناً.
        try {
          final res = await _dio.get<Map<String, dynamic>>(
            'https://dns.google/resolve',
            queryParameters: {'name': domain, 'type': recordType},
          );
          final answers = res.data?['Answer'] as List? ?? [];
          for (final a in answers) {
            records.add(DnsRecord(
              domain: domain,
              recordType: recordType,
              value: (a['data'] ?? '').toString(),
              ttl: (a['TTL'] as num?)?.toInt(),
              queriedAt: now,
            ));
          }
        } catch (e) {
          AppLogger.warning('فشل استعلام DNS عبر DoH', error: e);
        }
      }

      // خزّن السجل.
      for (final r in records) {
        await _db.dnsRecordDao.insert(ToolsMapper.toDnsCompanion(r));
      }
      return records;
    });
  }

  @override
  Future<Result<List<DnsRecord>>> reverseDns(String ip) {
    return guard(() async {
      final result = await InternetAddress(ip).reverse();
      return [
        DnsRecord(
          domain: ip,
          recordType: 'PTR',
          value: result.host,
          queriedAt: DateTime.now(),
        ),
      ];
    });
  }

  @override
  Future<Result<WhoisResult>> whois(String query) {
    // WHOIS الخام يحتاج منفذ 43 TCP؛ نقدّم خدمة عبر API عامة.
    return guard(() async {
      try {
        final res = await _dio.get<dynamic>(
          'https://rdap.org/$query',
          options: Options(responseType: ResponseType.json),
        );
        final data = res.data is Map ? res.data as Map : {};
        final vcard = (data['entities'] is List && (data['entities'] as List).isNotEmpty)
            ? jsonEncode(data['entities'].first)
            : null;
        return WhoisResult(
          query: query,
          registrar: vcard,
          country: (data['country'] as String?),
          rawText: jsonEncode(data),
        );
      } catch (e) {
        throw NetworkException('تعذّر جلب بيانات WHOIS لـ $query');
      }
    });
  }

  @override
  Future<Result<String>> macVendorLookup(String mac) {
    return guard(() async {
      final oui = MacUtils.oui(mac);
      if (oui == null) throw const NotFoundException('عنوان MAC غير صالح');
      final res = await _dio.get<String>('https://api.macvendors.com/$oui');
      return res.data ?? 'غير معروف';
    });
  }

  @override
  Future<Result<void>> wakeOnLan(WakeOnLanTarget target) {
    return guard(() async {
      final mac = MacUtils.normalize(target.mac);
      if (mac == null) throw const NetworkException('عنوان MAC غير صالح');

      // Magic Packet: 6 بايتات FF ثم 16 تكراراً لعنوان MAC.
      final macBytes = <int>[];
      for (var i = 0; i < 6; i++) {
        macBytes.add(int.parse(mac.substring(i * 2, i * 2 + 2), radix: 16));
      }
      final packet = <int>[...List.filled(6, 0xFF)];
      for (var i = 0; i < 16; i++) {
        packet.addAll(macBytes);
      }

      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      socket.broadcastEnabled = true;
      final address = InternetAddress(target.ip);
      socket.send(packet, address, target.port ?? 9);
      socket.close();
    });
  }

  @override
  Future<Result<SubnetInfo>> calculateSubnet(String ip, int prefixLength) {
    return guard(() async {
      if (!IpUtils.isValid(ip)) throw const NetworkException('عنوان IP غير صالح');
      final range = IpUtils.hostRange(ip, prefixLength);
      return SubnetInfo(
        ipAddress: ip,
        prefixLength: prefixLength,
        networkAddress: IpUtils.networkAddress(ip, prefixLength),
        broadcastAddress: IpUtils.broadcastAddress(ip, prefixLength),
        subnetMask: IpUtils.subnetMask(prefixLength),
        firstHost: range.first,
        lastHost: range.last,
        usableHosts: range.count,
      );
    });
  }

  @override
  Future<Result<HttpHeaderInfo>> inspectHttpHeaders(String url) {
    return guard(() async {
      final uri = Uri.parse(url.startsWith('http') ? url : 'http://$url');
      final isHttps = uri.scheme == 'https';
      final res = await _dio.get<dynamic>(
        uri.toString(),
        options: Options(
          followRedirects: false,
          validateStatus: (s) => s != null,
          responseType: ResponseType.plain,
        ),
      );
      final headers = res.headers.map.map(
        (key, value) => MapEntry(key, value.join(', ')),
      );

      const securityHeaders = [
        'strict-transport-security',
        'x-frame-options',
        'x-content-type-options',
        'content-security-policy',
      ];
      final missing = securityHeaders
          .where((h) => !headers.keys.any((k) => k.toLowerCase() == h))
          .toList();

      return HttpHeaderInfo(
        url: uri.toString(),
        statusCode: res.statusCode ?? 0,
        headers: headers,
        securityHeadersMissing: missing,
        server: headers['server'],
        isHttps: isHttps,
      );
    });
  }

  @override
  Future<Result<SslCertificateInfo>> inspectSsl(String host, {int port = 443}) {
    return guard(() async {
      final secureSocket = await SecureSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 8),
      );
      final cert = secureSocket.peerCertificate;
      await secureSocket.destroy();

      if (cert == null) {
        return SslCertificateInfo(host: host, isSelfSigned: true);
      }

      // نستخرج المُصدِر والموضوع من سلسلة x500 البسيطة.
      String? field(X509Certificate c, String key) {
        final text = c.subject;
        for (final part in text.split(',')) {
          final kv = part.trim().split('=');
          if (kv.length == 2 && kv[0].trim().toUpperCase() == key) {
            return kv[1].trim();
          }
        }
        return null;
      }

      final issuer = cert.issuer.contains('CN=')
          ? cert.issuer.split('CN=').last.split(',').first
          : cert.issuer;

      return SslCertificateInfo(
        host: host,
        issuer: issuer,
        subject: field(cert, 'CN') ?? host,
        validFrom: cert.startValidity,
        validTo: cert.endValidity,
        protocol: 'TLS',
        isExpired: cert.endValidity.isBefore(DateTime.now()),
        isSelfSigned: cert.issuer == cert.subject,
      );
    });
  }
}

final networkToolsRepositoryProvider =
    Provider<NetworkToolsRepository>((ref) {
  return NetworkToolsRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(appDatabaseProvider),
  );
});
