import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/notification_service.dart';
import '../../services/permission_service.dart';
import '../../utils/app_logger.dart';
import 'root_status_provider.dart';

/// نتيجة تهيئة الإقلاع.
class BootstrapResult {
  const BootstrapResult({
    required this.notificationsReady,
    required this.rootStatusKnown,
  });
  final bool notificationsReady;
  final bool rootStatusKnown;
}

/// تهيئة التطبيق عند الإقلاع.
///
/// تشغّل كل ما يلزم قبل عرض اللوحة: الإشعارات، فحص Root،
/// وطلب الصلاحيات الأساسية بصمت (لا نُجبر المستخدم هنا — شاشة
/// الصلاحيات المخصصة تعرض التفاصيل في PHASE 8).
final appBootstrapProvider = FutureProvider<BootstrapResult>((ref) async {
  var notificationsReady = false;
  var rootKnown = false;

  try {
    final notifications = ref.watch(notificationServiceProvider);
    await notifications.init();
    notificationsReady = true;
  } catch (e) {
    AppLogger.warning('تعذّرت تهيئة الإشعارات عند الإقلاع', error: e);
  }

  try {
    // فحص حالة Root (لا يرمي أبداً — يعيد unknown عند التعذّر).
    await ref.read(rootStatusProvider.notifier).check();
    rootKnown = true;
  } catch (e) {
    AppLogger.warning('تعذّر فحص Root عند الإقلاع', error: e);
  }

  // نطلب صلاحية الإشعارات فقط بهدوء؛ البقية تُطلب في سياقها.
  try {
    final permissions = ref.read(permissionServiceProvider);
    await permissions.request(Permission.notification);
  } catch (_) {}

  AppLogger.info('اكتملت تهيئة الإقلاع', tag: 'Bootstrap');
  return BootstrapResult(
    notificationsReady: notificationsReady,
    rootStatusKnown: rootKnown,
  );
});
