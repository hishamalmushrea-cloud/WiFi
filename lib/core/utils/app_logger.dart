import 'package:logger/logger.dart';

/// اللوجر الموحد للتطبيق.
///
/// سبب اللفّ حول حزمة logger: نمنع استخدام `print()` نهائياً
/// (مفروض عبر lint أيضاً) ونوفر واجهة عربية الدلالة مع تصنيف
/// للرسائل حسب الطبقة، ويمكن مستقبلاً توجيه اللوج لملف محلي
/// أو إيقافه في إصدارات الإنتاج من مكان واحد.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    level: Level.debug,
  );

  /// معلومة عامة عن تدفق التطبيق.
  static void info(String message, {String? tag}) =>
      _logger.i(tag == null ? message : '[$tag] $message');

  /// تفاصيل تتبّع للفحص والتطوير.
  static void debug(String message, {String? tag}) =>
      _logger.d(tag == null ? message : '[$tag] $message');

  /// تحذير لا يوقف العملية لكن يجب الانتباه له.
  static void warning(String message,
          {String? tag, Object? error, StackTrace? stackTrace}) =>
      _logger.w(tag == null ? message : '[$tag] $message',
          error: error, stackTrace: stackTrace);

  /// خطأ فعلي — يُستخدم في مسارات معالجة الاستثناءات.
  static void error(String message,
          {String? tag, Object? error, StackTrace? stackTrace}) =>
      _logger.e(tag == null ? message : '[$tag] $message',
          error: error, stackTrace: stackTrace);
}
