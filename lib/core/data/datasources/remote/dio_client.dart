import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_logger.dart';

/// عميل Dio مركزي بإعدادات موحّدة ومسجّل طلبات.
///
/// السبب: كل طلبات HTTP الخارجية (مصنّعو MAC، WHOIS، WiGLE،
/// اختبار السرعة) تمر عبر هذا العميل فنضبط المهلات والمتغيّرات
/// والتسجيل في مكان واحد بدل تكرارها.
Dio _buildDio({Duration timeout = const Duration(seconds: 15)}) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      responseType: ResponseType.plain,
      // الكثير من واجهات الراوترات شهاداتها موقّعة ذاتياً؛
      // نعالج الشهادات في طلبات الراوتر عبر validateStatus مخصص.
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.debug(
          '→ ${options.method} ${options.uri}',
          tag: 'Dio',
        );
        handler.next(options);
      },
      onError: (error, handler) {
        AppLogger.warning(
          '← خطأ ${error.response?.statusCode}: ${error.requestOptions.uri}',
          error: error,
        );
        handler.next(error);
      },
    ),
  );

  return dio;
}

/// عميل عام للإنترنت (مهلة معتدلة).
final dioProvider = Provider<Dio>((ref) => _buildDio());

/// عميل للشبكة المحلية/الراوتر (مهلة أطول قليلاً للأجهزة البطيئة).
final lanDioProvider = Provider<Dio>(
  (ref) => _buildDio(timeout: const Duration(seconds: 20)),
);
