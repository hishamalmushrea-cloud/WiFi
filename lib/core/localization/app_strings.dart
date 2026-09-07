/// النصوص العربية المركزية للتطبيق.
///
/// قاعدة صارمة: لا يوضع أي نص عربي أو إنجليزي ظاهر للمستخدم
/// خارج هذا الملف. هذا يضمن:
///  1) سهولة الترجمة لاحقاً (تُستبدل بملفات arb عند الحاجة).
///  2) اتساق المصطلحات التقنية في كل الشاشات.
///  3) مراجعة النصوص من مكان واحد.
abstract class AppStrings {
  // ── عام ──────────────────────────────────────────────────────
  static const String appName = 'نت كونترول';
  static const String appTagline = 'تحكم شامل بشبكتك وأمانها';
  static const String loading = 'جارٍ التحميل…';
  static const String retry = 'إعادة المحاولة';
  static const String cancel = 'إلغاء';
  static const String save = 'حفظ';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String close = 'إغلاق';
  static const String confirm = 'تأكيد';
  static const String search = 'بحث';
  static const String settings = 'الإعدادات';
  static const String yes = 'نعم';
  static const String no = 'لا';
  static const String unknown = 'غير معروف';
  static const String online = 'متصل';
  static const String offline = 'غير متصل';
  static const String enabled = 'مفعّل';
  static const String disabled = 'معطّل';
  static const String copy = 'نسخ';
  static const String share = 'مشاركة';
  static const String export = 'تصدير';
  static const String start = 'بدء';
  static const String stop = 'إيقاف';
  static const String back = 'رجوع';
  static const String next = 'التالي';
  static const String done = 'تم';
  static const String details = 'تفاصيل';
  static const String refresh = 'تحديث';
  static const String seeAll = 'عرض الكل';

  // ── شاشة الإقلاع ─────────────────────────────────────────────
  static const String splashInitializing = 'جارٍ تهيئة المحرك الأمني…';
  static const String splashLoading = 'تحميل الوحدات…';

  // ── التعريف بالتطبيق (Onboarding) ───────────────────────────
  static const String onboardingTitle1 = 'افحص شبكتك';
  static const String onboardingBody1 =
      'اكتشف كل الأجهزة المتصلة بشبكتك، نوعها، ومصنّعها، وتابع أي جهاز غريب فور دخوله.';
  static const String onboardingTitle2 = 'حلّل وراقب';
  static const String onboardingBody2 =
      'تحليل القنوات، الخرائط الحرارية، اختبار السرعة، وكشف هجمات الواي فاي في مكان واحد.';
  static const String onboardingTitle3 = 'تحكم بالراوتر';
  static const String onboardingBody3 =
      'احظر الأجهزة، حدّد السرعات، أدر شبكة الضيوف، وعدّل إعدادات الواي فاي — من عشرات أنواع الراوترات.';
  static const String onboardingSkip = 'تخطّي';
  static const String onboardingStart = 'لنبدأ';

  // ── فحص Root ─────────────────────────────────────────────────
  static const String rootCheckTitle = 'فحص صلاحيات النظام';
  static const String rootAvailable = 'صلاحيات Root متاحة';
  static const String rootAvailableBody =
      'يمكنك استخدام جميع الميزات المتقدمة الـ 30: التقاط الحزم، فحوصات SYN، وكشف هجمات Deauth.';
  static const String rootUnavailable = 'لا توجد صلاحيات Root';
  static const String rootUnavailableBody =
      'سيعمل التطبيق بكامل ميزاته الأساسية (96 ميزة). الميزات المتقدمة ستظهر مع علامة «تتطلب Root».';
  static const String rootCheckButton = 'فحص حالة Root';
  static const String rootChecking = 'جارٍ الفحص…';
  static const String rootGuide = 'دليل الحصول على Root (متقدم)';
  static const String continueWithoutRoot = 'المتابعة بدون Root';
  static const String requiresRoot = 'تتطلب صلاحيات Root';
  static const String requiresRootBody =
      'هذه الميزة تحتاج صلاحيات Root على Android أو Jailbreak على iOS للوصول لواجهات الشبكة المنخفضة المستوى.';

  // ── الصلاحيات ────────────────────────────────────────────────
  static const String permissionsTitle = 'الصلاحيات المطلوبة';
  static const String permissionLocation = 'الموقع الجغرافي';
  static const String permissionLocationBody =
      'لتحليل شبكات الواي فاي وتسجيلها على الخريطة (تتطلبها قيود أندرويد لمسح WiFi).';
  static const String permissionBluetooth = 'البلوتوث';
  static const String permissionBluetoothBody = 'لفحص أجهزة بلوتوث وBLE القريبة.';
  static const String permissionNotifications = 'الإشعارات';
  static const String permissionNotificationsBody = 'تنبيهات الأمان والأجهزة الجديدة في الشبكة.';
  static const String permissionBackground = 'العمل في الخلفية';
  static const String permissionBackgroundBody = 'مراقبة مستمرة للشبكة وكشف الانقطاعات.';
  static const String permissionGrant = 'منح الصلاحية';
  static const String permissionsContinue = 'المتابعة';

  // ── التنقل السفلي ────────────────────────────────────────────
  static const String navHome = 'الرئيسية';
  static const String navNetwork = 'الشبكة';
  static const String navWifi = 'الواي فاي';
  static const String navSecurity = 'الأمان';
  static const String navTools = 'أدوات';

  // ── لوحة التحكم ──────────────────────────────────────────────
  static const String dashboardTitle = 'لوحة التحكم';
  static const String statOnlineDevices = 'أجهزة متصلة';
  static const String statSecurityScore = 'مؤشر الأمان';
  static const String statLastSpeed = 'آخر سرعة';
  static const String statAlerts = 'تنبيهات نشطة';
  static const String quickActions = 'إجراءات سريعة';
  static const String actionScanNetwork = 'فحص الشبكة';
  static const String actionSpeedTest = 'اختبار السرعة';
  static const String actionWifiAnalysis = 'تحليل الواي فاي';
  static const String actionSecurity = 'فحص الأمان';
  static const String actionRouter = 'التحكم بالراوتر';
  static const String actionWardriving = 'مسح الطريق';
  static const String recentAlerts = 'آخر التنبيهات';
  static const String welcomeSubtitle = 'إليك ملخص شبكتك الآن';

  // ── الأجهزة ──────────────────────────────────────────────────
  static const String devicesTitle = 'الأجهزة';
  static const String deviceUnknown = 'جهاز غير معروف';
  static const String deviceDetails = 'تفاصيل الجهاز';
  static const String deviceIp = 'عنوان IP';
  static const String deviceMac = 'عنوان MAC';
  static const String deviceVendor = 'المصنّع';
  static const String deviceType = 'النوع';
  static const String deviceOs = 'نظام التشغيل';
  static const String deviceHostname = 'اسم المضيف';
  static const String deviceSignal = 'قوة الإشارة';
  static const String deviceConnection = 'نوع الاتصال';
  static const String deviceFirstSeen = 'أول ظهور';
  static const String deviceLastSeen = 'آخر ظهور';
  static const String deviceFavorite = 'مفضّل';
  static const String deviceKnown = 'معروف';
  static const String deviceBlocked = 'محظور';
  static const String deviceRename = 'إعادة تسمية';
  static const String deviceBlock = 'حظر الجهاز';
  static const String deviceUnblock = 'إلغاء الحظر';
  static const String deviceLimitSpeed = 'تحديد السرعة';
  static const String deviceWake = 'إيقاظ (WOL)';
  static const String deviceHistory = 'السجل التاريخي';
  static const String deviceNotes = 'ملاحظات';
  static const String filterAll = 'الكل';
  static const String filterOnline = 'متصل';
  static const String filterOffline = 'غير متصل';
  static const String filterFavorites = 'المفضلة';
  static const String filterBlocked = 'المحظورة';
  static const String newDeviceAlert = 'جهاز جديد على شبكتك';

  // ── فحص الشبكة ───────────────────────────────────────────────
  static const String scanNetworkTitle = 'فحص الشبكة';
  static const String scanStart = 'بدء الفحص';
  static const String scanning = 'جارٍ الفحص…';
  static const String scanProgress = 'تم فحص {scanned} من {total} عنوان';
  static const String scanDevicesFound = 'عُثر على {count} جهاز';
  static const String scanComplete = 'اكتمل الفحص';
  static const String lanInfo = 'الشبكة المحلية';
  static const String gateway = 'البوابة (الراوتر)';
  static const String subnet = 'الشبكة الفرعية';
  static const String publicIp = 'عنوان IP العام';

  // ── المنافذ والفحص المتقدم ───────────────────────────────────
  static const String portScanTitle = 'فحص المنافذ';
  static const String port = 'المنفذ';
  static const String protocol = 'البروتوكول';
  static const String service = 'الخدمة';
  static const String state = 'الحالة';
  static const String portOpen = 'مفتوح';
  static const String portClosed = 'مغلق';
  static const String portFiltered = 'مصفّى';
  static const String tcpConnectScan = 'فحص اتصال TCP';
  static const String synScan = 'فحص SYN (يتطلب Root)';
  static const String udpScan = 'فحص UDP';
  static const String serviceVersion = 'إصدار الخدمة';
  static const String osDetection = 'كشف نظام التشغيل';

  // ── السرعة ───────────────────────────────────────────────────
  static const String speedTestTitle = 'اختبار السرعة';
  static const String download = 'التحميل';
  static const String upload = 'الرفع';
  static const String ping = 'الكمون (Ping)';
  static const String jitter = 'التذبذب (Jitter)';
  static const String mbps = 'ميجابت/ث';
  static const String ms = 'مللي ثانية';
  static const String speedHistory = 'سجل السرعات';
  static const String isp = 'مزود الخدمة';
  static const String startSpeedTest = 'بدء الاختبار';
  static const String peakSpeed = 'أعلى سرعة';

  // ── تحليل WiFi ───────────────────────────────────────────────
  static const String wifiAnalysisTitle = 'تحليل الواي فاي';
  static const String channelGraph = 'رسم القنوات';
  static const String apList = 'نقاط الوصول';
  static const String bestChannel = 'أفضل قناة';
  static const String channel = 'القناة';
  static const String frequency = 'التردد';
  static const String band = 'النطاق';
  static const String security = 'الأمان';
  static const String signalStrength = 'قوة الإشارة';
  static const String interference = 'التداخل';
  static const String band24 = '2.4 جيجاهرتز';
  static const String band5 = '5 جيجاهرتز';
  static const String band6 = '6 جيجاهرتز (WiFi 6E)';
  static const String recommendedChannel = 'القناة الموصى بها';
  static const String noApNearby = 'لا توجد نقاط وصول — تأكد من تفعيل الموقع.';

  // ── الأمان ───────────────────────────────────────────────────
  static const String securityDashboard = 'لوحة الأمان';
  static const String securityScore = 'مؤشر الأمان';
  static const String alertsCenter = 'مركز التنبيهات';
  static const String vulnerabilities = 'الثغرات المكتشفة';
  static const String threatCritical = 'حرج';
  static const String threatHigh = 'مرتفع';
  static const String threatMedium = 'متوسط';
  static const String threatLow = 'منخفض';
  static const String evilTwin = 'شبكة توأم خبيثة محتملة';
  static const String rogueAp = 'نقطة وصول مشبوهة';
  static const String arpSpoofing = 'محاولة انتحال ARP';
  static const String deauthAttack = 'هجوم قطع اتصال';
  static const String intruderDetected = 'جهاز دخيل محتمل';
  static const String markResolved = 'تعليم كمعالَج';

  // ── الراوتر ──────────────────────────────────────────────────
  static const String routerSelection = 'اختر نوع الراوتر';
  static const String routerConnect = 'الاتصال بالراوتر';
  static const String routerIp = 'عنوان الراوتر';
  static const String routerUsername = 'اسم المستخدم';
  static const String routerPassword = 'كلمة المرور';
  static const String routerAutoDetect = 'اكتشاف تلقائي';
  static const String routerDashboard = 'لوحة الراوتر';
  static const String routerWifiSettings = 'إعدادات الواي فاي';
  static const String routerGuestNetwork = 'شبكة الضيوف';
  static const String routerPortForwarding = 'توجيه المنافذ';
  static const String routerClients = 'الأجهزة المتصلة';
  static const String routerMacFilter = 'تصفية MAC';
  static const String routerReboot = 'إعادة تشغيل الراوتر';
  static const String routerFactoryReset = 'استعادة المصنع';
  static const String routerFactoryResetWarn =
      'سيؤدي هذا لمسح كل الإعدادات نهائياً! هل أنت متأكد؟';
  static const String routerConnected = 'متصل بالراوتر';

  // ── الأدوات ──────────────────────────────────────────────────
  static const String toolsTitle = 'أدوات الشبكة';
  static const String toolPing = 'فحص Ping';
  static const String toolTraceroute = 'تتبع المسار';
  static const String toolWhois = 'استعلام WHOIS';
  static const String toolDns = 'استعلام DNS';
  static const String toolSubnet = 'حاسبة الشبكات';
  static const String toolWol = 'إيقاظ الأجهزة (WOL)';
  static const String toolMacVendor = 'معرفة المصنّع من MAC';
  static const String toolIpConverter = 'تحويل عناوين IP';
  static const String toolHeaders = 'فحص ترويسات HTTP';
  static const String toolSsl = 'فحص شهادة SSL';
  static const String toolHeatmap = 'الخريطة الحرارية';
  static const String toolSiteSurvey = 'مسح الموقع';
  static const String toolWardriving = 'Wardriving';
  static const String toolPacketCapture = 'التقاط الحزم';
  static const String toolProtocolAnalyzer = 'محلل البروتوكولات';
  static const String toolMitmDetection = 'كشف هجمات الوسيط';
  static const String targetHost = 'الهدف (IP أو نطاق)';

  // ── الخط الزمني والخريطة الحرارية ───────────────────────────
  static const String activityTimeline = 'الخط الزمني للنشاط';
  static const String timelineEmpty = 'لا أحداث بعد — ستنتهي هنا جميع تنبيهات الأمان ونتائج الاختبارات.';

  // ── الإعدادات ────────────────────────────────────────────────
  static const String settingsAppearance = 'المظهر';
  static const String settingsThemeDark = 'الوضع الداكن';
  static const String settingsThemeLight = 'الوضع الفاتح';
  static const String settingsThemeSystem = 'حسب النظام';
  static const String settingsSecurity = 'الأمان';
  static const String settingsAppLock = 'قفل التطبيق (بصمة/وجه)';
  static const String settingsEncryptedBackup = 'نسخة احتياطية مشفرة';
  static const String settingsMonitoring = 'المراقبة';
  static const String settingsBackgroundScan = 'الفحص في الخلفية';
  static const String settingsNewDeviceAlert = 'تنبيه عند جهاز جديد';
  static const String settingsIntegrations = 'التكاملات';
  static const String settingsWigleToken = 'مفتاح WiGLE API';
  static const String settingsAbout = 'عن التطبيق';
  static const String settingsVersion = 'الإصدار';

  // ── حالات فارغة وأخطاء ───────────────────────────────────────
  static const String emptyDevices = 'لا أجهزة بعد — ابدأ بفحص الشبكة';
  static const String emptyAlerts = 'لا تنبيهات — شبكتك تبدو آمنة';
  static const String emptyResults = 'لا توجد نتائج';
  static const String errorGeneric = 'حدث خطأ ما. حاول مرة أخرى.';
  static const String errorNetwork = 'تعذّر الاتصال بالشبكة.';
  static const String errorPermission = 'الصلاحية مطلوبة للمتابعة.';
}
