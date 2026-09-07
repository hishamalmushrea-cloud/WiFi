/// امتدادات نصية شائعة.
extension StringX on String {
  bool get isBlank => trim().isEmpty;

  /// أول حرف كبير والباقي كما هو — لتسميات الأجهزة والخدمات.
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// يقطع النص الطويل مع علامة حذف إن تجاوز [max].
  String ellipsize(int max) =>
      length <= max ? this : '${substring(0, max)}…';
}
