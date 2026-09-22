import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../utils/app_logger.dart';

/// خدمة الإشعارات المحلية.
///
/// تُستخدم للتنبيهات الأمنية الفورية (دخيل جديد، انقطاع الشبكة،
/// هجوم محتمل). تهيّأ مرة واحدة عند الإقلاع، وتُربط بقنوات
/// Android المصنّفة حسب الأهمية.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelSecurity = 'security_alerts';
  static const String _channelNetwork = 'network_events';
  static const String _channelMonitor = 'monitoring';

  Future<void> init() async {
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    try {
      await _plugin.initialize(settings);

      // قناة الأمان: أهمية قصوى مع صوت واهتزاز للتهديدات الحرجة.
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelSecurity,
              'تنبيهات الأمان',
              description: 'تهديدات شبكية وأجهزة دخيلة',
              importance: Importance.max,
            ),
          );

      // قناة أحداث الشبكة: أهمية عالية.
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelNetwork,
              'أحداث الشبكة',
              description: 'انقطاع وعودة الاتصال',
              importance: Importance.high,
            ),
          );

      // قناة المراقبة: منخفضة (إشعارات خدمة الخلفية).
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelMonitor,
              'المراقبة المستمرة',
              description: 'حالة المراقبة في الخلفية',
              importance: Importance.low,
            ),
          );

      AppLogger.info('تهيأت خدمة الإشعارات', tag: 'Notifications');
    } catch (e, st) {
      AppLogger.warning('فشلت تهيئة الإشعارات', error: e, stackTrace: st);
    }
  }

  /// طلب صلاحية الإشعارات (Android 13+/iOS) بصمت إن رُفضت.
  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? true;
    } catch (e) {
      AppLogger.warning('تعذّر طلب صلاحية الإشعارات', error: e);
      return false;
    }
  }

  /// تنبيه أمني (دخيل/تهديد).
  Future<void> showSecurityAlert({
    required String title,
    required String body,
  }) =>
      _show(
        id: _nextId(),
        title: title,
        body: body,
        channelId: _channelSecurity,
        channelName: 'تنبيهات الأمان',
      );

  /// حدث شبكة (انقطاع/عودة).
  Future<void> showNetworkEvent({required String title, required String body}) =>
      _show(
        id: _nextId(),
        title: title,
        body: body,
        channelId: _channelNetwork,
        channelName: 'أحداث الشبكة',
      );

  /// إشعار دائم لخدمة المراقبة في الخلفية.
  Future<void> showPersistentMonitor({required String body}) => _show(
        id: 1000,
        title: AppStrings.appName,
        body: body,
        channelId: _channelMonitor,
        channelName: 'المراقبة المستمرة',
        ongoing: true,
      );

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    bool ongoing = false,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            ongoing: ongoing,
            autoCancel: !ongoing,
            priority: Priority.high,
            importance: ongoing ? Importance.low : Importance.max,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      AppLogger.warning('فشل عرض الإشعار', error: e);
    }
  }

  int _counter = 100;
  int _nextId() => _counter++;
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(FlutterLocalNotificationsPlugin()),
);
