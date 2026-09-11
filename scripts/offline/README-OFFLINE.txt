NETCONTROL — OFFLINE BUILD KIT (حزمة البناء دون اتصال)
======================================================

محتويات هذه الحزمة:
  pub-cache/            مخزن حزم Dart كامل (192 حزمة)
  pubspec.lock          قفل النسخ الموثّق (لا تعدّله)
  gradle/wrapper-dists  توزيعة Gradle 8.4
  gradle/modules-2      كل ملفات Maven (AGP/Kotlin/AndroidX)
  licenses/             تراخيص Android SDK
  versions.txt          النسخ المستخدمة عند توليد الحزمة
  setup-offline.bat     سكربت الإعداد لـ Windows
  setup-offline.sh      سكربت الإعداد لـ Linux/macOS
  OFFLINE_BUILD.md      الدليل الكامل بالعربية

الاستخدام السريع (Windows):
  1) ثبت Flutter SDK 3.24.5 وAndroid Studio + SDK 34 مسبقاً.
  2) شغّل:  setup-offline.bat "C:\path\to\WiFi"
  3) انتظر — السكربت ينتهي ببناء APK كامل للتأكد.

النسخ المتوقعة على جهازك:
  Flutter 3.24.5  |  Dart 3.5.4  |  Gradle 8.4  |  AGP 8.3.0
  Kotlin 1.9.22   |  compileSdk 34 | minSdk 26   |  Java 17
