import '../utils/format_utils.dart';

/// امتدادات رقمية لتنسيق وحدات الشبكة.
extension NumX on num {
  String get asDataSize => FormatUtils.dataSize(this);
  String get asDataRate => FormatUtils.dataRate(this);
  String get asMbps => FormatUtils.speedMbps(this);

  /// dBm → نسبة مئوية للعرض.
  int get rssiPercent => FormatUtils.rssiToPercent(toInt());
}
