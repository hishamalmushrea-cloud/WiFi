import '../../errors/result.dart';
import '../entities/router.dart';
import '../repositories/router_repository.dart';

/// اكتشاف نوع الراوتر تلقائياً.
class AutoDetectRouterUseCase {
  AutoDetectRouterUseCase(this._repo);
  final RouterRepository _repo;
  Future<Result<RouterBrand>> call(String ip) => _repo.autoDetect(ip);
}

/// تسجيل الدخول للراوتر.
class ConnectRouterUseCase {
  ConnectRouterUseCase(this._repo);
  final RouterRepository _repo;
  Future<Result<RouterInfo>> call({
    required String ip,
    required String username,
    required String password,
    RouterBrand? brand,
  }) =>
      _repo.connect(ip: ip, username: username, password: password, brand: brand);
}

class GetRouterStatsUseCase {
  GetRouterStatsUseCase(this._repo);
  final RouterRepository _repo;
  Future<Result<RouterTrafficStats>> call() => _repo.getTrafficStats();
}

class GetRouterClientsUseCase {
  GetRouterClientsUseCase(this._repo);
  final RouterRepository _repo;
  Future<Result<List<RouterClient>>> call() => _repo.getConnectedClients();
}

class BlockRouterClientUseCase {
  BlockRouterClientUseCase(this._repo);
  final RouterRepository _repo;
  Future<Result<void>> call(String mac, bool block) =>
      block ? _repo.blockDevice(mac) : _repo.unblockDevice(mac);
}

class LimitClientSpeedUseCase {
  LimitClientSpeedUseCase(this._repo);
  final RouterRepository _repo;
  Future<Result<void>> call(String mac, int kbps) =>
      _repo.setDeviceSpeedLimit(mac, kbps);
}

class GetWifiSettingsUseCase {
  GetWifiSettingsUseCase(this._repo);
  final RouterRepository _repo;
  Future<Result<RouterWifiSettings>> call() => _repo.getWifiSettings();
}

class SetWifiSettingsUseCase {
  SetWifiSettingsUseCase(this._repo);
  final RouterRepository _repo;
  Future<Result<void>> call(RouterWifiSettings settings) =>
      _repo.setWifiSettings(settings);
}

class RebootRouterUseCase {
  RebootRouterUseCase(this._repo);
  final RouterRepository _repo;
  Future<Result<void>> call() => _repo.reboot();
}

/// استعادة المصنع — يجب أن يسبقها تأكيد صريح من الواجهة.
class FactoryResetRouterUseCase {
  FactoryResetRouterUseCase(this._repo);
  final RouterRepository _repo;
  Future<Result<void>> call() => _repo.factoryReset();
}
