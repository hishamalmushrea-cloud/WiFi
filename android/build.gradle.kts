// ملف Gradle على مستوى المشروع.
// كل الإعدادات تُدار عبر Plugin Management في settings.gradle.kts
// (أسلوب Flutter الحديث).
allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // بعض إضافات Flutter (مثل flutter_blue_plus) لا تُصرّح compileSdk
    // فتُفشل على AGP 8: "compileSdkVersion is not specified".
    // نفرضها على كل الوحدات لضمان بناء متّسق.
    project.plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            if (compileSdk == null) compileSdk = 34
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
