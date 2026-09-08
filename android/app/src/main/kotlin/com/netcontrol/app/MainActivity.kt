package com.netcontrol.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import com.netcontrol.app.native.NativeChannels

/**
 * نقطة الدخول الأصلية لتطبيق Android.
 *
 * تسجّل كل الجسور الأصلية عند إنشاء المحرّك:
 *  - RootCheckerChannel   : فحص صلاحيات الجذر بأربع طرق
 *  - NetworkChannel       : معلومات الشبكة، جدول ARP، مسح WiFi، RSSI
 *  - PacketCaptureChannel : التقاط حزم مباشر عبر tcpdump/EventChannel
 *
 * نرث من FlutterFragmentActivity (وليس FlutterActivity) لأن مكوّن
 * local_auth يعرض نافذة البصمة عبر BiometricPrompt التي تتطلب
 * FragmentActivity — وإلا يفشل قفل التطبيق على Android.
 */
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NativeChannels.register(applicationContext, flutterEngine)
    }
}
