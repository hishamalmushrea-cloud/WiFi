import '../../errors/result.dart';
import '../entities/device.dart';
import '../entities/network_info.dart';
import '../entities/network_tools.dart';
import '../entities/vulnerability.dart';

/// نسبة تقدّم الفحص (مفحوص/إجمالي + الأجهزة المكتشفة حتى الآن).
class ScanProgress {
  const ScanProgress({
    required this.scanned,
    required this.total,
    required this.found,
  });
  final int scanned;
  final int total;
  final int found;
  double get percent => total == 0 ? 0 : scanned / total;
}

/// عقد ماسح الشبكة المحلية.
abstract class NetworkScannerRepository {
  /// معلومات الشبكة المحلية الحالية (IP/بوابة/SSID).
  Future<Result<NetworkInfoData>> getLocalNetworkInfo();

  /// فحص الشبكة بالكامل.
  ///
  /// [onProgress] يُستدعى دورياً بآخر التقدّم والأجهزة المكتشفة
  /// لتبثها الواجهة لحظياً بدل انتظار اكتمال الفحص.
  Future<Result<List<Device>>> scanNetwork({
    void Function(ScanProgress progress, List<Device> found)? onProgress,
  });

  /// فحص منافذ جهاز واحد (متزامن بحدّ مدمج).
  Future<Result<List<PortScanResult>>> scanPorts(
    String ip, {
    required List<int> ports,
    void Function(int done, int total)? onProgress,
  });

  /// قياس Ping لهدف.
  Future<Result<PingResult>> ping(String host, {int count});

  /// تتبع مسار الحزم.
  Future<Result<List<TracerouteHop>>> traceroute(String host);
}
