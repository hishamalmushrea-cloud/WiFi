import 'package:flutter/material.dart' show ThemeMode;

import '../../errors/result.dart';
import '../entities/app_settings.dart';

/// عقد إعدادات التطبيق والتفضيلات.
abstract class SettingsRepository {
  Stream<AppSettings> watchSettings();

  Future<Result<AppSettings>> getSettings();

  Future<Result<void>> setThemeMode(ThemeMode mode);

  Future<Result<void>> setLocale(String code);

  Future<Result<void>> setOnboardingComplete(bool value);

  Future<Result<void>> setAppLock(bool enabled);

  Future<Result<void>> setBackgroundMonitoring(bool enabled);

  Future<Result<void>> setNewDeviceAlerts(bool enabled);

  Future<Result<void>> setWigleToken(String? token);

  Future<Result<AppInfo>> getAppInfo();
}
