import '../../errors/result.dart';
import '../entities/wardriving.dart';
import '../repositories/wardriving_repository.dart';

class StartWardrivingUseCase {
  StartWardrivingUseCase(this._repo);
  final WardrivingRepository _repo;
  Stream<List<WardrivingPoint>> call() => _repo.startSession();
}

class StopWardrivingUseCase {
  StopWardrivingUseCase(this._repo);
  final WardrivingRepository _repo;
  Future<Result<void>> call() => _repo.stopSession();
}

class WatchWardrivingPointsUseCase {
  WatchWardrivingPointsUseCase(this._repo);
  final WardrivingRepository _repo;
  Stream<List<WardrivingPoint>> call() => _repo.watchPoints();
}

class WardrivingStatsUseCase {
  WardrivingStatsUseCase(this._repo);
  final WardrivingRepository _repo;
  Future<Result<WardrivingStats>> call() => _repo.getStatistics();
}

class UploadToWigleUseCase {
  UploadToWigleUseCase(this._repo);
  final WardrivingRepository _repo;
  Future<Result<int>> call(String token) => _repo.uploadToWigle(token);
}

class ScanBluetoothUseCase {
  ScanBluetoothUseCase(this._repo);
  final WardrivingRepository _repo;
  Future<Result<List<BluetoothDeviceData>>> call({Duration duration = const Duration(seconds: 8)}) =>
      _repo.scanBluetooth(duration: duration);
}

class ExportWardrivingCsvUseCase {
  ExportWardrivingCsvUseCase(this._repo);
  final WardrivingRepository _repo;
  Future<Result<String>> call() => _repo.exportCsv();
}
