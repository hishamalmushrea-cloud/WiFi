import '../../errors/result.dart';
import '../entities/access_point.dart';
import '../entities/device.dart';
import '../entities/security.dart';
import '../entities/vulnerability.dart';
import '../repositories/security_repository.dart';

/// تقييم أمان الشبكة وإنتاج مؤشر 0–100.
class EvaluateSecurityUseCase {
  EvaluateSecurityUseCase(this._repo);
  final SecurityRepository _repo;

  Future<Result<SecurityScore>> call({
    required List<Device> devices,
    required List<AccessPoint> accessPoints,
  }) =>
      _repo.evaluateSecurity(devices: devices, accessPoints: accessPoints);
}

/// مراقبة التنبيهات الأمنية (بث حيّ).
class WatchSecurityAlertsUseCase {
  WatchSecurityAlertsUseCase(this._repo);
  final SecurityRepository _repo;
  Stream<List<SecurityAlert>> call() => _repo.watchAlerts();
}

class ResolveAlertUseCase {
  ResolveAlertUseCase(this._repo);
  final SecurityRepository _repo;
  Future<Result<void>> call(int id) => _repo.resolveAlert(id);
}

class ResolveAllAlertsUseCase {
  ResolveAllAlertsUseCase(this._repo);
  final SecurityRepository _repo;
  Future<Result<void>> call() => _repo.resolveAllAlerts();
}

/// فحص ثغرات جهاز معيّن.
class ScanVulnerabilitiesUseCase {
  ScanVulnerabilitiesUseCase(this._repo);
  final SecurityRepository _repo;
  Future<Result<List<Vulnerability>>> call(int deviceId) =>
      _repo.scanVulnerabilities(deviceId);
}

/// هل صلاحيات الجذر متاحة (للميزات الـ 30)؟
class CheckRootAccessUseCase {
  CheckRootAccessUseCase(this._repo);
  final SecurityRepository _repo;
  Future<Result<bool>> call() => _repo.hasRootAccess();
}
