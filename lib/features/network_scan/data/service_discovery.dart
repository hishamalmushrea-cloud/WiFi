import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/discovered_service.dart';
import '../../../core/utils/app_logger.dart';

/// اكتشاف خدمات الشبكة المحلية عبر mDNS/Bonjour و UPnP/SSDP.
///
/// السبب: الكثير من الأجهزة لا تردّ على ping (جدران حماية) لكنها
/// تعلن عن خدماتها عبر mDNS (Apple/Google/طابعات) أو UPnP
/// (راوترات، أجهزة DLNA). دمج المصدرين يرفع دقة كشف الأجهزة
/// ويُغني بصمة الجهاز (نوعه/نظامه) دون أي صلاحيات Root.
class ServiceDiscovery {
  const ServiceDiscovery();

  /// أنواع خدمات Bonjour الشائعة التي تكشف نوع الجهاز.
  static const _mdnsTypes = <String>[
    '_http._tcp',
    '_ssh._tcp',
    '_smb._tcp',
    '_airplay._tcp',
    '_googlecast._tcp',
    '_hap._tcp', // HomeKit (Apple)
    '_ipp._tcp', // طابعات
    '_printer._tcp',
    '_pdl-datastream._tcp',
    '_device-info._tcp',
    '_raop._tcp', // AirPlay audio
    '_spotify-connect._tcp',
  ];

  Future<List<DiscoveredService>> discoverAll({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final results = <DiscoveredService>[];
    // نجمع المصدرين بالتوازي؛ فشل أحدهما لا يُسقط الآخر.
    final (mdns, upnpResults) = await (
      _discoverMdns(timeout),
      _discoverUpnp(timeout),
    ).wait;
    results.addAll(mdns);
    results.addAll(upnpResults);
    AppLogger.info(
      'اكتُشفت ${results.length} خدمة (mDNS: ${mdns.length}، UPnP: ${upnpResults.length})',
      tag: 'ServiceDiscovery',
    );
    return results;
  }

  Future<List<DiscoveredService>> _discoverMdns(Duration timeout) async {
    final found = <String, DiscoveredService>{};
    final scans = <BonsoirDiscovery>[];

    try {
      for (final type in _mdnsTypes) {
        try {
          final discovery = BonsoirDiscovery(type: type);
          scans.add(discovery);
          await discovery.ready;

          discovery.eventStream?.listen((event) {
            final isFoundOrResolved =
                event.type == BonsoirDiscoveryEventType.discoveryServiceFound ||
                    event.type ==
                        BonsoirDiscoveryEventType.discoveryServiceResolved;
            if (!isFoundOrResolved) return;
            final service = event.service;
            if (service == null) return;
            if (service is! ResolvedBonsoirService) {
              // خدمة غير محلولة بعد — نطلب حلّها للحصول على المضيف.
              service.resolve(discovery.serviceResolver);
              return;
            }
            // Bonsoir 5.x يوفّر اسم المضيف (host) لا عمود IP منفصلاً.
            final key = '${service.name}:${service.host}:${service.port}';
            found[key] = DiscoveredService(
              name: service.name,
              type: type,
              host: service.host,
              ip: service.host,
              port: service.port,
              attributes: Map<String, String>.from(service.attributes),
            );
          });
          await discovery.start();
        } catch (e) {
          AppLogger.warning('فشل مسح mDNS لـ $type', error: e);
        }
      }
      await Future<void>.delayed(timeout);
    } finally {
      for (final scan in scans) {
        try {
          await scan.stop();
        } catch (_) {}
      }
    }

    return found.values.toList();
  }

  /// اكتشاف أجهزة UPnP عبر SSDP مباشرة (بدون حزمة upnp المتوقفة عند Dart 2).
  ///
  /// السبب: حزمة upnp الرسمية آخر إصدار 2.0.1 مبني على Dart <3 ولا
  /// يحل مع Dart 3، لذلك ننفّذ M-SEARCH على مجموعة SSDP المتعددة
  /// الإرسال (239.255.255.250:1900) عبر [RawDatagramSocket] المدمج
  /// في dart:io، ونقرأ ترويسة LOCATION لرسم عنوان الجهاز.
  Future<List<DiscoveredService>> _discoverUpnp(Duration timeout) async {
    final results = <String, DiscoveredService>{};
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        ttl: 4,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;
      socket.multicastHops = 4;

      // رسالة M-SEARCH التي تستجيب لها أجهزة UPnP (راوترات، طابعات…).
      final search = 'M-SEARCH * HTTP/1.1\r\n'
              'HOST: 239.255.255.250:1900\r\n'
              'MAN: "ssdp:discover"\r\n'
              'MX: 2\r\n'
              'ST: ssdp:all\r\n\r\n'
          .codeUnits;
      final multicast = InternetAddress('239.255.255.250');

      // نرسل عدة مرات على فترات قصيرة فأجهزة الشبكة قد تتفقد حزمة.
      for (var i = 0; i < 3; i++) {
        socket.send(search, multicast, 1900);
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }

      final completer = Completer<void>();
      final timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete();
      });

      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket!.receive();
        if (datagram == null) return;
        final text = String.fromCharCodes(datagram.data);
        final location = _ssdpHeader(text, 'LOCATION');
        if (location == null) return;

        final uri = Uri.tryParse(location);
        if (uri == null || uri.host.isEmpty) return;
        final key = '${uri.host}:${uri.port}';
        final server = _ssdpHeader(text, 'SERVER');
        results.putIfAbsent(
          key,
          () => DiscoveredService(
            name: uri.host,
            type: '_upnp._tcp',
            host: uri.host,
            ip: uri.host,
            port: uri.port,
            source: 'upnp',
            attributes: {
              if (server != null) 'server': server,
              'location': location,
            },
          ),
        );
      });

      await completer.future;
      timer.cancel();
    } catch (e) {
      AppLogger.warning('تعذّر بدء اكتشاف UPnP/SSDP', error: e);
    } finally {
      socket?.close();
    }
    return results.values.toList();
  }

  /// يستخرج قيمة ترويسة من ردّ SSDP (مثل LOCATION/SERVER) دون حساسية حالة.
  String? _ssdpHeader(String response, String name) {
    for (final line in response.split('\r\n')) {
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final key = line.substring(0, idx).trim().toUpperCase();
      if (key == name.toUpperCase()) {
        return line.substring(idx + 1).trim();
      }
    }
    return null;
  }
}

final serviceDiscoveryProvider =
    Provider<ServiceDiscovery>((ref) => const ServiceDiscovery());
