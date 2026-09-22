package com.netcontrol.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.netcontrol.app.native.NativeChannels

/**
 * نقطة الدخول الأصلية لتطبيق Android.
 *
 * تسجّل كل الجسور الأصلية عند إنشاء المحرّك:
 *  - RootCheckerChannel   : فحص صلاحيات الجذر بأربع طرق
 *  - NetworkChannel       : معلومات الشبكة، جدول ARP، مسح WiFi
 *  - PacketCaptureChannel : التقاط حزم مباشر عبر tcpdump/EventChannel
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NativeChannels.register(applicationContext, flutterEngine)
    }
}
