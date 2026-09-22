/// نتيجة فحص صلاحيات الجذر (Root على Android / Jailbreak على iOS).
///
/// نموذج غير قابل للتعديل نعيده من [RootChecker] لتستهلكه
/// واجهة فحص Root وحالة الميزات الـ 30 المتقدمة.
library;

enum RootState {
  /// الجهاز مروّت/مكسر الحماية — الميزات المتقدمة متاحة.
  granted,

  /// الجهاز سليم — تعمل الميزات الأساسية فقط.
  notGranted,

  /// الفحص جارٍ أو لم يُنفَّذ بعد.
  checking,

  /// تعذّر الجزم (قناة غير متاحة) — نعاملها كأنه لا يوجد Root
  /// مع رسالة توضيحية، تطبيقاً لمبدأ graceful degradation.
  unknown,
}

class RootStatus {
  const RootStatus({
    required this.state,
    this.methods = const <String>[],
    this.evidence = const <String>[],
  });

  final RootState state;

  /// طرق الكشف التي اشتغلت (للعرض التقني في شاشة الفحص).
  final List<String> methods;

  /// دلائل مقروءة وجدت (مثل مسار Magisk) — للعرض فقط.
  final List<String> evidence;

  bool get isRooted => state == RootState.granted;

  /// عدد الميزات المتاحة حسب الحالة (من المواصفات).
  int get availableFeatures => isRooted ? 126 : 96;
  int get lockedFeatures => isRooted ? 0 : 30;

  factory RootStatus.checking() => const RootStatus(state: RootState.checking);

  RootStatus copyWith({
    RootState? state,
    List<String>? methods,
    List<String>? evidence,
  }) =>
      RootStatus(
        state: state ?? this.state,
        methods: methods ?? this.methods,
        evidence: evidence ?? this.evidence,
      );
}
