import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/router.dart';
import '../../../core/domain/repositories/router_repository.dart';
import '../data/router_repository_impl.dart';

/// مرحلة اتصال الراوتر.
enum RouterConnectionPhase { disconnected, connecting, autoDetecting, connected, error }

/// حالة اتصال الراوتر.
class RouterState {
  const RouterState({
    this.phase = RouterConnectionPhase.disconnected,
    this.info,
    this.detectedBrand,
    this.error,
  });

  final RouterConnectionPhase phase;
  final RouterInfo? info;
  final RouterBrand? detectedBrand;
  final String? error;

  bool get isConnected => phase == RouterConnectionPhase.connected;

  RouterState copyWith({
    RouterConnectionPhase? phase,
    RouterInfo? info,
    RouterBrand? detectedBrand,
    String? error,
  }) =>
      RouterState(
        phase: phase ?? this.phase,
        info: info ?? this.info,
        detectedBrand: detectedBrand ?? this.detectedBrand,
        error: error,
      );
}

class RouterNotifier extends StateNotifier<RouterState> {
  RouterNotifier(this._repo) : super(const RouterState()) {
    _loadActive();
  }

  final RouterRepository _repo;

  Future<void> _loadActive() async {
    final result = await _repo.getActiveRouter();
    result.when(
      onSuccess: (info) {
        if (info != null) {
          state = state.copyWith(phase: RouterConnectionPhase.disconnected, info: info);
        }
      },
      onFailure: (_) {},
    );
  }

  Future<void> autoDetect(String ip) async {
    state = state.copyWith(phase: RouterConnectionPhase.autoDetecting, error: null);
    final result = await _repo.autoDetect(ip);
    result.when(
      onSuccess: (brand) =>
          state = state.copyWith(phase: RouterConnectionPhase.disconnected, detectedBrand: brand),
      onFailure: (failure) => state = state.copyWith(
        phase: RouterConnectionPhase.error,
        error: failure.message,
      ),
    );
  }

  Future<bool> connect({
    required String ip,
    required String username,
    required String password,
    RouterBrand? brand,
  }) async {
    state = state.copyWith(phase: RouterConnectionPhase.connecting, error: null);
    final result = await _repo.connect(
      ip: ip,
      username: username,
      password: password,
      brand: brand,
    );

    return result.when(
      onSuccess: (info) {
        state = RouterState(
          phase: RouterConnectionPhase.connected,
          info: info,
          detectedBrand: info.brand,
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(
          phase: RouterConnectionPhase.error,
          error: failure.message,
        );
        return false;
      },
    );
  }

  Future<void> reboot() => _repo.reboot();

  void disconnect() => state = const RouterState();
}

final routerProvider = StateNotifierProvider<RouterNotifier, RouterState>(
  (ref) => RouterNotifier(ref.watch(routerRepositoryProvider)),
);

/// إحصائيات الراوتر الحيّة (تُجلب عند الطلب).
final routerStatsProvider = FutureProvider<RouterTrafficStats?>((ref) async {
  if (!ref.watch(routerProvider).isConnected) return null;
  final result =
      await ref.watch(routerRepositoryProvider).getTrafficStats();
  return result.dataOrNull;
});

/// العملاء المتصلون بالراوتر.
final routerClientsProvider = FutureProvider<List<RouterClient>>((ref) async {
  if (!ref.watch(routerProvider).isConnected) return const [];
  final result =
      await ref.watch(routerRepositoryProvider).getConnectedClients();
  return result.dataOrNull ?? const [];
});

/// إعدادات واي فاي الراوتر.
final routerWifiSettingsProvider =
    FutureProvider<RouterWifiSettings?>((ref) async {
  if (!ref.watch(routerProvider).isConnected) return null;
  final result =
      await ref.watch(routerRepositoryProvider).getWifiSettings();
  return result.dataOrNull;
});
