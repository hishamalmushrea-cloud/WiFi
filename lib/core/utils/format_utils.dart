/// تنسيق وحدات البيانات والإشارة بشكل مقروء عربي.
class FormatUtils {
  FormatUtils._();

  /// يحوّل بايتات إلى «KB/MB/GB» بفاصلتين.
  static String dataSize(num bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 100 || unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  /// سرعة بيانات/ث (مثلاً استهلاك) بتنسيق «KB/s».
  static String dataRate(num bytesPerSecond) => '${dataSize(bytesPerSecond)}/ث';

  /// سرعة إنترنت بالميجابت مع منزلتين عند اللزوم.
  static String speedMbps(num mbps) {
    if (mbps >= 100) return mbps.toStringAsFixed(0);
    if (mbps >= 10) return mbps.toStringAsFixed(1);
    return mbps.toStringAsFixed(2);
  }

  /// dBm إلى نسبة مئوية تقريبية للعرض (مقاييس RSSI الشائعة).
  /// القيم بين -100 (ضعيف جداً) و -40 (ممتاز).
  static int rssiToPercent(int rssi) {
    const min = -100;
    const max = -40;
    final pct = ((rssi - min) / (max - min)) * 100;
    return pct.clamp(0, 100).round();
  }

  /// تصنيف نصي عربي لقوة الإشارة.
  static String signalLabel(int rssi) {
    if (rssi >= -50) return 'ممتازة';
    if (rssi >= -60) return 'جيدة جداً';
    if (rssi >= -70) return 'جيدة';
    if (rssi >= -80) return 'ضعيفة';
    return 'ضعيفة جداً';
  }

  /// رقم بفواصل آلاف عربية-هندية لاحقاً؟ نُبقي أرقاماً لاتينية
  /// لاتساقها مع القيم التقنية (IP/MAC/سرعات).
  static String number(num value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();
}
