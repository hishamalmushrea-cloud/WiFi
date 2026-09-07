import '../../../../core/domain/entities/router.dart';

/// واجهة متحكّم راوتر.
///
/// كل ماركة (TP-Link، Huawei، Xiaomi…) تنفّذ هذه الواجهة بمنطق
/// HTTP الخاص بمسارات واجهتها. العمليات المشتركة لها تنفيذ
/// افتراضي في [BaseRouterController] وتتجاوزها الماركة عند الحاجة.
abstract class RouterController {
  /// الماركة التي يمثلها هذا المتحكم.
  RouterBrand get brand;

  /// تسجيل الدخول وفتح جلسة.
  Future<bool> login({
    required String ip,
    required String username,
    required String password,
  });

  /// معلومات الراوتر (الموديل/الإصدار).
  Future<RouterInfo> getInfo();

  Future<RouterTrafficStats> getTrafficStats();

  Future<List<RouterClient>> getConnectedClients();

  Future<bool> blockDevice(String mac);
  Future<bool> unblockDevice(String mac);
  Future<bool> setDeviceSpeedLimit(String mac, int kbps);

  Future<RouterWifiSettings> getWifiSettings();
  Future<bool> setWifiSettings(RouterWifiSettings settings);

  Future<GuestNetwork> getGuestNetwork();
  Future<bool> setGuestNetwork(GuestNetwork network);

  Future<List<PortForwardRule>> getPortForwardRules();
  Future<bool> addPortForwardRule(PortForwardRule rule);
  Future<bool> removePortForwardRule(String id);

  Future<List<MacFilterEntry>> getMacFilter();
  Future<bool> setMacFilter(List<MacFilterEntry> entries);

  Future<bool> reboot();
  Future<bool> factoryReset();
}
