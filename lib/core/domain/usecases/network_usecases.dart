import '../../errors/result.dart';
import '../entities/device.dart';
import '../entities/network_info.dart';
import '../entities/network_tools.dart';
import '../entities/vulnerability.dart';
import '../repositories/network_scanner_repository.dart';

/// فحص الشبكة المحلية بالكامل مع بثّ التقدّم.
class ScanNetworkUseCase {
  ScanNetworkUseCase(this._repo);
  final NetworkScannerRepository _repo;

  Future<Result<List<Device>>> call({
    void Function(ScanProgress, List<Device>)? onProgress,
  }) =>
      _repo.scanNetwork(onProgress: onProgress);
}

/// قراءة معلومات الشبكة المحلية الحالية.
class GetNetworkInfoUseCase {
  GetNetworkInfoUseCase(this._repo);
  final NetworkScannerRepository _repo;

  Future<Result<NetworkInfoData>> call() => _repo.getLocalNetworkInfo();
}

/// فحص منافذ جهاز هدف.
class ScanPortsUseCase {
  ScanPortsUseCase(this._repo);
  final NetworkScannerRepository _repo;

  Future<Result<List<PortScanResult>>> call(
    String ip,
    List<int> ports, {
    void Function(int, int)? onProgress,
  }) =>
      _repo.scanPorts(ip, ports: ports, onProgress: onProgress);
}

/// قياس زمن الاستجابة (Ping).
class PingUseCase {
  PingUseCase(this._repo);
  final NetworkScannerRepository _repo;

  Future<Result<PingResult>> call(String host, {int count = 10}) =>
      _repo.ping(host, count: count);
}

/// تتبع مسار الحزم.
class TracerouteUseCase {
  TracerouteUseCase(this._repo);
  final NetworkScannerRepository _repo;

  Future<Result<List<TracerouteHop>>> call(String host) =>
      _repo.traceroute(host);
}
