import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/device.dart';
import '../../../core/domain/entities/network_info.dart';
import '../../../core/domain/repositories/network_scanner_repository.dart';
import '../../../core/domain/repositories/device_repository.dart';
import '../../devices/data/device_repository_impl.dart';
import '../data/network_scanner_repository_impl.dart';
import '../data/service_discovery.dart';
import '../data/device_fingerprinter.dart';

/// مرحلة فحص الشبكة.
enum ScanPhase { idle, scanning, enriching, done, error }

/// حالة فحص الشبكة للواجهة.
class ScanState {
  const ScanState({
    this.phase = ScanPhase.idle,
    this.scanned = 0,
    this.total = 0,
    this.devices = const [],
    this.networkInfo,
    this.errorMessage,
  });

  final ScanPhase phase;
  final int scanned;
  final int total;
  final List<Device> devices;
  final NetworkInfoData? networkInfo;
  final String? errorMessage;

  double get progress => total == 0 ? 0 : scanned / total;
  bool get isScanning =>
      phase == ScanPhase.scanning || phase == ScanPhase.enriching;

  ScanState copyWith({
    ScanPhase? phase,
    int? scanned,
    int? total,
    List<Device>? devices,
    NetworkInfoData? networkInfo,
    String? errorMessage,
  }) =>
      ScanState(
        phase: phase ?? this.phase,
        scanned: scanned ?? this.scanned,
        total: total ?? this.total,
        devices: devices ?? this.devices,
        networkInfo: networkInfo ?? this.networkInfo,
        errorMessage: errorMessage,
      );
}

/// يدير دورة فحص الشبكة الكاملة:
///  1) قراءة معلومات الشبكة.
///  2) فحص ping + جمع الأجهزة مع تحديث لحظي.
///  3) إثراء بالخدمات (mDNS/UPnP) والبصمة.
///  4) حفظ النتائج في قاعدة البيانات.
class NetworkScanNotifier extends StateNotifier<ScanState> {
  NetworkScanNotifier(this._scanner, this._deviceRepo, this._discovery)
      : super(const ScanState());

  final NetworkScannerRepository _scanner;
  final DeviceRepository _deviceRepo;
  final ServiceDiscovery _discovery;

  Future<void> startScan() async {
    state = const ScanState(phase: ScanPhase.scanning);

    // معلومات الشبكة أولاً (للعرض في الواجهة).
    final infoResult = await _scanner.getLocalNetworkInfo();
    infoResult.when(
      onSuccess: (info) =>
          state = state.copyWith(networkInfo: info, total: 256),
      onFailure: (_) {},
    );

    final scanResult = await _scanner.scanNetwork(
      onProgress: (progress, found) {
        state = state.copyWith(
          phase: ScanPhase.scanning,
          scanned: progress.scanned,
          total: progress.total,
          devices: found,
        );
      },
    );

    final devices = await scanResult.when(
      onSuccess: (found) async {
        // إثراء: اكتشاف الخدمات والبصمة.
        state = state.copyWith(phase: ScanPhase.enriching);
        final services = await _discovery.discoverAll();
        final enriched = <Device>[];
        for (final device in found) {
          final type = DeviceFingerprinter.inferType(
            vendor: device.vendor,
            hostname: device.hostname,
            services: services
                .where((s) => s.ip == device.ip || s.host == device.hostname)
                .toList(),
          );
          enriched.add(device.copyWith(type: type));
        }
        return enriched;
      },
      onFailure: (failure) {
        state = state.copyWith(
          phase: ScanPhase.error,
          errorMessage: failure.message,
        );
        return <Device>[];
      },
    );

    if (devices.isEmpty && state.phase == ScanPhase.error) return;

    // احفظ الأجهزة في قاعدة البيانات (upsert حسب MAC).
    for (final device in devices) {
      await _deviceRepo.upsertDevice(device);
    }

    state = state.copyWith(phase: ScanPhase.done, devices: devices);
  }

  void reset() => state = const ScanState();
}

final networkScanProvider =
    StateNotifierProvider<NetworkScanNotifier, ScanState>(
  (ref) => NetworkScanNotifier(
    ref.watch(networkScannerRepositoryProvider),
    ref.watch(deviceRepositoryProvider),
    ref.watch(serviceDiscoveryProvider),
  ),
);
