import 'package:drift/drift.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/datasources/remote/dio_client.dart';
import '../../../core/database/app_database.dart';
import '../../../core/data/mappers/router_mapper.dart';
import '../../../core/domain/entities/router.dart';
import '../../../core/domain/repositories/router_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/result.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/crypto_utils.dart';
import 'controllers/router_controller.dart';
import 'controllers/router_factory.dart';

/// تنفيذ مستودع التحكم بالراوتر.
///
/// ينسّق بين:
///  - [RouterFactory] لاكتشاف الماركة وإنشاء المتحكم.
///  - قاعدة البيانات لحفظ معلومات الراوتر.
///  - الخزن الآمن لحفظ كلمة المرور مشفّرة (AES) لا نصاً صريحاً.
///
/// عبارة المرور المستخدمة لتشفير سر الراوتر تُشتق من معرّف ثابت
/// للتطبيق في الخزن الآمن، فلا يلزم المستخدم كلمة مرور إضافية.
class RouterRepositoryImpl implements RouterRepository {
  RouterRepositoryImpl(this._db, this._secure, this._dio);

  final AppDatabase _db;
  final SecureStorageService _secure;
  final Dio _dio;

  late final RouterFactory _factory = RouterFactory(_dio);
  RouterController? _activeController;

  @override
  Future<Result<RouterBrand>> autoDetect(String ip) =>
      guard(() => _factory.autoDetect(ip));

  @override
  Future<Result<RouterInfo>> connect({
    required String ip,
    required String username,
    required String password,
    RouterBrand? brand,
  }) async {
    return guard(() async {
      final resolvedBrand = brand ?? await _factory.autoDetect(ip);
      final controller = _factory.createController(resolvedBrand);
      final ok = await controller.login(
        ip: ip,
        username: username,
        password: password,
      );
      if (!ok) throw const RouterAuthException();

      _activeController = controller;
      final info = await controller.getInfo();

      // احفظ معلومات الراوتر (بدون كلمة المرور في الجدول).
      final id = await _db.routerSettingsDao.insert(
        RouterSettingsCompanion(
          routerType: Value(resolvedBrand.name),
          ip: Value(ip),
          username: Value(username),
          model: Value(info.model),
          firmware: Value(info.firmware),
          macAddress: Value(info.macAddress),
          lastConnected: Value(DateTime.now()),
          isActive: const Value(true),
        ),
      );
      await _db.routerSettingsDao.setActive(id);

      // خزّن كلمة المرور مشفّرة في الخزن الآمن (مفتاح التطبيق).
      final key = await _secure.getOrCreateDatabaseKey();
      final encrypted = CryptoUtils.encryptText(password, key);
      await _secure.saveRouterSecret(id, encrypted);

      return RouterInfo(
        id: id,
        brand: resolvedBrand,
        ip: ip,
        username: username,
        model: info.model,
        firmware: info.firmware,
        macAddress: info.macAddress,
        lastConnected: DateTime.now(),
        isActive: true,
      );
    });
  }

  @override
  Future<Result<RouterInfo?>> getActiveRouter() async {
    return guard(() async {
      final row = await _db.routerSettingsDao.getActive();
      return row == null ? null : RouterMapper.toEntity(row);
    });
  }

  /// يجلب المتحكم النشط أو يرمي خطأ إن لم يُتصل بعد.
  RouterController _requireController() {
    final c = _activeController;
    if (c == null) {
      throw const NetworkException('لم يتم الاتصال بالراوتر بعد');
    }
    return c;
  }

  @override
  Future<Result<RouterTrafficStats>> getTrafficStats() =>
      guard(() => _requireController().getTrafficStats());

  @override
  Future<Result<List<RouterClient>>> getConnectedClients() =>
      guard(() => _requireController().getConnectedClients());

  @override
  Future<Result<void>> blockDevice(String mac) =>
      guard(() async => _requireController().blockDevice(mac));

  @override
  Future<Result<void>> unblockDevice(String mac) =>
      guard(() async => _requireController().unblockDevice(mac));

  @override
  Future<Result<void>> setDeviceSpeedLimit(String mac, int kbps) =>
      guard(() async => _requireController().setDeviceSpeedLimit(mac, kbps));

  @override
  Future<Result<RouterWifiSettings>> getWifiSettings() =>
      guard(() => _requireController().getWifiSettings());

  @override
  Future<Result<void>> setWifiSettings(RouterWifiSettings settings) =>
      guard(() async => _requireController().setWifiSettings(settings));

  @override
  Future<Result<GuestNetwork>> getGuestNetwork() =>
      guard(() => _requireController().getGuestNetwork());

  @override
  Future<Result<void>> setGuestNetwork(GuestNetwork network) =>
      guard(() async => _requireController().setGuestNetwork(network));

  @override
  Future<Result<List<PortForwardRule>>> getPortForwardRules() =>
      guard(() => _requireController().getPortForwardRules());

  @override
  Future<Result<void>> addPortForwardRule(PortForwardRule rule) =>
      guard(() async => _requireController().addPortForwardRule(rule));

  @override
  Future<Result<void>> removePortForwardRule(String id) =>
      guard(() async => _requireController().removePortForwardRule(id));

  @override
  Future<Result<List<MacFilterEntry>>> getMacFilter() =>
      guard(() => _requireController().getMacFilter());

  @override
  Future<Result<void>> setMacFilter(List<MacFilterEntry> entries) =>
      guard(() async => _requireController().setMacFilter(entries));

  @override
  Future<Result<void>> reboot() async =>
      guard(() async => _requireController().reboot());

  @override
  Future<Result<void>> factoryReset() async {
    // الواجهة تفرض تأكيداً صريحاً قبل الوصول هنا (قاعدة صارمة).
    AppLogger.warning('طلب استعادة مصنع الراوتر — إجراء خطير', tag: 'Router');
    return guard(() async => _requireController().factoryReset());
  }
}

final routerRepositoryProvider = Provider<RouterRepository>((ref) {
  return RouterRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(secureStorageServiceProvider),
    ref.watch(lanDioProvider),
  );
});
