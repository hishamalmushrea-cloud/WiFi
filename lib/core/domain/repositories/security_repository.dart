import '../../errors/result.dart';
import '../entities/access_point.dart';
import '../entities/device.dart';
import '../entities/security.dart';
import '../entities/vulnerability.dart';

/// عقد محرك الأمان وكشف التهديدات.
abstract class SecurityRepository {
  /// تقييم أمان شامل يعطي درجة (0–100) وبنود الفحص.
  Future<Result<SecurityScore>> evaluateSecurity({
    required List<Device> devices,
    required List<AccessPoint> accessPoints,
  });

  /// كشف التهديدات الحية (ARP spoofing، evil twin، دخيل…).
  Stream<List<SecurityAlert>> watchAlerts();

  Future<Result<void>> recordAlert(SecurityAlert alert);

  Future<Result<void>> resolveAlert(int id);

  Future<Result<void>> resolveAllAlerts();

  /// فحص ثغرات جهاز (منافذ مفتوحة + قاعدة بسيطة للخدمات المكشوفة).
  Future<Result<List<Vulnerability>>> scanVulnerabilities(int deviceId);

  /// هل توفّرت صلاحيات الجذر للميزات المتقدمة؟
  Future<Result<bool>> hasRootAccess();
}
