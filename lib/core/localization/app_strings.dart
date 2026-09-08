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

  // ── P12: نصوص موحّدة لكل الشاشات ─────────────────────────
  static const String hintPing = '8.8.8.8 أو example.com';
  static const String hintDns = 'example.com (سجل A)';
  static const String labelLastHost = 'آخر مضيف';
  static const String labelFirstHost = 'أول مضيف';
  static const String labelUsableHosts = 'المضيفون المتاحون';
  static const String labelMinAvgMax = 'أدنى / متوسط / أعلى';
  static const String labelSentReceived = 'أُرسل / استُلم';
  static const String labelPacketLoss = 'فقد الحزم';
  static const String labelQuery = 'الاستعلام';
  static const String labelCountry = 'الدولة';
  static const String labelRegistrar = 'جهة التسجيل';
  static const String labelHost = 'المضيف';
  static const String labelIssuer = 'المُصدِر';
  static const String labelValidTo = 'تنتهي في';
  static const String sslValid = 'سارية';
  static const String sslExpired = 'منتهية الصلاحية';
  static const String sslSelfSigned = 'موقّعة ذاتياً';
  static const String labelIpAddress = 'عنوان IP';
  static const String labelSubnetMask = 'قناع الشبكة';
  static const String labelNetworkAddress = 'عنوان الشبكة';
  static const String labelBroadcastAddress = 'عنوان البث';
  static const String labelPrefix = 'البادئة: /';
  static const String labelPortRange = 'نطاق المنافذ';
  static const String hintPortRange = 'مثال: 80,443,8000-8010';
  static const String labelPort = 'المنفذ';
  static const String scanCommonPorts = 'فحص المنافذ الشائعة';
  static const String enterTargetFirst = 'أدخل عنوان الهدف أولاً';
  static const String noOpenPorts = 'لا منافذ مفتوحة';
  static const String noOpenPortsHint = 'لم يُعثر على منافذ مفتوحة في النطاق المفحوص.';
  static const String advFtp = 'FTP ينقل كلمات المرور نصاً صريحاً';
  static const String advTelnet = 'Telnet غير مشفّر — استخدم SSH';
  static const String advSmb = 'SMB — تأكد من تحديث النظام وتعطيل SMBv1';
  static const String advRdp = 'RDP مكشوف — لا تعرضه على الشبكة العامة';
  static const String advVnc = 'VNC — قيّده بشبكة داخلية';
  static const String advRedis = 'Redis غالباً بلا مصادقة';
  static const String advMongo = 'MongoDB قد يكون بلا مصادقة';
  static const String wolWakeDevice = 'إيقاظ الجهاز';
  static const String wolMacLabel = 'عنوان MAC للجهاز';
  static const String wolBroadcastLabel = 'عنوان البث (Broadcast)';
  static const String wolSent = 'أُرسلت حزمة الإيقاظ بنجاح ✓';
  static const String networkMap = 'مخطط الشبكة';
  static const String scanGuides = 'أدلة الفحص';
  static const String speedDownload = 'تنزيل (Mbps)';
  static const String speedUpload = 'رفع (Mbps)';
  static const String speedNoHistory = 'لا اختبارات بعد — ابدأ اختباراً لعرض السجل.';
  static const String newSurvey = 'مسح جديد';
  static const String surveyNameTitle = 'اسم المسح / الموقع';
  static const String defaultSurveyName = 'مسح المنزل';
  static const String noSurveys = 'لا مسوحات بعد';
  static const String noSurveysHint = 'أنشئ مسحاً لموقع وتنقّل لقياس قوة الإشارة وبناء خريطة حرارية.';
  static const String samplesCount = 'نقطة قياس';
  static const String heatmapHint = 'انقر على الخريطة في أماكن وقوفك أثناء المسح لإضافة قياسات الإشارة.';
  static const String metricSamples = 'النقاط';
  static const String metricAvgSignal = 'متوسط الإشارة';
  static const String metricWeakest = 'أضعف نقطة';
  static const String pdfSaved = 'حُفظ التقرير: ';
  static const String mapStartRecording = 'ابدأ التسجيل لعرض الخريطة';
  static const String needsLocation = 'يتطلب صلاحية الموقع.';
  static const String recordingDots = 'جارٍ التسجيل…';
  static const String dropPoint = 'تسجيل نقطة';
  static const String statNetworks = 'شبكات';
  static const String statDistance = 'المسافة';
  static const String statOpen = 'مفتوحة';
  static const String unitKm = ' كم';
  static const String csvExported = 'صُدّر الملف: ';
  static const String stopCapture = 'إيقاف الالتقاط';
  static const String startCapture = 'بدء التقاط الحزم';
  static const String captureNotStarted = 'لم يبدأ الالتقاط';
  static const String captureNotStartedHint = 'اضغط بدء لمراقبة الحزم على الواجهة (يتطلب Root).';
  static const String captureNeedsRoot = 'الالتقاط المباشر يتطلب جهازاً بصلاحيات Root مع أداة tcpdump. ';
  static const String captureNeedsRoot2 = 'على الأجهزة غير المدعومة تتوفر بقية أدوات التحليل دون قيود.';
  static const String protocolDistribution = 'توزيع البروتوكولات المُلتقطة (إجمالي 100 حزمة)';
  static const String protocolHttpExposed = 'HTTP (مكشوف)';
  static const String httpExposedWarning = 'رُصد 3 حزم HTTP غير مشفّرة — بياناتها تنتقل نصاً صريحاً.';
  static const String mitmTitle = 'كشف هجمات الوسيط (MITM)';
  static const String mitmArpTitle = 'فحص بوابة ARP';
  static const String mitmArpDetail = 'عنوان MAC للبوابة ثابت — لا إعادة توجيه مزدوجة مكتشفة.';
  static const String mitwDnsTitle = 'سلوك DNS';
  static const String mitwDnsDetail = 'لا خوادم DNS دخيلة في تدفّق الاستعلامات.';
  static const String mitmTlsTitle = 'شهادات TLS';
  static const String mitmTlsDetail = 'الشهادات المتفاوض عليها موقّعة من جهات موثوقة.';
  static const String mitmProbeTitle = 'طلبات Probe';
  static const String mitmProbeDetail = 'يتطلب Root لرصد إطارات Probe-Request وكشف Karma/PineAP.';
  static const String noActivity = 'لا نشاط بعد';
  static const String noActivityHint = 'ستظهر هنا التنبيهات الأمنية واختبارات السرعة.';
  static const String tabOverview = 'نظرة عامة';
  static const String tabClients = 'العملاء';
  static const String tabWifi = 'الواي فاي';
  static const String tabGuests = 'الضيوف';
  static const String tabPorts = 'المنافذ';
  static const String tabMacFilter = 'تصفية MAC';
  static const String routerRebootSent = 'أُرسل أمر إعادة التشغيل';
  static const String routerRebootConfirm = 'سيُعاد تشغيل الراوتر وقد ينقطع الاتصال لدقيقة. متابعة؟';
  static const String routerUptime = 'مدة التشغيل';
  static const String routerNotConnected = 'غير متصل بالراوتر';
  static const String routerConnectFirst = 'اتصل بالراوتر أولاً من شاشة الاختيار.';
  static const String clientsLoadFailed = 'تعذّر جلب العملاء';
  static const String noClients = 'لا عملاء';
  static const String noClientsHint = 'لم يُعثر على عملاء من واجهة الراوتر.';
  static const String connectedClient = 'عميل متصل';
  static const String wifiSettingsReadFailed = 'تعذّرت قراءة إعدادات الواي فاي';
  static const String fieldSsid = 'اسم الشبكة (SSID)';
  static const String fieldPassword = 'كلمة المرور';
  static const String guestEnable = 'تفعيل شبكة الضيوف';
  static const String guestIsolation = 'عزل الضيوف عن الشبكة الداخلية';
  static const String guestIsolationHint = 'لا يستطيع الضيوف رؤية أجهزتك';
  static const String portForwardInfo = 'قواعد توجيه المنافذ تُقرأ من الراوتر عند الاتصال بواجهة تدعمها. ';
  static const String macFilterInfo = 'قوائم السماح/الحظر تُدار عبر واجهة الراوتر. ';
  static const String blockHint = 'يمكنك أيضاً حظر الأجهزة من تبويب «العملاء» أو من صفحة الجهاز.';
  static const String chooseBrand = 'اختر الماركة';
  static const String autoDetectNote = 'سنحاول تحديد نوع الراوتر تلقائياً';
  static const String brandRulesNote = 'الماركات المدعومة بنمط JSON ستظهر قواعدها هنا تلقائياً.';
  static const String securityChecks = 'فحوصات الأمان';
  static const String resolveAll = 'تعليم الكل كمعالَج';
  static const String runSecurityScan = 'إجراء فحص أمني';
  static const String noVulnerabilities = 'لا ثغرات مكتشفة على هذا الجهاز';
  static const String severityCritical = 'حرج';
  static const String actions = 'إجراءات';
  static const String randomMac = 'MAC عشوائي';
  static const String deviceSeenNote = 'سيُسجَّل ظهور الجهاز عبر الفحوصات القادمة';
  static const String rootStatusTitle = 'حالة Root / Jailbreak';
  static const String rootNotAvailable = 'غير متاحة — 96 ميزة أساسية تعمل';
  static const String rootStatusNone = 'الحالة: لا توجد صلاحيات Root';
  static const String rootRecheck = 'تعذّر الجزم — أعد الفحص';
  static const String featureAvailable = 'ميزة متاحة';
  static const String featureAdvanced = 'ميزة متقدمة';
  static const String comingSoonRoot = 'تتطلب صلاحيات Root أو قيد التطوير';
  static const String comingSoon = 'ستتوفر في التحديث القادم';
  static const String wigleKeySet = 'المفتاح مُعدّ ✓';
  static const String wigleKeyMissing = 'غير مُعدّ — أدخل مفتاح WiGLE API';
  static const String wigleKeyHint = 'Basic ... أو رمز WiGLE';
  static const String status = 'الحالة';
  static const String target = 'الهدف';
  static const String requiredField = 'مطلوب';
  static const String information = 'معلومات';
  static const String labelHistory = 'السجل';
  static const String noHistory = 'لا سجل بعد';
  static const String noHistoryAlt = 'لا يوجد سجل بعد';
  static const String noData = 'لا توجد بيانات';
  static const String connected = 'متصل';
  static const String disconnected = 'غير متصل';
  static const String ratingGood = 'جيد';
  static const String ratingGreat = 'ممتاز';
  static const String ratingWeak = 'ضعيف';
  static const String ratingMedium = 'متوسط';
  static const String general = 'عام';
  static const String viewAll = 'عرض الكل';
  static const String appVersion = 'الإصدار: 1.0.0';
  static const String bootstrapReady = 'اكتملت تهيئة الإقلاع';
  static const String bootstrapRootFailed = 'تعذّر فحص Root عند الإقلاع';
  static const String bootstrapNotifFailed = 'تعذّرت تهيئة الإشعارات عند الإقلاع';

  // ── P12: دوال تنسيق النصوص الديناميكية (تحتوي متغيرات) ────────
  // تُبقى كل العربية هنا حتى مع وجود أرقام/أسماء متغيرة.
  static String samplesCountN(int n) => '$n نقطة قياس';
  static String vulnerabilitiesFound(int n) => 'عُثر على $n تحذير أمني';
  static String devicesFound(int n) => 'عُثر على $n جهاز حتى الآن';
  static String scannedAddresses(int scanned, int total) =>
      'تم فحص $scanned من $total عنوان';
  static String scannedPorts(int done, int total) =>
      'فُحص $done من $total منفذ';
  static String knownPortsCount(int n) => '$n منفذ خدمة معروفة';
  static String scanProgress(int scanned, int total, int devices) =>
      '$scanned / $total • $devices جهاز';
  static String onlineOfTotal(int total) => 'من $total إجمالي';
  static String recordingPoints(int n) => 'جارٍ التسجيل • $n نقطة';
  static String distanceKm(double km) => '$km كم';
  static String fileExported(String path) => 'صُدّر الملف: $path';
  static String reportSaved(String path) => 'حُفظ التقرير: $path';
  static String connectedTo(String brand) => 'متصل: $brand';
  static String connectingTo(String brand) => 'الاتصال بـ $brand';
  static String requiredForLabel(String what) => 'لـ: $what';
  static String uptimeHours(String hours) => '${hours}س';
  static String channelLabel(int ch) => 'قناة $ch';
  static String channelNumber(int ch) => 'القناة: $ch';

  // ── نصوص متناثرة أخيرة ──────────────────────────────────────
  static const String routerLabel = 'الراوتر';
  static const String deviceUnfavorite = 'إزالة من المفضلة';
  static const String statsLoadFailed = 'تعذّرت قراءة الإحصائيات';
  static String prefixLabel(int prefix) => 'البادئة: /$prefix';
  static String searchHintDots(String label) => '$label… (IP, MAC, اسم)';
}
