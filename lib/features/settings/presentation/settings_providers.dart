import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/app_settings.dart';
import '../../../core/domain/repositories/settings_repository.dart';
import '../../settings/data/settings_repository_impl.dart';

/// حالة الإعدادات الحالية (تُقرأ من التخزين وتتحديث تلقائياً
/// عبر البثّ). كل إجراء يعمل بأفضل جهد: فشل الحفظ لا يُسقط
/// الواجهة لأن البثّ سيعيد المحاولة.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._repo) : super(const AppSettings()) {
    _init();
  }

  final SettingsRepository _repo;
  StreamSubscription<AppSettings>? _sub;

  void _init() {
    _sub = _repo.watchSettings().listen(
      (settings) => state = settings,
      onError: (Object e) {},
    );
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _repo.setThemeMode(mode).then((_) {});
  Future<void> setLocale(String code) =>
      _repo.setLocale(code).then((_) {});
  Future<void> setAppLock(bool enabled) =>
      _repo.setAppLock(enabled).then((_) {});
  Future<void> setBackgroundMonitoring(bool enabled) =>
      _repo.setBackgroundMonitoring(enabled).then((_) {});
  Future<void> setNewDeviceAlerts(bool enabled) =>
      _repo.setNewDeviceAlerts(enabled).then((_) {});
  Future<void> setWigleToken(String? token) =>
      _repo.setWigleToken(token).then((_) {});
  Future<void> completeOnboarding() =>
      _repo.setOnboardingComplete(true).then((_) {});

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref.watch(settingsRepositoryProvider)),
);
