import '../constants/app_constants.dart';

/// أدوات المنافذ والخدمات الشائعة.
class PortUtils {
  PortUtils._();

  /// اسم الخدمة المعروفة لمنفذ (من الخريطة المركزية)، وإلا null.
  static String? serviceName(int port) => AppConstants.commonPorts[port];

  /// هل المنفذ ضمن النطاق الصالح 1–65535؟
  static bool isValid(int port) => port >= 1 && port <= 65535;

  /// قائمة المنافذ الشائعة للفحص السريع الذكي.
  static List<int> commonPorts() => AppConstants.commonPorts.keys.toList();

  /// يوسّع وصفاً نصياً للمنافذ ("80,443,1000-1005") إلى أرقام.
  /// يسهّل إدخال المستخدم لنطاقات مخصصة في شاشة فحص المنافذ.
  static List<int> parseRange(String input) {
    final result = <int>{};
    for (final token in input.split(',')) {
      final t = token.trim();
      if (t.isEmpty) continue;
      if (t.contains('-')) {
        final bounds = t.split('-');
        if (bounds.length == 2) {
          final start = int.tryParse(bounds[0].trim());
          final end = int.tryParse(bounds[1].trim());
          if (start != null && end != null && start <= end) {
            for (var p = start; p <= end && p <= 65535; p++) {
              if (p >= 1) result.add(p);
            }
          }
        }
      } else {
        final p = int.tryParse(t);
        if (p != null && isValid(p)) result.add(p);
      }
    }
    return result.toList();
  }
}
