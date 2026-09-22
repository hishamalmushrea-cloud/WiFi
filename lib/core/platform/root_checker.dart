import 'root_status.dart';

/// واجهة كشف صلاحيات الجذر.
///
/// السبب في فصلها عن التنفيذ: المنطق الأصلي يختلف جذرياً
/// بين Android (فحص su/Magisk/test-keys) و iOS (Cydia/Sileo/
/// Fork test)، والكود الأصلي يأتي في PHASE 11 عبر Method Channel.
/// نعتمد على الواجهة الآن ونحقنها كـ Provider فتعمل الواجهة كاملة.
abstract class RootChecker {
  /// فحص شامل متعدد الطرق. يجب ألا يرمي استثناءً أبداً:
  /// أي فشل يُعاد كـ [RootState.unknown] (graceful degradation).
  Future<RootStatus> check();

  /// فحص سريع لتخمين الحالة (يُستخدم عند الإقلاع).
  Future<bool> isRooted();
}
