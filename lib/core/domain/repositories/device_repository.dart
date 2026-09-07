import '../../errors/result.dart';
import '../entities/device.dart';

/// عقد وصول بيانات الأجهزة.
///
/// طبقة المجال تعرّف العقد فقط؛ التنفيذ الفعلي (Drift + الماسح)
/// يأتي في PHASE 5 و يُحقن عبر Riverpod.
abstract class DeviceRepository {
  /// بثّ حيّ لكل الأجهزة (يتحديث تلقائي عند الفحص والتعديل).
  Stream<List<Device>> watchDevices();

  Future<Result<List<Device>>> getDevices();

  Future<Result<Device?>> getDeviceById(int id);

  Future<Result<int>> upsertDevice(Device device);

  Future<Result<void>> setBlocked(int id, bool blocked);

  Future<Result<void>> setFavorite(int id, bool favorite);

  Future<Result<void>> rename(int id, String name);

  Future<Result<void>> deleteDevice(int id);

  Future<Result<void>> addHistoryEntry(DeviceHistoryEntry entry);

  Stream<List<DeviceHistoryEntry>> watchHistory(int deviceId);
}
