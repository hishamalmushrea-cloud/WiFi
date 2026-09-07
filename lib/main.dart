import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/data/datasources/local/settings_local_datasource.dart';
import 'core/utils/app_logger.dart';

/// نقطة دخول التطبيق.
///
/// نهيّئ الخدمات التي تحتاج تهيئة غير متزامنة (SharedPreferences)
/// قبل بناء الواجهة، ونمرّرها عبر ProviderScope.override حتى لا
/// تضطر أي طبقة لانتظارها وقت التشغيل.
Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0A0E1A),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      final prefs = await SharedPreferences.getInstance();

      FlutterError.onError = (FlutterErrorDetails details) {
        AppLogger.error(
          'خطأ في طبقة الواجهة: ${details.exception}',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        AppLogger.error('خطأ غير ممسوك على مستوى المنصة',
            error: error, stackTrace: stack);
        return true;
      };

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const NetControlApp(),
        ),
      );
    },
    (error, stackTrace) {
      AppLogger.error(
        'خطأ غير متوقع في منطقة التطبيق',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
