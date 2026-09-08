import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/app_lock_gate.dart';
import 'features/splash/presentation/app_gate.dart';

/// الجذر البصري للتطبيق.
///
/// عربي RTL افتراضياً مع دعم الاتجاه تلقائياً عبر Localizations،
/// وثيم داكن افتراضي (يتغير عبر Provider الإعدادات في مرحلة لاحقة).
class NetControlApp extends StatelessWidget {
  const NetControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // ── الاتجاه واللغة ──
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── الثيم: داكن افتراضياً مع نسخة فاتحة ──
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,

      home: const AppGate(),
      builder: (context, child) {
        // نوسّط المحتوى ونحدّد أقصى عرض على الشاشات الكبيرة
        // (ديسكتوب/تابلت أفقي) حسب قاعدة التصميم المتجاوب.
        //
        // AppLockGate فوق الـ Navigator نفسه (لا داخل مسار) حتى يغطي
        // الحاجز كل الشاشات والحوارات، ويُبقى المحتوى مبنيًّا خلفه
        // فيُحفظ وضع التنقل ولا يظهر أي محتوى حساس في multitasking.
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AppLockGate(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.maxContentWidth,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
