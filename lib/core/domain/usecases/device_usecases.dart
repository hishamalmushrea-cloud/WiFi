import '../../errors/result.dart';
import '../entities/device.dart';
import '../repositories/device_repository.dart';
import 'usecase.dart';

/// مراقبة كل الأجهزة (بث حيّ).
class WatchDevicesUseCase {
  WatchDevicesUseCase(this._repo);
  final DeviceRepository _repo;
  Stream<List<Device>> call() => _repo.watchDevices();
}

class GetDevicesUseCase {
  GetDevicesUseCase(this._repo);
  final DeviceRepository _repo;
  Future<Result<List<Device>>> call() => _repo.getDevices();
}

class GetDeviceUseCase {
  GetDeviceUseCase(this._repo);
  final DeviceRepository _repo;
  Future<Result<Device?>> call(int id) => _repo.getDeviceById(id);
}

class BlockDeviceUseCase {
  BlockDeviceUseCase(this._repo);
  final DeviceRepository _repo;
  Future<Result<void>> call(int id, bool blocked) =>
      _repo.setBlocked(id, blocked);
}

class ToggleFavoriteUseCase {
  ToggleFavoriteUseCase(this._repo);
  final DeviceRepository _repo;
  Future<Result<void>> call(int id, bool favorite) =>
      _repo.setFavorite(id, favorite);
}

class RenameDeviceUseCase {
  RenameDeviceUseCase(this._repo);
  final DeviceRepository _repo;
  Future<Result<void>> call(int id, String name) => _repo.rename(id, name);
}

class DeleteDeviceUseCase {
  DeleteDeviceUseCase(this._repo);
  final DeviceRepository _repo;
  Future<Result<void>> call(int id) => _repo.deleteDevice(id);
}

class WatchDeviceHistoryUseCase {
  WatchDeviceHistoryUseCase(this._repo);
  final DeviceRepository _repo;
  Stream<List<DeviceHistoryEntry>> call(int deviceId) =>
      _repo.watchHistory(deviceId);
}
