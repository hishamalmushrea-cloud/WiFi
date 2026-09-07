// ملف Gradle على مستوى المشروع.
// كل الإعدادات تُدار عبر Plugin Management في settings.gradle.kts
// (أسلوب Flutter الحديث)، لذلك تبقى كتلة subprojects فارغة عمداً.
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
