import 'package:flutter/material.dart' show ThemeMode;

import '../../errors/result.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class WatchSettingsUseCase {
  WatchSettingsUseCase(this._repo);
  final SettingsRepository _repo;
  Stream<AppSettings> call() => _repo.watchSettings();
}

class GetSettingsUseCase {
  GetSettingsUseCase(this._repo);
  final SettingsRepository _repo;
  Future<Result<AppSettings>> call() => _repo.getSettings();
}

class SetThemeModeUseCase {
  SetThemeModeUseCase(this._repo);
  final SettingsRepository _repo;
  Future<Result<void>> call(ThemeMode mode) => _repo.setThemeMode(mode);
}

class SetLocaleUseCase {
  SetLocaleUseCase(this._repo);
  final SettingsRepository _repo;
  Future<Result<void>> call(String code) => _repo.setLocale(code);
}

class SetAppLockUseCase {
  SetAppLockUseCase(this._repo);
  final SettingsRepository _repo;
  Future<Result<void>> call(bool enabled) => _repo.setAppLock(enabled);
}

class SetBackgroundMonitoringUseCase {
  SetBackgroundMonitoringUseCase(this._repo);
  final SettingsRepository _repo;
  Future<Result<void>> call(bool enabled) =>
      _repo.setBackgroundMonitoring(enabled);
}

class SetNewDeviceAlertsUseCase {
  SetNewDeviceAlertsUseCase(this._repo);
  final SettingsRepository _repo;
  Future<Result<void>> call(bool enabled) =>
      _repo.setNewDeviceAlerts(enabled);
}

class CompleteOnboardingUseCase {
  CompleteOnboardingUseCase(this._repo);
  final SettingsRepository _repo;
  Future<Result<void>> call() => _repo.setOnboardingComplete(true);
}

class GetAppInfoUseCase {
  GetAppInfoUseCase(this._repo);
  final SettingsRepository _repo;
  Future<Result<AppInfo>> call() => _repo.getAppInfo();
}
