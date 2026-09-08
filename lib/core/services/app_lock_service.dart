import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../localization/app_strings.dart';

/// خدمة قفل التطبيق بالمصادقة الحيوية (بصمة/Face ID/رمز الجهاز).
///
/// تغلّف local_auth خلف واجهة آمنة:
///  - أي استثناء من المنصة يُعاد كقيمة منطقية بدل انهيار الواجهة.
///  - نسمح بالرجوع لرمز قفل الجهاز (biometricOnly: false) حتى لا
///    يُحبس المستخدم خارج التطبيق عند فشل البصمة عدة مرات.
///  - stickyAuth لإعادة المحاولة تلقائياً عند انقطاع النشاط أثناء
///    عرض نافذة المصادقة (شائع على Android).
class AppLockService {
  AppLockService([LocalAuthentication? localAuth])
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// هل يستطيع هذا الجهاز تنفيذ المصادقة؟
  ///
  /// يكفي وجود قفل شاشة (رمز/نمط/بصمة)؛ لا نشترط البصمة وحدها
  /// لأن الرجوع لرمز الجهاز مدعوم.
  Future<bool> isAvailable() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// هل توجد بصمة/وجه مسجّلان؟ (للعرض فقط، ليس شرطاً للتفعيل).
  Future<bool> hasBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// يعرض نافذة المصادقة ويعيد true عند النجاح.
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: AppStrings.appLockReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

final appLockServiceProvider = Provider<AppLockService>((_) => AppLockService());
