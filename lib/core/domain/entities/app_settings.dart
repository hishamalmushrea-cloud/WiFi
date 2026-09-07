import 'package:flutter/material.dart' show ThemeMode;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

/// إعدادات التطبيق المحفوظة (تقود مزود الإعدادات).
@freezed
class AppSettings with _$AppSettings {
  const AppSettings._();

  const factory AppSettings({
    @Default(ThemeMode.dark) ThemeMode themeMode,
    @Default('ar') String localeCode,
    @Default(false) bool onboardingComplete,
    @Default(false) bool appLockEnabled,
    @Default(false) bool backgroundMonitoring,
    @Default(true) bool newDeviceAlerts,
    String? wigleApiToken,
    // حالة الجذر تُخزَّن كقيمة بسيطة حتى لا تعتمد طبقة المجال
    // على طبقة المنصة (Method Channel)؛ الاشتقاق الكامل في root_status.
    @Default(false) bool isRooted,
    @Default('1.0.0') String appVersion,
  }) = _AppSettings;

  bool get isWigleConfigured =>
      wigleApiToken != null && wigleApiToken!.trim().isNotEmpty;
}

/// معلومات إصدار التطبيق (من package_info).
@freezed
class AppInfo with _$AppInfo {
  const factory AppInfo({
    required String appName,
    required String version,
    required String buildNumber,
    required String packageName,
  }) = _AppInfo;
}
