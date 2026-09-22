import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/data/mappers/device_mapper.dart';
import '../../../core/domain/entities/device.dart';
import '../../../core/domain/repositories/device_repository.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/app_logger.dart';

/// تنفيذ مستودع الأجهزة فوق Drift.
///
/// يحول استثناءات قاعدة البيانات إلى نتائج فشل آمنة، ويحوّل
/// الصفوف المخزّنة إلى كيانات المجال عبر [DeviceMapper].
class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Stream<List<Device>> watchDevices() =>
      _db.deviceDao.watchAll().map((rows) => rows.map(DeviceMapper.toEntity).toList());

  @override
  Stream<List<DeviceHistoryEntry>> watchHistory(int deviceId) => _db
      .deviceDao
      .watchHistory(deviceId)
      .map((rows) => rows.map(DeviceMapper.toHistoryEntity).toList());

  @override
  Future<Result<List<Device>>> getDevices() async {
    return guard(() async {
      final rows = await _db.deviceDao.getAll();
      return rows.map(DeviceMapper.toEntity).toList();
    });
  }

  @override
  Future<Result<Device?>> getDeviceById(int id) async {
    return guard(() async {
      final row = await _db.deviceDao.getById(id);
      return row == null ? null : DeviceMapper.toEntity(row);
    });
  }

  @override
  Future<Result<int>> upsertDevice(Device device) async {
    return guard(() async {
      return _db.deviceDao.upsertByMac(DeviceMapper.toCompanion(device));
    });
  }

  @override
  Future<Result<void>> addHistoryEntry(DeviceHistoryEntry entry) async {
    return guard(() => _db.deviceDao.addHistory(
          DeviceHistoryCompanion(
            deviceId: Value(entry.deviceId),
            isOnline: Value(entry.isOnline),
            rssi: Value(entry.rssi),
            connectionType: Value(entry.connectionType?.name),
            throughput: Value(entry.throughputKbps),
            ipAddress: Value(entry.ipAddress),
            timestamp: Value(entry.timestamp),
          ),
        ));
  }

  @override
  Future<Result<void>> setBlocked(int id, bool blocked) =>
      guard(() => _db.deviceDao.setBlocked(id, blocked));

  @override
  Future<Result<void>> setFavorite(int id, bool favorite) =>
      guard(() => _db.deviceDao.setFavorite(id, favorite));

  @override
  Future<Result<void>> rename(int id, String name) =>
      guard(() => _db.deviceDao.rename(id, name));

  @override
  Future<Result<void>> deleteDevice(int id) =>
      guard(() => _db.deviceDao.deleteDevice(id));
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final repo = DeviceRepositoryImpl(ref.watch(appDatabaseProvider));
  ref.onDispose(() => AppLogger.debug('تحرير DeviceRepository'));
  return repo;
});
