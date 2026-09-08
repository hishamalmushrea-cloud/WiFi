import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/rssi_utils.dart';

/// مصدر أخذ قراءة الإشارة للخريطة الحرارية.
///
///  - auto  : قراءة RSSI الحقيقية للشبكة المتصلة عبر القناة الأصلية
///            (Android فقط — iOS لا يتيحها بدون واجهات خاصة).
///  - manual: المستخدم يُدخل القيمة بنفسه (يعمل على كل المنصات).
///  - demo  : قيم محاكاة لأغراض العرض فقط — لا تُحفظ ولا تُصدَّر،
///            وتظهر ببانر واضح يفيد بأنها غير حقيقية.
enum SignalSourceMode { auto, manual, demo }

/// الوضع الافتراضي بحسب المنصة: Android قراءة تلقائية، iOS إدخال
/// يدوي (لا توجد واجهة RSSI عامة على iOS).
SignalSourceMode defaultModeForPlatform({required bool isIOS}) =>
    isIOS ? SignalSourceMode.manual : SignalSourceMode.auto;

/// يقرأ قوة إشارة الشبكة المتصلة حالياً (dBm) عبر الجسر الأصلي.
///
/// أي فشل (منصة غير مدعومة، WiFi مغلق، صلاحية مرفوضة) يُعاد null —
/// لا نُخترع قيمة أبداً؛ الواجهة تعرض حينها تلميحاً للتبديل للإدخال
/// اليدوي.
class SignalSampler {
  SignalSampler([this.channel = const MethodChannel(AppConstants.channelNetwork)]);

  final MethodChannel channel;

  Future<int?> readConnectedRssi() async {
    int? raw;
    try {
      raw = await channel.invokeMethod<int>('getWifiRssi');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }

    if (raw == null) return null;
    // يستبعد 0 وINVALID_RSSI (-9999) وقيم القمم غير المنطقية.
    if (!RssiUtils.isValidRssi(raw)) return null;
    if (kDebugMode) {
      debugPrint('[SignalSampler] RSSI الحقيقية: $raw dBm');
    }
    return raw;
  }
}

final signalSamplerProvider = Provider<SignalSampler>((_) => SignalSampler());
