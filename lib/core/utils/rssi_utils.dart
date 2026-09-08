/// أدوات قوة الإشارة (RSSI) — منطق خالص قابل للاختبار.
///
/// يُستخدم في الخريطة الحرارية لتصنيف جودة القراءات والتحقق
/// من صحتها قبل اعتمادها.
library;

/// تصنيف جودة إشارة بوحدة dBm (معايير شائعة لشبكات WiFi).
enum RssiQuality {
  excellent,
  good,
  fair,
  weak,
  veryPoor,
}

abstract class RssiUtils {
  /// الحدود المنطقية لقراءة RSSI صالحة من WiFi.
  static const int minValid = -100;
  static const int maxValid = -20;

  /// هل القراءة داخل المدى المنطقي؟ (يستبعد 0 وINVALID_RSSI=-9999)
  static bool isValidRssi(int rssi) =>
      rssi >= minValid && rssi <= maxValid;

  /// يحصر قيمة في المدى المعقول للعرض والرسم.
  static int clampRssi(int rssi) => rssi.clamp(minValid + 5, -30);

  /// يصنّف جودة الإشارة وفق العتبات المتعارف عليها.
  static RssiQuality qualityOf(int rssi) {
    if (rssi >= -50) return RssiQuality.excellent;
    if (rssi >= -60) return RssiQuality.good;
    if (rssi >= -70) return RssiQuality.fair;
    if (rssi >= -80) return RssiQuality.weak;
    return RssiQuality.veryPoor;
  }

  /// اللون التقريبي للجودة كقيمة مضاعف شفافية 0–1 للحرارة
  /// (1 = ممتاز، 0 = ضعيف جداً) — يفيد في تدرجات الرسم.
  static double heatOf(int rssi) {
    final clamped = clampRssi(rssi);
    // المدى الفعلي بعد الحصر: [-95, -30] → قيمة 0–1.
    return ((clamped + 95) / 65).clamp(0.0, 1.0);
  }
}
