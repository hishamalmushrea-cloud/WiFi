library;

import 'failures.dart';

/// استثناءات طبقة البيانات (Data).
///
/// تُرمى من مصادر البيانات (Dio، Drift، القنوات الأصلية) ثم
/// تُلتقط وتُحوَّل إلى [Failure] مطابق في [guard]، فلا تصل
/// الاستثناءات التقنية لطبقة المجال أبداً.

sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';

  /// التحويل المطابق لـ Failure في طبقة المجال.
  Failure toFailure();
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'لا يوجد اتصال بالشبكة']);
  @override
  Failure toFailure() => const NetworkFailure();
}

class ServerException extends AppException {
  const ServerException([super.message = 'خطأ من الخادم', this.statusCode]);
  final int? statusCode;
  @override
  Failure toFailure() => ServerFailure(message, statusCode);
}

class TimeoutAppException extends AppException {
  const TimeoutAppException([super.message = 'انتهت المهلة']);
  @override
  Failure toFailure() => const TimeoutFailure();
}

class DatabaseException extends AppException {
  const DatabaseException([super.message = 'خطأ في قاعدة البيانات']);
  @override
  Failure toFailure() => DatabaseFailure(message);
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'صلاحية غير ممنوحة']);
  @override
  Failure toFailure() => PermissionFailure(message);
}

class RootRequiredException extends AppException {
  const RootRequiredException([super.message = 'تتطلب صلاحيات Root']);
  @override
  Failure toFailure() => const RootRequiredFailure();
}

class RouterAuthException extends AppException {
  const RouterAuthException([super.message = 'فشلت مصادقة الراوتر']);
  @override
  Failure toFailure() => RouterAuthFailure(message);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'غير موجود']);
  @override
  Failure toFailure() => NotFoundFailure(message);
}

class SecurityException extends AppException {
  const SecurityException([super.message = 'خطأ أمني']);
  @override
  Failure toFailure() => SecurityFailure(message);
}
