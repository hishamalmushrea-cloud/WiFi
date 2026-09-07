import '../../errors/result.dart';
import '../entities/network_tools.dart';

/// عقد أدوات الشبكة (ping, traceroute, DNS, WHOIS, WOL، الشهادات).
abstract class NetworkToolsRepository {
  Future<Result<PingResult>> ping(String host, {int count = 10});

  Future<Result<List<TracerouteHop>>> traceroute(String host, {int maxHops});

  Future<Result<List<DnsRecord>>> dnsLookup(String domain, String recordType);

  Future<Result<List<DnsRecord>>> reverseDns(String ip);

  Future<Result<WhoisResult>> whois(String query);

  Future<Result<String>> macVendorLookup(String mac);

  Future<Result<void>> wakeOnLan(WakeOnLanTarget target);

  Future<Result<SubnetInfo>> calculateSubnet(String ip, int prefixLength);

  Future<Result<HttpHeaderInfo>> inspectHttpHeaders(String url);

  Future<Result<SslCertificateInfo>> inspectSsl(String host, {int port});
}
