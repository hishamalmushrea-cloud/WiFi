// ملف Gradle على مستوى المشروع.
// كل الإعدادات تُدار عبر Plugin Management في settings.gradle.kts
// (أسلوب Flutter الحديث).
allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // بعض إضافات Flutter لا تُصرّح compileSdk فتُفشل على AGP 8
    // ("compileSdkVersion is not specified")، نفرضها قبل التقييم.
    project.plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            if (compileSdk == null) compileSdk = 34
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
