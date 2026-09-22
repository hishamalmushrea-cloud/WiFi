import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/app_constants.dart';
import '../../../domain/entities/app_settings.dart';

/// مصدر الإعدادات المحلي عبر SharedPreferences.
///
/// يبثّ التغييرات لحظياً كي تتحديث الواجهة فور تبديل الثيم
/// أو تفعيل قفل التطبيق، بدل إعادة قراءة يدوية في كل شاشة.
class SettingsLocalDataSource {
  SettingsLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  final _controller = StreamController<AppSettings>.broadcast();

  Stream<AppSettings> watch() async* {
    yield read();
    yield* _controller.stream;
  }

  AppSettings read() {
    return AppSettings(
      themeMode: _readThemeMode(),
      localeCode: _prefs.getString(AppConstants.keyLocale) ?? 'ar',
      onboardingComplete:
          _prefs.getBool(AppConstants.keyOnboardingComplete) ?? false,
      appLockEnabled: _prefs.getBool(AppConstants.keyAppLockEnabled) ?? false,
      backgroundMonitoring:
          _prefs.getBool(AppConstants.keyBackgroundMonitoring) ?? false,
      newDeviceAlerts:
          _prefs.getBool(AppConstants.keyNewDeviceAlerts) ?? true,
      wigleApiToken: _prefs.getString(AppConstants.keyWigleApiToken),
      isRooted: _prefs.getBool('security.is_rooted') ?? false,
    );
  }

  ThemeMode _readThemeMode() {
    final raw = _prefs.getString(AppConstants.keyThemeMode);
    return switch (raw) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(
      AppConstants.keyThemeMode,
      mode.name,
    );
    _emit();
  }

  Future<void> setLocale(String code) async {
    await _prefs.setString(AppConstants.keyLocale, code);
    _emit();
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(AppConstants.keyOnboardingComplete, value);
    _emit();
  }

  Future<void> setAppLock(bool enabled) async {
    await _prefs.setBool(AppConstants.keyAppLockEnabled, enabled);
    _emit();
  }

  Future<void> setBackgroundMonitoring(bool enabled) async {
    await _prefs.setBool(AppConstants.keyBackgroundMonitoring, enabled);
    _emit();
  }

  Future<void> setNewDeviceAlerts(bool enabled) async {
    await _prefs.setBool(AppConstants.keyNewDeviceAlerts, enabled);
    _emit();
  }

  Future<void> setWigleToken(String? token) async {
    if (token == null || token.trim().isEmpty) {
      await _prefs.remove(AppConstants.keyWigleApiToken);
    } else {
      await _prefs.setString(AppConstants.keyWigleApiToken, token.trim());
    }
    _emit();
  }

  Future<void> setRooted(bool value) async {
    await _prefs.setBool('security.is_rooted', value);
    _emit();
  }

  void _emit() => _controller.add(read());

  void dispose() => _controller.close();
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'يجب تهيئة SharedPreferences في main وتجاوز المزود بقيمته',
  ),
);

final settingsLocalDataSourceProvider =
    Provider<SettingsLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final source = SettingsLocalDataSource(prefs);
  ref.onDispose(source.dispose);
  return source;
});
