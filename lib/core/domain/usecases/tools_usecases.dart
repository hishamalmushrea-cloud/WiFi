import '../../errors/result.dart';
import '../entities/network_tools.dart';
import '../repositories/network_tools_repository.dart';

class PingToolUseCase {
  PingToolUseCase(this._repo);
  final NetworkToolsRepository _repo;
  Future<Result<PingResult>> call(String host, {int count = 10}) =>
      _repo.ping(host, count: count);
}

class TracerouteToolUseCase {
  TracerouteToolUseCase(this._repo);
  final NetworkToolsRepository _repo;
  Future<Result<List<TracerouteHop>>> call(String host, {int maxHops = 30}) =>
      _repo.traceroute(host, maxHops: maxHops);
}

class DnsLookupUseCase {
  DnsLookupUseCase(this._repo);
  final NetworkToolsRepository _repo;
  Future<Result<List<DnsRecord>>> call(String domain, String type) =>
      _repo.dnsLookup(domain, type);
}

class ReverseDnsUseCase {
  ReverseDnsUseCase(this._repo);
  final NetworkToolsRepository _repo;
  Future<Result<List<DnsRecord>>> call(String ip) => _repo.reverseDns(ip);
}

class WhoisUseCase {
  WhoisUseCase(this._repo);
  final NetworkToolsRepository _repo;
  Future<Result<WhoisResult>> call(String query) => _repo.whois(query);
}

class MacVendorUseCase {
  MacVendorUseCase(this._repo);
  final NetworkToolsRepository _repo;
  Future<Result<String>> call(String mac) => _repo.macVendorLookup(mac);
}

class WakeOnLanUseCase {
  WakeOnLanUseCase(this._repo);
  final NetworkToolsRepository _repo;
  Future<Result<void>> call(WakeOnLanTarget target) => _repo.wakeOnLan(target);
}

class SubnetCalculatorUseCase {
  SubnetCalculatorUseCase(this._repo);
  final NetworkToolsRepository _repo;
  Future<Result<SubnetInfo>> call(String ip, int prefix) =>
      _repo.calculateSubnet(ip, prefix);
}

class HttpHeadersUseCase {
  HttpHeadersUseCase(this._repo);
  final NetworkToolsRepository _repo;
  Future<Result<HttpHeaderInfo>> call(String url) =>
      _repo.inspectHttpHeaders(url);
}

class SslInspectUseCase {
  SslInspectUseCase(this._repo);
  final NetworkToolsRepository _repo;
  Future<Result<SslCertificateInfo>> call(String host, {int port = 443}) =>
      _repo.inspectSsl(host, port: port);
}
