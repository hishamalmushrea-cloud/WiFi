import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/vulnerability.dart';
import '../../../core/domain/repositories/network_scanner_repository.dart';
import '../data/network_scanner_repository_impl.dart';

/// حالة فحص المنافذ.
class PortScanState {
  const PortScanState({
    this.scanning = false,
    this.done = 0,
    this.total = 0,
    this.results = const [],
    this.target,
  });

  final bool scanning;
  final int done;
  final int total;
  final List<PortScanResult> results;
  final String? target;

  double get progress => total == 0 ? 0 : done / total;
  List<PortScanResult> get openPorts =>
      results.where((r) => r.state == PortState.open).toList();

  PortScanState copyWith({
    bool? scanning,
    int? done,
    int? total,
    List<PortScanResult>? results,
    String? target,
  }) =>
      PortScanState(
        scanning: scanning ?? this.scanning,
        done: done ?? this.done,
        total: total ?? this.total,
        results: results ?? this.results,
        target: target ?? this.target,
      );
}

class PortScanNotifier extends StateNotifier<PortScanState> {
  PortScanNotifier(this._scanner) : super(const PortScanState());

  final NetworkScannerRepository _scanner;

  Future<void> scan(String ip, List<int> ports) async {
    state = PortScanState(scanning: true, total: ports.length, target: ip);

    final result = await _scanner.scanPorts(
      ip,
      ports: ports,
      onProgress: (done, total) {
        state = state.copyWith(done: done, total: total);
      },
    );

    result.when(
      onSuccess: (openPorts) =>
          state = state.copyWith(scanning: false, results: openPorts),
      onFailure: (_) => state = state.copyWith(scanning: false),
    );
  }

  void reset() => state = const PortScanState();
}

final portScanProvider =
    StateNotifierProvider<PortScanNotifier, PortScanState>(
  (ref) => PortScanNotifier(ref.watch(networkScannerRepositoryProvider)),
);
