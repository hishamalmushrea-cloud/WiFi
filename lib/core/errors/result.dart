library;

import '../utils/app_logger.dart';
import 'exceptions.dart';
import 'failures.dart';

/// نتيجة عملية إما [Success] تحمل البيانات أو [FailureResult]
/// تحمل سبب الفشل. بديل خفيف عن حزمة dartz بأسلوب Dart 3 المختوم.
///
/// سبب التصميم: يُجبر كل مستدعي على معالجة حالتي النجاح والفشل
/// صراحة عبر [when]، فلا تُبتلع الأخطاء في الواجهة.

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;

  /// البيانات في حالة النجاح، أو null في الفشل.
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        FailureResult<T>() => null,
      };

  /// الفشل إن وُجد، أو null في النجاح.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        FailureResult<T>(:final failure) => failure,
      };

  /// معالجة شاملة للحالتين (مشابهة لـ fold).
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Success<T>(:final data) => onSuccess(data),
        FailureResult<T>(:final failure) => onFailure(failure),
      };
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}

/// غلاف أمني لتنفيذ أي عملية:
/// يحوّل كل استثناء إلى [Failure] مطابق بدل أن ينهار التطبيق.
///
/// الاستخدام:
/// ```dart
/// final result = await guard(() => repository.scan());
/// result.when(
///   onSuccess: (data) => ...,
///   onFailure: (f) => ...,
/// );
/// ```
Future<Result<T>> guard<T>(Future<T> Function() action) async {
  try {
    return Success(await action());
  } on AppException catch (e) {
    // AppException تحمل تحويلها الجاهز إلى Failure.
    return FailureResult(e.toFailure());
  } catch (e, stackTrace) {
    // أي استثناء غير متوقع: نسجّل التفاصيل التقنية في اللوج
    // ونعيد رسالة عامة كي لا تتسرب لغة تقنية للمستخدم.
    AppLogger.error('استثناء غير ممسوك في guard', error: e, stackTrace: stackTrace);
    return FailureResult(const UnknownFailure());
  }
}
