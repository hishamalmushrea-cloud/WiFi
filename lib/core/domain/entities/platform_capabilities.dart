/// كتالوج قدرات المنصات — توثيق صادق لما يعمل على Android مقابل iOS.
///
/// ملاحظة على القاعدة الصارمة للنصوص: عناوين ووصف القدرات هنا هي
/// بيانات محتوى (كتالوج) وليست نصوص واجهة — تبقى في هذا الملف كمصدر
/// وحيد لها. نصوص الواجهة العامة (عناوين الشاشة، الأزرار…) في
/// app_strings.dart كالمعتاد.
///
/// الهدف: أن يرى المستخدم قبل الاستخدام ما الذي تدعمه منصته، بدل
/// اكتشاف ذلك بالصدفة — خصوصاً على iOS حيث تقيّد Apple واجهات
/// الشبكة بشكل جذري.

/// مستوى الدعم على منصة.
enum SupportLevel {
  /// يعمل بالكامل.
  full,

  /// يعمل جزئياً أو بتدهور آمن (نتائج أقل دقة أو ميزة بديلة).
  partial,

  /// غير متاح على هذه المنصة قيود النظام.
  unavailable,
}

class PlatformCapability {
  const PlatformCapability({
    required this.title,
    required this.description,
    required this.android,
    required this.ios,
    this.iosNote,
  });

  final String title;
  final String description;

  /// مستوى الدعم على كل منصة.
  final SupportLevel android;
  final SupportLevel ios;

  /// توضيح إضافي لسبب القيد على iOS إن وجد.
  final String? iosNote;

  bool get isLimitedOnIos => ios != SupportLevel.full;
}

abstract class PlatformCapabilities {
  static const List<PlatformCapability> all = [
    // ── يعمل بالكامل على المنصتين ──
    PlatformCapability(
      title: 'اختبار سرعة الإنترنت',
      description:
          'قياس التحميل والرفع والاستجابة عبر خوادم Cloudflare — لا يحتاج أي صلاحية خاصة.',
      android: SupportLevel.full,
      ios: SupportLevel.full,
    ),
    PlatformCapability(
      title: 'لوحة تحكم الراوتر',
      description:
          'قراءة الأجهزة المتصلة، حجب MAC، وإدارة إعدادات الراوتر عبر بروتوكولات HTTP الخاصة بالمصنّعين.',
      android: SupportLevel.full,
      ios: SupportLevel.full,
    ),
    PlatformCapability(
      title: 'فحص المنافذ والثغرات',
      description:
          'فحص منافذ الأجهزة على الشبكة المحلية من التطبيق مباشرة دون امتيازات.',
      android: SupportLevel.full,
      ios: SupportLevel.full,
    ),
    PlatformCapability(
      title: 'كشف الجيلبريك / صلاحيات الروت',
      description:
          'فحص متعدد المؤشرات (ملفات، تطبيقات، مكتبات محقونة) عبر جسر أصلي لكل منصة.',
      android: SupportLevel.full,
      ios: SupportLevel.full,
    ),
    PlatformCapability(
      title: 'قفل التطبيق بالبصمة / Face ID',
      description:
          'حماية التطبيق بمصادقة الجهاز الحيوية عند الإقلاع والعودة من الخلفية.',
      android: SupportLevel.full,
      ios: SupportLevel.full,
    ),
    PlatformCapability(
      title: 'Wardriving وتسجيل الشبكات بالـ GPS',
      description:
          'تسجيل نقاط الوصول على الخريطة أثناء التنقل مع تصدير WiGLE.',
      android: SupportLevel.full,
      ios: SupportLevel.partial,
      iosNote:
          'يعمل أثناء فتح التطبيق في المقدمة؛ التشغيل الدائم في الخلفية مقيّد على iOS.',
    ),
    PlatformCapability(
      title: 'الخريطة الحرارية للتغطية',
      description:
          'أخذ عينات قوة الإشارة على مخطط الموقع ورسم خريطة التغطية.',
      android: SupportLevel.full,
      ios: SupportLevel.full,
      iosNote:
          'على Android تُقرأ الإشارة تلقائياً؛ على iOS يُدخل المستخدم القيمة يدوياً (لا واجهة RSSI عامة).',
    ),

    // ── مقيّد على iOS ──
    PlatformCapability(
      title: 'مسح شبكات WiFi المحيطة',
      description:
          'عرض الشبكات القريبة مع القناة والتشفير وقوة الإشارة لتحليل الازدحام.',
      android: SupportLevel.full,
      ios: SupportLevel.unavailable,
      iosNote:
          'Apple لا تتيح مسح الشبكات المحيطة إلا لتطبيقات ذات امتياز خاص (Hotspot Helper). يعمل التطبيق بالنتائج المحفوظة.',
    ),
    PlatformCapability(
      title: 'اكتشاف الأجهزة عبر جدول ARP',
      description:
          'قراءة جدول ARP النظامي لمعرفة الأجهزة المتصلة بعناوينها الفعلية.',
      android: SupportLevel.full,
      ios: SupportLevel.partial,
      iosNote:
          'قراءة جدول ARP غير متاحة؛ يقتصر الاكتشاف على فحص عناوين الشبكة (Ping Scan).',
    ),
    PlatformCapability(
      title: 'التقاط حزم الشبكة (Packet Capture)',
      description:
          'التقاط الحزم وتحليل البروتوكولات وكشف MITM.',
      android: SupportLevel.partial,
      ios: SupportLevel.unavailable,
      iosNote:
          'يتطلب صلاحيات روت على Android، وغير ممكن نهائياً على iOS بدون جيلبريك.',
    ),
    PlatformCapability(
      title: 'قراءة RSSI اللحظية للشبكة الحالية',
      description:
          'قياس قوة إشارة الشبكة المتصلة لحظياً لأخذ عينات دقيقة.',
      android: SupportLevel.full,
      ios: SupportLevel.unavailable,
      iosNote:
          'iOS لا يعرض RSSI إلا عبر واجهات خاصة بامتياز. البديل: الإدخال اليدوي في الخريطة الحرارية.',
    ),
  ];

  /// تجميع مرتب للعرض: المقيّد على iOS أولاً ثم الكامل.
  static List<PlatformCapability> get sortedForDisplay {
    final limited =
        all.where((c) => c.isLimitedOnIos).toList(growable: false);
    final full =
        all.where((c) => !c.isLimitedOnIos).toList(growable: false);
    return [...limited, ...full];
  }

  /// مستوى الدعم لمنصة معينة.
  static SupportLevel levelFor(PlatformCapability c, {required bool isIOS}) =>
      isIOS ? c.ios : c.android;
}
