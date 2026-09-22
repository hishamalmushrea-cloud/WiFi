# WiFi

[![GitHub Repo stars](https://img.shields.io/github/stars/hishamalmushrea-cloud/WiFi?style=social)](https://github.com/hishamalmushrea-cloud/WiFi)
[![GitHub](https://img.shields.io/github/license/hishamalmushrea-cloud/WiFi)](https://github.com/hishamalmushrea-cloud/WiFi/blob/main/LICENSE)
[![Trendshift](https://trendshift.io/api/badge/repositories/4119)](https://trendshift.io/)
[![Docs Website](https://img.shields.io/badge/Docs-Website-blue?style=for-the-badge&logo=readthedocs)](https://github.com/hishamalmushrea-cloud/WiFi)
[![Discord](https://img.shields.io/badge/Discord-Join%20Us-7289DA?style=for-the-badge&logo=discord&logoColor=white)](https://discord.com/)
[![X (formerly Twitter) Follow](https://img.shields.io/twitter/follow/hishamalmushrea-cloud?style=social)](https://x.com/hishamalmushrea-cloud)

---

# 🛡️ نت كونترول — NetControl

تطبيق Flutter شامل للتحكم بالشبكة والأمان على Android و iOS، يجمع ميزات أفضل
تطبيقات الشبكات (Fing، Router Chef، WiFiman، NetSpot، GlassWire، Nmap،
Speedtest، WiFi Analyzer، WiGLE، WiFi Pineapple، inSSIDer).

> **126 ميزة** — **45 شاشة** — **15 جدول قاعدة بيانات** — **10 أنواع راوتر**
> واجهة عربية RTL كاملة، تصميم Material 3 زجاجي داكن، متجاوب لكل الشاشات.

## 🧱 الحالة الحالية

✅ **PHASE 1 مكتملة: إعداد المشروع**

- مشروع Flutter 3.19+ / Dart 3.3+ مهيأ بالكامل
- `pubspec.yaml` بكل الحزم (Riverpod, Drift+SQLCipher, Dio, fl_chart,
  syncfusion, flutter_map, geolocator, flutter_blue_plus, pdf/csv…)
- هيكل مجلدات **Clean Architecture / Feature-First**
- نظام التصميم: ألوان، ثيمات داكن/فاتح، مسافات، خط IBM Plex Sans Arabic
- النصوص العربية مركزية في `app_strings.dart`
- اللوجر الموحد (ممنوع `print`)
- قاعدة بيانات Drift: **15 جدولاً** مع المفاتيح الأجنبية وWAL
- صلاحيات Android (Manifest + network security) و iOS (Info.plist)
- قناة Method Channel جاهزة للتسجيل (تُفعَّل في PHASE 11)

## 🚀 التشغيل

```bash
# 1) جلب الحزم
flutter pub get

# 2) توليد الكود (Drift / Freezed / Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 3) التشغيل
flutter run
```

> يتطلب Flutter 3.19+ و Dart 3.3+. على Android minSdk 26، وعلى iOS 14.0+.

## 🗺️ خارطة المراحل

| المرحلة | المحتوى | الحالة |
|---|---|---|
| 1 | إعداد المشروع | ✅ |
| 2 | Core Layer (ثيمات، أخطاء، كشف Root، أدوات، Extensions، متجاوب) | ✅ |
| 3 | Database Layer (15 جدول + 14 DAO + فهارس + SQLCipher + ترحيل) | ✅ |
| 4 | Domain Layer (12 كيان Freezed + 9 مستودعات + حالات استخدام) | ✅ |
| 5 | Data Layer (10 مستودعات + 10 متحكمات راوتر + Mappers + Datasources) | ✅ |
| 6 | Network Services (اكتشاف mDNS/UPnP، بصمة أجهزة، كشف تهديدات، مراقب خلفية، إشعارات، موفّرات Riverpod) | ✅ |
| 7 | UI - Common Widgets (زجاج، عدّادات، رسوم، حالات، تنقل) | ✅ |
| 8 | الشاشات الأساسية (Splash/Onboarding/Root/صلاحيات/لوحة/أجهزة/تفاصيل/إعدادات + أدوات) | ✅ |
| 9 | شاشات الميزات (فحص الشبكة/المنافذ/الثغرات، سرعة، لوحة راوتر بست تبويبات) | ✅ |
| 10 | الشاشات المتقدمة (خط زمني النشاط، خريطة حرارية/مسح موقع، Wardriving بـGPS+OpenStreetMap، التقاط حزم/محلل بروتوكولات/كشف MITM محمية بـRoot Gate، Wake-on-LAN) | ✅ |
| 11 | الكود الأصلي (Kotlin / Swift): فحص Root/جيلبريك، معلومات الشبكة وجدول ARP ومسح WiFi على Android، التقاط حزم عبر tcpdump/EventChannel، معلومات الشبكة على iOS | ✅ |
| 12 | الربط والتلميع (توحيد 170+ نص في app_strings، دوال تنسيق ديناميكية، اختبارات وحدة للمنطق الخالص) | ✅ |

## 🏗️ البنية

```
lib/
├── core/                 # ثوابت، ثيمات، قاعدة بيانات، لوجر، جسر أصلي
└── features/             # كل ميزة: data / domain / presentation
    ├── network_scan/     ├── speed_test/      ├── security/
    ├── wifi_analysis/    ├── router_control/  ├── wardriving/
    ├── tools/            ├── heatmap/         └── …
```
