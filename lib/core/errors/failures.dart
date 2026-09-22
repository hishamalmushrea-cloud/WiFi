/// أنواع الفشل (Failures) في طبقة المجال (Domain).
///
/// السبب: طبقة المجال لا تتعامل مع الاستثناءات التقنية مباشرة؛
/// نحوّلها إلى كائنات فشل دلالية برسائل عربية واضحة، فتستطيع
/// الواجهة عرض رسالة مفهومة دون معرفة تفاصيل التنفيذ.
/// نستخدم sealed لتضمن المحلّل (analyzer) تغطية كل الحالات
/// في `switch` دون فرع ناقص.
library;

sealed class Failure {
  const Failure(this.message);

  /// رسالة عربية جاهزة للعرض على المستخدم.
  final String message;
}

/// فشل في الاتصال بالشبكة (لا يوجد إنترنت/راوتر غير متاح).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'تعذّر الاتصال بالشبكة. تحقق من اتصالك.']);
}

/// فشل من خادم بعيد (HTTP 5xx أو استجابة غير صالحة).
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'تعذّر الحصول على استجابة من الخادم.',
    this.statusCode,
  ]);

  /// رمز الحالة HTTP إن كان متاحاً (للعرض أو التتبع).
  final int? statusCode;
}

/// مهلة انتهت دون استجابة.
class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'انتهت مهلة الانتظار. حاول مرة أخرى.']);
}

/// فشل في قاعدة البيانات المحلية.
class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'حدث خطأ في قاعدة البيانات المحلية.']);
}

/// صلاحية غير ممنوحة (موقع/بلوتوث/إشعارات).
class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'الصلاحية المطلوبة غير ممنوحة. فعّلها من إعدادات الجهاز.',
  ]);
}

/// ميزة تتطلب صلاحيات Root/Jailbreak غير متوفرة.
/// الفرق عن PermissionFailure: هذا قرار بيئة الجهاز لا صلاحية وقتية.
class RootRequiredFailure extends Failure {
  const RootRequiredFailure([
    super.message = 'هذه الميزة تتطلب صلاحيات Root على أندرويد أو Jailbreak على iOS.',
  ]);
}

/// فشل مصادقة مع الراوتر (اسم مستخدم/كلمة مرور خاطئة).
class RouterAuthFailure extends Failure {
  const RouterAuthFailure([
    super.message = 'فشل تسجيل الدخول للراوتر. تحقق من بيانات الدخول.',
  ]);
}

/// الكائن المطلوب غير موجود.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'العنصر المطلوب غير موجود.']);
}

/// فشل في التشفير/فك التشفير أو الخزن الآمن.
class SecurityFailure extends Failure {
  const SecurityFailure([super.message = 'حدث خطأ أمني أثناء معالجة البيانات الحساسة.']);
}

/// أي فشل آخر غير مصنّف — نحصر الرسالة التقنية في اللوج فقط.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'حدث خطأ غير متوقع. حاول مرة أخرى.']);
}
