// ملف Gradle على مستوى المشروع.
// كل الإعدادات تُدار عبر Plugin Management في settings.gradle.kts
// (أسلوب Flutter الحديث).

// كائن flutter تطلبه بعض إضافات Flutter (geolocator/flutter_blue_plus…)
// عبر `android.flutter.minSdkVersion` في build.gradle بصياغتها القديمة.
// بعد إعادة تنظيم Gradle في Flutter الحديثة اختفى هذا الامتداد من سياق
// المكتبات، فتعرض "Could not get unknown property 'flutter'".
// نوفّر قيم الـ SDK بصفات ext على مستوى الجذر فتجدها الإضافات.
extra["flutter.minSdkVersion"] = 26
extra["flutter.targetSdkVersion"] = 34
extra["flutter.compileSdkVersion"] = 34

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // بعض الإضافات لا تُصرّح compileSdk فتُفشل على AGP 8؛ نفرضها.
    project.plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            if (compileSdk == null) compileSdk = 34
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
