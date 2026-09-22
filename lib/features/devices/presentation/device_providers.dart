import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/device.dart';
import '../../../core/domain/repositories/device_repository.dart';
import '../data/device_repository_impl.dart';

/// بثّ كل الأجهزة من قاعدة البيانات (يتحديث تلقائياً بعد الفحص).
final devicesStreamProvider = StreamProvider<List<Device>>((ref) {
  return ref.watch(deviceRepositoryProvider).watchDevices();
});

/// فلاتر قائمة الأجهزة.
enum DeviceFilter { all, online, offline, favorites, blocked }

/// البحث النصي + الفلتر النشط.
class DeviceQuery {
  const DeviceQuery({this.filter = DeviceFilter.all, this.search = ''});
  final DeviceFilter filter;
  final String search;

  DeviceQuery copyWith({DeviceFilter? filter, String? search}) =>
      DeviceQuery(
        filter: filter ?? this.filter,
        search: search ?? this.search,
      );
}

class DeviceQueryNotifier extends StateNotifier<DeviceQuery> {
  DeviceQueryNotifier() : super(const DeviceQuery());

  void setFilter(DeviceFilter filter) =>
      state = state.copyWith(filter: filter);
  void setSearch(String search) => state = state.copyWith(search: search);
}

final deviceQueryProvider =
    StateNotifierProvider<DeviceQueryNotifier, DeviceQuery>(
  (ref) => DeviceQueryNotifier(),
);

/// قائمة الأجهزة بعد تطبيق الفلتر والبحث.
final filteredDevicesProvider = Provider<AsyncValue<List<Device>>>((ref) {
  final devices = ref.watch(devicesStreamProvider);
  final query = ref.watch(deviceQueryProvider);

  return devices.whenData((list) {
    var result = list;
    switch (query.filter) {
      case DeviceFilter.online:
        result = result.where((d) => d.isOnline).toList();
      case DeviceFilter.offline:
        result = result.where((d) => !d.isOnline).toList();
      case DeviceFilter.favorites:
        result = result.where((d) => d.isFavorite).toList();
      case DeviceFilter.blocked:
        result = result.where((d) => d.isBlocked).toList();
      case DeviceFilter.all:
        break;
    }
    if (query.search.trim().isNotEmpty) {
      final q = query.search.trim().toLowerCase();
      result = result
          .where((d) =>
              d.displayName.toLowerCase().contains(q) ||
              d.ip.contains(q) ||
              d.mac.toLowerCase().contains(q) ||
              (d.vendor ?? '').toLowerCase().contains(q))
          .toList();
    }
    return result;
  });
});

/// إجراءات الجهاز (حظر/مفضلة/تسمية) — تُغلّف المستودع.
class DeviceActions {
  DeviceActions(this._repo);
  final DeviceRepository _repo;

  Future<void> toggleBlocked(Device device) =>
      _repo.setBlocked(device.id, !device.isBlocked).then((_) {});
  Future<void> toggleFavorite(Device device) =>
      _repo.setFavorite(device.id, !device.isFavorite).then((_) {});
  Future<void> rename(Device device, String name) =>
      _repo.rename(device.id, name).then((_) {});
  Future<void> markKnown(Device device) =>
      _repo.upsertDevice(device.copyWith(isKnown: true)).then((_) {});
  Future<void> remove(Device device) =>
      _repo.deleteDevice(device.id).then((_) {});
}

final deviceActionsProvider = Provider<DeviceActions>(
  (ref) => DeviceActions(ref.watch(deviceRepositoryProvider)),
);

/// سجل جهاز واحد (بثّ).
final deviceHistoryProvider =
    StreamProvider.family<List<DeviceHistoryEntry>, int>((ref, deviceId) {
  return ref.watch(deviceRepositoryProvider).watchHistory(deviceId);
});
