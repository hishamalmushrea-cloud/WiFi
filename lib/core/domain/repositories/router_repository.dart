import '../../errors/result.dart';
import '../entities/router.dart';

/// عقد التحكم بالراوتر.
///
/// كل نوع راوتر (10) ينفّذ هذه الواجهة في PHASE 5 بمنطق HTTP
/// الخاص به، ويُختار عبر RouterFactory.
abstract class RouterRepository {
  /// اكتشاف نوع الراوتر تلقائياً من عنوانه/استجابته.
  Future<Result<RouterBrand>> autoDetect(String ip);

  /// تسجيل الدخول وفتح جلسة.
  Future<Result<RouterInfo>> connect({
    required String ip,
    required String username,
    required String password,
    RouterBrand? brand,
  });

  Future<Result<RouterInfo?>> getActiveRouter();

  Future<Result<RouterTrafficStats>> getTrafficStats();

  Future<Result<List<RouterClient>>> getConnectedClients();

  Future<Result<void>> blockDevice(String mac);

  Future<Result<void>> unblockDevice(String mac);

  Future<Result<void>> setDeviceSpeedLimit(String mac, int kbps);

  Future<Result<RouterWifiSettings>> getWifiSettings();

  Future<Result<void>> setWifiSettings(RouterWifiSettings settings);

  Future<Result<GuestNetwork>> getGuestNetwork();

  Future<Result<void>> setGuestNetwork(GuestNetwork network);

  Future<Result<List<PortForwardRule>>> getPortForwardRules();

  Future<Result<void>> addPortForwardRule(PortForwardRule rule);

  Future<Result<void>> removePortForwardRule(String id);

  Future<Result<List<MacFilterEntry>>> getMacFilter();

  Future<Result<void>> setMacFilter(List<MacFilterEntry> entries);

  Future<Result<void>> reboot();

  /// استعادة المصنع — تتطلب تأكيداً صريحاً قبل استدعائها.
  Future<Result<void>> factoryReset();
}
