import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upnp/upnp.dart' as upnp;

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
            if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
              final service = event.service;
              if (service is ResolvedBonsoirService) {
                final key = '${service.name}:${service.host}:${service.port}';
                found[key] = DiscoveredService(
                  name: service.name,
                  type: type,
                  host: service.host,
                  ip: service.ip,
                  port: service.port,
                  attributes: Map<String, String>.from(service.attributes ?? {}),
                );
              } else {
                // خدمة غير محلولة بعد — نطلب حلّها للحصول على IP.
                service.resolve(service);
              }
            } else if (event.type ==
                BonsoirDiscoveryEventType.discoveryServiceResolved) {
              final service = event.service;
              if (service is ResolvedBonsoirService) {
                final key = '${service.name}:${service.host}:${service.port}';
                found[key] = DiscoveredService(
                  name: service.name,
                  type: type,
                  host: service.host,
                  ip: service.ip,
                  port: service.port,
                  attributes:
                      Map<String, String>.from(service.attributes ?? {}),
                );
              }
            }
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

  Future<List<DiscoveredService>> _discoverUpnp(Duration timeout) async {
    final results = <DiscoveredService>[];
    try {
      final discoverer = upnp.DeviceDiscoverer();
      final devices = await discoverer
          .quickDiscoverClients(timeout: timeout)
          .toList()
          .catchError((Object e) {
        AppLogger.warning('فشل اكتشاف UPnP', error: e);
        return <upnp.DiscoveredClient>[];
      });

      for (final client in devices) {
        try {
          final device = await client.getDevice();
          results.add(DiscoveredService(
            name: device.friendlyName ?? client.location?.host ?? 'جهاز UPnP',
            type: '_upnp._tcp',
            host: client.location?.host,
            ip: client.location?.host,
            port: client.location?.port,
            source: 'upnp',
            attributes: {
              if (device.manufacturer != null) 'manufacturer': device.manufacturer!,
              if (device.modelName != null) 'model': device.modelName!,
              'udn': device.udn ?? '',
            },
          ));
        } catch (e) {
          // تعذّر جلب تفاصيل الجهاز — نكتفي بالعنوان.
          results.add(DiscoveredService(
            name: client.location?.host ?? 'جهاز UPnP',
            type: '_upnp._tcp',
            ip: client.location?.host,
            port: client.location?.port,
            source: 'upnp',
          ));
        }
      }
    } catch (e) {
      AppLogger.warning('تعذّر بدء اكتشاف UPnP', error: e);
    }
    return results;
  }
}

final serviceDiscoveryProvider =
    Provider<ServiceDiscovery>((ref) => const ServiceDiscovery());
