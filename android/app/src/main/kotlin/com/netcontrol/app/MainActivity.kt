package com.netcontrol.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * نقطة الدخول الأصلية لتطبيق Android.
 *
 * القنوات الأصلية (Method Channels) التالية ستُسجَّل هنا في PHASE 11:
 *  - [RootCheckerChannel]  : فحص صلاحيات Root بطرق متعددة
 *  - [NetworkChannel]      : جدول ARP، معلومات WiFi، أوامر ping
 *  - [ArpReaderChannel]    : قراءة ملفات /proc/net/arp
 *
 * نُبقي الـ Activity في أقل صورة ممكنة الآن ليعمل توليد
 * GeneratedPluginRegistrant تلقائياً، وكل القنوات تُضاف في مرحلتها.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // تسجيل القنوات الأصلية سيتم هنا في PHASE 11.
    }
}
