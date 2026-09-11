# 📴 البناء دون اتصال — Offline Build

دليل بناء تطبيق **نت كونترول** على كمبيوتر **بدون إنترنت** من Android Studio.

## الفكرة باختصار

البناء يحتاج ثلاثة أشياء ضخمة لا يمكن وضعها داخل ملفات المستودع نفسه
(حدود GitHub 100MB للملف + آلاف ملفات Maven التي لا تُحصى إلا ببناء فعلي):

| المكوّن | الحجم التقريبي | مصدره في هذا الحل |
|---|---|---|
| حزم Dart (pub) | ~200MB | `offline-kit.zip` → مخزن pub |
| توزيعة Gradle 8.4 | ~120MB | `offline-kit.zip` → wrapper/dists |
| ملفات Maven (AGP/Kotlin/AndroidX) | ~600MB | `offline-kit.zip` → modules-2 |
| Flutter SDK نفسه | ~1GB | تنزيل منفصل (مرة واحدة) |
| Android Studio + SDK | موجود مسبقاً | على جهازك |

حزمة `offline-kit.zip` **يولّدها CI هذا المستودع تلقائياً** (workflow
اسمه **Build Offline Kit**) وتُنشر في [Releases](https://github.com/hishamalmushrea-cloud/WiFi/releases)
تحت الوسم `offline-kit-latest`.

---

## المتطلبات على الكمبيوتر بدون إنترنت (تُنقل بـ USB مرة واحدة)

| # | المتطلب | من أين |
|---|---|---|
| 1 | **Android Studio** مع **Android SDK 34** + Build-Tools 34 + Platform-Tools | مثبّت مسبقاً أو انسخ مجلد `Android/Sdk` من جهاز فيه إنترنت |
| 2 | **Flutter SDK 3.24.5** بالضبط | [flutter_windows_3.24.5-stable.zip](https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip) (فك الضغط في `C:\flutter` مثلاً) — لينكس: [flutter_linux_3.24.5-stable.tar.xz](https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz) |
| 3 | **Java 17** | يكفي JDK Android Studio المدمج (jbr) — السكربت يكتشفه |
| 4 | **المشروع** (مجلد WiFi) | من المستودع |
| 5 | **offline-kit.zip** | من [Releases](https://github.com/hishamalmushrea-cloud/WiFi/releases) — نزّله من أي جهاز فيه إنترنت |

> ⚠️ لا تستعمل إصدار Flutter غير 3.24.5 — نسخ Dart المولّدة في الحزمة
> مرتبطة به، ونسخة Gradle/AGP مختبرة معه تحديداً.

## خطوات التشغيل (Windows)

```bat
:: 1) فك ضغط offline-kit.zip في أي مكان (المكتب مثلاً)
:: 2) شغّل موجه الأوامر وانتقل إلى مجلد الحزمة، ثم:
setup-offline.bat "C:\path\to\WiFi"
```

السكربت يقوم بكل شيء تلقائياً:
1. ينسخ مخزن حزم Dart إلى مكان pub الافتراضي.
2. ينسخ توزيعة Gradle 8.4 وملفات Maven إلى `%USERPROFILE%\.gradle`.
3. يفعّل وضع Gradle دون اتصال **لهذا المشروع فقط**.
4. يكتب `android/local.properties` (مسارا SDK وFlutter).
5. ينفّذ `pub get --offline` + توليد الكود (`build_runner`).
6. **يبني APK كاملاً للتأكد** أن كل شيء يعمل — نتيجة نهائية خضراء أو
   رسالة خطأ واضحة.

بعد نجاحه: افتح المجلد في Android Studio وسيعمل Sync والبناء دون اتصال.
على Linux/macOS: `./setup-offline.sh /path/to/WiFi`.

## النسخ المرجعية

| المكوّن | النسخة |
|---|---|
| Flutter / Dart | 3.24.5 / 3.5.4 |
| Gradle (wrapper) | 8.4 |
| Android Gradle Plugin | 8.3.0 |
| Kotlin | 1.9.22 |
| compileSdk / targetSdk / minSdk | 34 / 34 / 26 |
| Java | 17 |

## استكشاف الأخطاء

| المشكلة | الحل |
|---|---|
| `Unable to strip the following libraries... libflutter.so` | **تحذير حميد** — غياب NDK لا يمنع البناء |
| `Failed to find platform android-34` | ثبّت SDK Platform 34 عبر Android Studio (أو انسخ مجلد `platforms/android-34` بـ USB) |
| `No version of NDK matches` | تحذير فقط — المشروع بلا كود أصلي C/C++ |
| فشل `pub get --offline` | تأكد أنك على Flutter 3.24.5 وأن السكربت نسخ المخزن لنفس المستخدم الذي يبني |
| Gradle `offline mode` ينقصه ملف | أعد توليد الحزمة (الأسفل) — حدث المستودع بملف جديد |
| أين ملف `gradlew`؟ | أداة Flutter تحقنه تلقائياً من SDK عند أول `flutter build` — طبيعي |

## تحديث الحزمة بعد تغيّر المشروع

من تبويب [Actions](https://github.com/hishamalmushrea-cloud/WiFi/actions) →
**Build Offline Kit** → **Run workflow** → اختر الفرع → Run. بعد ~20 دقيقة
تُنشر نسخة جديدة في Releases.

> كيف تعمل؟ الـ workflow يبني المشروع بنجاح على جهاز CI متصل، ثم يحزم
> كل مخازن البناء الناتجة — ولهذا تُلتقط قائمة Maven الدقيقة 100% التي
> يستحيل حسابها يدوياً.
