import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/app_logger.dart';

/// نقطة دخول التطبيق.
///
/// نلتقط كل أخطاء Flutter وأخطاء المنطقة (Zone) هنا حتى لا
/// تنهار التجربة بصمت؛ يُسجَّل الخطأ باللوجر ويستمر التطبيق.
Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // شريط الحالة شفاف ليندمج مع خلفية التطبيق الداكنة.
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0A0E1A),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      FlutterError.onError = (FlutterErrorDetails details) {
        AppLogger.error(
          'خطأ في طبقة الواجهة: ${details.exception}',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        AppLogger.error(
          'خطأ غير ممسوك على مستوى المنصة',
          error: error,
          stackTrace: stack,
        );
        return true;
      };

      runApp(const ProviderScope(child: NetControlApp()));
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
