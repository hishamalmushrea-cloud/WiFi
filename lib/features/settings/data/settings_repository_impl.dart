import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/data/datasources/local/settings_local_datasource.dart';
import '../../../core/domain/entities/app_settings.dart';
import '../../../core/domain/repositories/settings_repository.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/app_logger.dart';

/// تنفيذ مستودع الإعدادات فوق SharedPreferences.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._source);
  final SettingsLocalDataSource _source;

  @override
  Stream<AppSettings> watchSettings() => _source.watch();

  @override
  Future<Result<AppSettings>> getSettings() async =>
      guard(() async => _source.read());

  @override
  Future<Result<void>> setThemeMode(ThemeMode mode) =>
      guard(() => _source.setThemeMode(mode));

  @override
  Future<Result<void>> setLocale(String code) =>
      guard(() => _source.setLocale(code));

  @override
  Future<Result<void>> setOnboardingComplete(bool value) =>
      guard(() => _source.setOnboardingComplete(value));

  @override
  Future<Result<void>> setAppLock(bool enabled) =>
      guard(() => _source.setAppLock(enabled));

  @override
  Future<Result<void>> setBackgroundMonitoring(bool enabled) =>
      guard(() => _source.setBackgroundMonitoring(enabled));

  @override
  Future<Result<void>> setNewDeviceAlerts(bool enabled) =>
      guard(() => _source.setNewDeviceAlerts(enabled));

  @override
  Future<Result<void>> setWigleToken(String? token) =>
      guard(() => _source.setWigleToken(token));

  @override
  Future<Result<AppInfo>> getAppInfo() async {
    return guard(() async {
      final info = await PackageInfo.fromPlatform();
      return AppInfo(
        appName: info.appName,
        version: info.version,
        buildNumber: info.buildNumber,
        packageName: info.packageName,
      );
    });
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final repo = SettingsRepositoryImpl(ref.watch(settingsLocalDataSourceProvider));
  ref.onDispose(() => AppLogger.debug('تحرير SettingsRepository'));
  return repo;
});
