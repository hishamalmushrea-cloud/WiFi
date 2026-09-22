import '../../errors/result.dart';

/// عقد حالة استخدام واحدة (Use Case).
///
/// السبب: كل عملية أعمال تُغلَّف في صنف مستقل يحمل اسماً واضحاً
/// يُستدعى عبر `call(...)`، فتُختبر وحدها وتُعاد الاستفادة منها
/// عبر مزودات Riverpod دون تسرّب منطق إلى الويدجت.
abstract class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

/// حالة استخدام تعيد بثاً حياً (Streams) بدل مستقبَل واحد.
abstract class StreamUseCase<Type, Params> {
  Stream<Type> call(Params params);
}

/// وسيط فارغ للحالات التي لا تحتاج مدخلات.
class NoParams {
  const NoParams();
}
