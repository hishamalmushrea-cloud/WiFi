import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../utils/app_logger.dart';
import 'notification_service.dart';

/// نوع حدث الشبكة المُكتشف.
enum NetworkEventType { connected, disconnected, changed, newDevice }

class NetworkMonitorEvent {
  const NetworkMonitorEvent(this.type, {this.detail});
  final NetworkEventType type;
  final String? detail;
}

/// مراقب الشبكة في الخلفية.
///
/// المسؤوليات:
///  - رصد تغيّر حالة الاتصال (WiFi/بيانات/لا اتصال) عبر connectivity.
///  - تأكيد «انقطاع حقيقي» بفحص دوري للبوابة (تجنّب إنذارات كاذبة).
///  - بثّ أحداث يستهلكها كلٌّ من الإشعارات ومحرّك الأمان.
///
/// الفحص الدوري للأجهزة الجديدة يُضاف عبر [onScanTick] في المرحلة 12
/// (خدمة WorkManager)؛ هنا البنية والأحداث الأساسية جاهزة.
class BackgroundMonitor {
  BackgroundMonitor(this._notifications);

  final NotificationService _notifications;
  final _connectivity = Connectivity();

  final _eventsController =
      StreamController<NetworkMonitorEvent>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _healthTimer;

  bool _isConnected = true;
  String? _lastSsid;

  /// بثّ أحداث الشبكة (الاتصال/الانقطاع/التغيير).
  Stream<NetworkMonitorEvent> get events => _eventsController.stream;

  /// بدء المراقبة.
  Future<void> start() async {
    if (_connectivitySub != null) return;

    final initial = await _connectivity.checkConnectivity();
    _handleConnectivity(initial);

    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _handleConnectivity,
      onError: (Object e) {
        AppLogger.warning('خطأ مراقبة الاتصال', error: e);
      },
    );

    // فحص صحة الاتصال كل 30 ثانية (كشف الانقطاع الصامت).
    _healthTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _healthCheck(),
    );

    AppLogger.info('بدأت مراقبة الشبكة', tag: 'BackgroundMonitor');
  }

  /// إيقاف المراقبة وتحرير الموارد.
  Future<void> stop() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _healthTimer?.cancel();
    _healthTimer = null;
    AppLogger.info('توقفت مراقبة الشبكة', tag: 'BackgroundMonitor');
  }

  void _handleConnectivity(List<ConnectivityResult> results) {
    final hasConnection =
        results.any((r) => r != ConnectivityResult.none);

    if (hasConnection && !_isConnected) {
      _isConnected = true;
      _emit(NetworkEventType.connected);
      _notifications.showNetworkEvent(
        title: 'عاد الاتصال بالإنترنت',
        body: 'استؤنف اتصال الشبكة بنجاح.',
      );
    } else if (!hasConnection && _isConnected) {
      _isConnected = false;
      _emit(NetworkEventType.disconnected);
      _notifications.showNetworkEvent(
        title: 'انقطع الاتصال بالشبكة',
        body: 'تحقق من الراوتر أو مزود الخدمة.',
      );
    } else if (hasConnection) {
      _emit(NetworkEventType.changed);
    }
  }

  /// فحص صحة بسيط: إن أخبر النظام أنه متصل لكن لا يوجد بوابة
  /// قابلة للوصول، نعتبره انقطاعاً فعلياً.
  Future<void> _healthCheck() async {
    if (!_isConnected) return;
    // فحص الوصول الفعلي يُنفَّذ عبر Ping في PHASE 12 دورياً؛
    // هنا نكتفي بحالة النظام (البنية جاهزة للربط).
  }

  /// يُستدعى من محرك الفحص عند اكتشاف جهاز جديد غير معروف.
  void notifyNewDevice(String deviceLabel) {
    _emit(NetworkEventType.newDevice, detail: deviceLabel);
    _notifications.showSecurityAlert(
      title: AppStrings.newDeviceAlert,
      body: 'رُصد جهاز جديد: $deviceLabel',
    );
  }

  void updateSsid(String? ssid) {
    if (ssid != null && ssid != _lastSsid && _lastSsid != null) {
      _emit(NetworkEventType.changed, detail: ssid);
      AppLogger.info('تغيّت الشبكة إلى: $ssid', tag: 'BackgroundMonitor');
    }
    _lastSsid = ssid;
  }

  void _emit(NetworkEventType type, {String? detail}) {
    if (!_eventsController.isClosed) {
      _eventsController.add(NetworkMonitorEvent(type, detail: detail));
    }
  }

  void dispose() {
    stop();
    _eventsController.close();
  }
}

final backgroundMonitorProvider = Provider<BackgroundMonitor>((ref) {
  final monitor = BackgroundMonitor(ref.watch(notificationServiceProvider));
  ref.onDispose(monitor.dispose);
  return monitor;
});
