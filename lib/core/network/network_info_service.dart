import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// معلومات الشبكة المحلية الحالية.
///
/// قيم قابلة للقراءة بأمان على المنصتين؛ أي تعذّر يُعاد null
/// (مثلاً iOS يمنع BSSID بدون صلاحية موقع دقيقة).
class LocalNetworkInfo {
  const LocalNetworkInfo({
    this.deviceIp,
    this.gatewayIp,
    this.subnet,
    this.wifiName,
    this.bssid,
    this.ipv6,
  });

  final String? deviceIp;
  final String? gatewayIp;
  final String? subnet;
  final String? wifiName;
  final String? bssid;
  final String? ipv6;
}

/// واجهة موحّدة لمعلومات الشبكة.
abstract class NetworkInfoService {
  Future<LocalNetworkInfo> read();
}

 /// يجمع بين [network_info_plus] (القيم المتاحة عبر Flutter)
 /// والقناة الأصلية (البوابة وجدول ARP — PHASE 11) في مصدر واحد.
class NetworkInfoServiceImpl implements NetworkInfoService {
  NetworkInfoServiceImpl(this._channel);
  final MethodChannel _channel;

  @override
  Future<LocalNetworkInfo> read() async {
    final info = NetworkInfo();

    String? deviceIp;
    String? wifiName;
    String? bssid;
    String? ipv6;
    try {
      deviceIp = await info.getWifiIP();
      wifiName = await info.getWifiName();
      bssid = await info.getWifiBSSID();
      ipv6 = await info.getWifiIPv6();
    } catch (e, st) {
      // بعض المنصات ترمي قبل منح صلاحية الموقع؛ نكتفي بالقناة الأصلية.
      AppLogger.warning('تعذّرت قراءة معلومات WiFi عبر network_info_plus',
          error: e, stackTrace: st);
    }

    String? gatewayIp;
    String? subnet;
    try {
      final native = await _channel.invokeMapMethod<String, dynamic>('getNetworkInfo');
      gatewayIp = native?['gateway'] as String?;
      subnet = native?['subnet'] as String?;
    } on MissingPluginException {
      // الكود الأصلي يأتي في PHASE 11.
    } on PlatformException catch (e, st) {
      AppLogger.error('فشلت قراءة معلومات الشبكة من القناة', error: e, stackTrace: st);
    }

    return LocalNetworkInfo(
      deviceIp: deviceIp,
      gatewayIp: gatewayIp,
      subnet: subnet,
      wifiName: wifiName,
      bssid: bssid,
      ipv6: ipv6,
    );
  }
}

final networkInfoServiceProvider = Provider<NetworkInfoService>(
  (ref) => NetworkInfoServiceImpl(
    const MethodChannel(AppConstants.channelNetwork),
  ),
);
