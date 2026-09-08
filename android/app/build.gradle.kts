plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin — يُطبَّق عبر settings.gradle.kts (قالب Flutter 3.19+)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.netcontrol.app"
    compileSdk = flutter.compileSdkVersion
    // أعلى NDK متوافق مع كل الإضافات (يتفادى تحذير التوافق في 12 إضافة).
    ndkVersion = "25.1.8937393"

    compileOptions {
        // مطلوب لـ flutter_local_notifications و workmanager:
        // يستخدمان واجهات Java 8 عبر desugar لدعم Android 8 (API 26).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.netcontrol.app"
        // minSdk 26 إلزامي حسب المواصفات (Android 8.0).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // التوقيع يُضبط لاحقاً عند الإنتاج؛ الاستخدام الشخصي الآن.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Flutter 3.24.5 + AGP 8.3: لا تتفعّل أحياناً نسخة插件 التي تنقل APK إلى
// build/app/outputs/flutter-apk/ التي يبحث عنها الأداة (flutter/flutter#174620).
// نزامن الملف صراحةً بعد اكتمال assembleRelease:
tasks.named("assembleRelease") {
    doLast {
        val from = layout.buildDirectory
            .file("outputs/apk/release/app-release.apk").get().asFile
        val toDir = file("$rootDir/../build/app/outputs/flutter-apk")
        toDir.mkdirs()
        val to = File(toDir, "app-release.apk")
        from.copyTo(to, overwrite = true)
        println("[NetControl] APK مُزامَن إلى flutter-apk (${to.length()} بايت)")
    }
}

dependencies {
    // تفكيك مكتبات Java الأساسية (WorkManager + الإشعارات).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
