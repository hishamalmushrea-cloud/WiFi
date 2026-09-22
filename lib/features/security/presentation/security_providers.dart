import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/device.dart';
import '../../../core/domain/entities/security.dart';
import '../../../core/domain/repositories/security_repository.dart';
import '../../devices/presentation/device_providers.dart';
import '../../wifi_analysis/presentation/wifi_analysis_providers.dart';
import '../data/security_repository_impl.dart';
import '../data/threat_detector.dart';

/// حالة لوحة الأمان.
class SecurityDashboardState {
  const SecurityDashboardState({
    this.loading = true,
    this.score,
    this.detectedThreats = const [],
    this.error,
  });

  final bool loading;
  final SecurityScore? score;
  final List<SecurityAlert> detectedThreats;
  final String? error;

  SecurityDashboardState copyWith({
    bool? loading,
    SecurityScore? score,
    List<SecurityAlert>? detectedThreats,
    String? error,
  }) =>
      SecurityDashboardState(
        loading: loading ?? this.loading,
        score: score ?? this.score,
        detectedThreats: detectedThreats ?? this.detectedThreats,
        error: error,
      );
}

/// ينسّق تقييم الأمان: يجمع الأجهزة ونقاط الوصول، يشغّل كاشف
/// التهديدات المحلي، ثم يطلب التقييم الموزون من المستودع.
class SecurityDashboardNotifier
    extends StateNotifier<SecurityDashboardState> {
  SecurityDashboardNotifier(this._repo, this._ref)
      : super(const SecurityDashboardState());

  final SecurityRepository _repo;
  final Ref _ref;

  Future<void> evaluate() async {
    state = state.copyWith(loading: true, error: null);

    final devices =
        _ref.read(devicesStreamProvider).valueOrNull ?? <Device>[];
    final accessPoints =
        _ref.read(liveAccessPointsProvider).valueOrNull ??
            _ref.read(wifiAnalysisProvider).accessPoints;

    // 1) كشف التهديدات المحلي (لا يحتاج اتصالاً).
    final threats = ThreatDetector.analyze(
      accessPoints: accessPoints,
      devices: devices,
    );

    // سجّل التهديدات الجديدة في قاعدة البيانات (للتنبيهات والتاريخ).
    for (final threat in threats) {
      await _repo.recordAlert(threat);
    }

    // 2) التقييم الموزون للدرجة.
    final result = await _repo.evaluateSecurity(
      devices: devices,
      accessPoints: accessPoints,
    );

    result.when(
      onSuccess: (score) => state = state.copyWith(
        loading: false,
        score: score,
        detectedThreats: threats,
      ),
      onFailure: (failure) => state = state.copyWith(
        loading: false,
        error: failure.message,
        detectedThreats: threats,
      ),
    );
  }

  Future<void> resolveAlert(int id) =>
      _repo.resolveAlert(id).then((_) => evaluate());

  Future<void> resolveAll() =>
      _repo.resolveAllAlerts().then((_) => evaluate());
}

final securityDashboardProvider = StateNotifierProvider<
    SecurityDashboardNotifier, SecurityDashboardState>(
  (ref) => SecurityDashboardNotifier(
    ref.watch(securityRepositoryProvider),
    ref,
  ),
);

/// كل التنبيهات المخزّنة (بثّ مباشر).
final securityAlertsProvider = StreamProvider<List<SecurityAlert>>((ref) {
  return ref.watch(securityRepositoryProvider).watchAlerts();
});

/// تنبيهات نشطة (غير معالَجة) فقط.
final activeAlertsProvider = Provider<AsyncValue<List<SecurityAlert>>>((ref) {
  return ref
      .watch(securityAlertsProvider)
      .whenData((alerts) => alerts.where((a) => !a.isResolved).toList());
});
