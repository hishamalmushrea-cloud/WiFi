import 'dart:async';
import 'dart:io';

import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/domain/entities/device.dart';
import '../../../core/domain/entities/network_info.dart';
import '../../../core/domain/entities/network_tools.dart';
import '../../../core/domain/entities/vulnerability.dart';
import '../../../core/domain/repositories/network_scanner_repository.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/network_info_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/ip_utils.dart';
import '../../../core/utils/port_utils.dart';

/// تنفيذ ماسح الشبكة.
///
/// الآلية (بدون Root — الميزة 96):
///  1) نقرأ IP الجهاز والبوابة.
///  2) نرسل ping متزامناً بدفعات لكل عنوان في /24.
///  3) نقرأ جدول ARP (عبر القناة الأصلية، PHASE 11) للحصول على MAC
///     للأجهزة التي ردّت — وهو ما يفرّق الأجهزة فعلياً المتصلة.
///  4) نُرجع الأجهزة المكتشفة مع تقدّم لحظي.
class NetworkScannerRepositoryImpl implements NetworkScannerRepository {
  NetworkScannerRepositoryImpl(this._networkInfo, this._channel);

  final NetworkInfoService _networkInfo;
  final MethodChannel _channel;

  @override
  Future<Result<NetworkInfoData>> getLocalNetworkInfo() async {
    return guard(() async {
      final info = await _networkInfo.read();
      return NetworkInfoData(
        deviceIp: info.deviceIp,
        gatewayIp: info.gatewayIp,
        subnet: info.subnet,
        wifiName: info.wifiName,
        bssid: info.bssid,
        ipv6: info.ipv6,
      );
    });
  }

  @override
  Future<Result<List<Device>>> scanNetwork({
    void Function(ScanProgress, List<Device>)? onProgress,
  }) async {
    return guard(() async {
      final info = await _networkInfo.read();
      final myIp = info.deviceIp;
      if (myIp == null || !IpUtils.isValid(myIp)) {
        throw const NetworkException('تعذّر تحديد عنوان الشبكة المحلية');
      }

      final hosts = IpUtils.enumerateHosts(
        IpUtils.networkAddress(myIp, 24),
        24,
      );
      final total = hosts.length;
      final found = <Device>[];
      var scanned = 0;

      // جدول ARP: MAC لكل IP (متاح بعد مرور حركة على العنوان).
      Map<String, String> arpTable = {};

      // معالجة بدفعات للتحكم بعدد الطلبات المتزامنة.
      for (var start = 0; start < hosts.length;
          start += AppConstants.lanScanBatchSize) {
        final batch = hosts.skip(start).take(AppConstants.lanScanBatchSize).toList();
        await Future.wait(
          batch.map((ip) => _probeHost(ip).then((alive) async {
                scanned++;
                if (alive) {
                  // نقرأ ARP لحظة وجود رد.
                  arpTable = await _readArpTable();
                  final mac = arpTable[ip] ?? '00:00:00:00:00:00';
                  final now = DateTime.now();
                  found.add(Device(
                    id: 0,
                    ip: ip,
                    mac: mac,
                    lastSeen: now,
                    firstSeen: now,
                    hostname: ip,
                    vendor: null,
                  ));
                }
                onProgress?.call(
                  ScanProgress(scanned: scanned, total: total, found: found.length),
                  List.unmodifiable(found),
                );
              })),
        );
      }

      AppLogger.info('اكتمل الفحص: ${found.length} جهاز', tag: 'LanScan');
      return found;
    });
  }

  /// يرسل ping واحداً سريعاً للعنوان؛ يرد حياً = موجود.
  Future<bool> _probeHost(String ip) async {
    try {
      final ping = Ping(ip, count: 1, timeout: AppConstants.shortTimeout.inSeconds);
      final result = await ping.stream.first;
      return result.response != null;
    } catch (_) {
      return false;
    }
  }

  /// يقرأ جدول ARP عبر القناة الأصلية (Kotlin/Swift — PHASE 11).
  /// قبل ذلك يعود بجدول فارغ فيعمل الفحص بـ ping فقط.
  Future<Map<String, String>> _readArpTable() async {
    try {
      final result = await _channel.invokeMapMethod<String, String>('getArpTable');
      return result ?? {};
    } on MissingPluginException {
      return {};
    } catch (e) {
      AppLogger.warning('تعذّرت قراءة جدول ARP', error: e);
      return {};
    }
  }

  @override
  Future<Result<List<PortScanResult>>> scanPorts(
    String ip, {
    required List<int> ports,
    void Function(int done, int total)? onProgress,
  }) async {
    return guard(() async {
      final results = <PortScanResult>[];
      var done = 0;

      // فحص اتصال TCP كامل (متاح بدون Root) بحد تزامن مدمج.
      final semaphore = _Semaphore(AppConstants.portScanConcurrency);
      await Future.wait(
        ports.map((port) async {
          await semaphore.run(() async {
            final state = await _probeTcpPort(ip, port);
            if (state == PortState.open) {
              results.add(PortScanResult(
                port: port,
                state: PortState.open,
                service: PortUtils.serviceName(port),
                scannedAt: DateTime.now(),
              ));
            }
            done++;
            onProgress?.call(done, ports.length);
          });
        }),
      );

      results.sort((a, b) => a.port.compareTo(b.port));
      return results;
    });
  }

  /// فحص منفذ TCP بمحاولة اتصال قصيرة.
  Future<PortState> _probeTcpPort(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(milliseconds: 1200),
      );
      socket.destroy();
      return PortState.open;
    } on SocketException {
      return PortState.closed;
    } catch (_) {
      return PortState.closed;
    }
  }

  @override
  Future<Result<PingResult>> ping(String host, {int count = 10}) async {
    return guard(() async {
      final ping = Ping(host, count: count, timeout: AppConstants.shortTimeout.inSeconds);
      final samples = <double>[];
      var received = 0;

      await for (final event in ping.stream) {
        if (event.response != null) {
          received++;
          final rtt = event.response?.time?.inMilliseconds.toDouble();
          if (rtt != null) samples.add(rtt);
        }
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

  @override
  Future<Result<List<TracerouteHop>>> traceroute(String host) async {
    // traceroute الحقيقي يحتاج raw sockets (Root على Android).
    // بدون Root نقدّم قفزات عبر طبقات متتالية من Ping بمهلة متدرجة
    // كأفضل جهد، ونشير لاحقاً في الواجهة لدقته المحدودة.
    return guard(() async {
      final hops = <TracerouteHop>[];
      for (var ttl = 1; ttl <= 8; ttl++) {
        try {
          final ping = Ping(host, count: 1, timeout: 2, ttl: ttl);
          final event = await ping.stream.first;
          final ip = event.response?.ip ?? host;
          hops.add(TracerouteHop(
            hop: ttl,
            ip: ip,
            rttMs: event.response?.time?.inMilliseconds.toDouble(),
            timedOut: event.response == null,
          ));
          if (ip == host) break;
        } catch (_) {
          hops.add(TracerouteHop(hop: ttl, ip: '*', timedOut: true));
        }
      }
      return hops;
    });
  }
}

/// إشارة بسيطة للحد من التزامن.
class _Semaphore {
  _Semaphore(this._max);
  final int _max;
  int _active = 0;
  final _queue = <Completer<void>>[];

  Future<T> run<T>(Future<T> Function() task) async {
    if (_active >= _max) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }
    _active++;
    try {
      return await task();
    } finally {
      _active--;
      if (_queue.isNotEmpty) _queue.removeAt(0).complete();
    }
  }
}

final networkScannerRepositoryProvider =
    Provider<NetworkScannerRepository>((ref) {
  return NetworkScannerRepositoryImpl(
    ref.watch(networkInfoServiceProvider),
    const MethodChannel(AppConstants.channelNetwork),
  );
});
