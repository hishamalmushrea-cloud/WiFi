import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/app_logger.dart';

/// وصف صلاحية للعرض في شاشة الصلاحيات.
class PermissionRequirement {
  const PermissionRequirement({
    required this.permission,
    required this.title,
    required this.body,
    required this.requiredFor,
  });

  final Permission permission;
  final String title;
  final String body;
  final String requiredFor;
}

/// خدمة إدارة الصلاحيات مركزياً.
///
/// السبب: عدة ميزات تشارك نفس الصلاحيات (الموقع لمسح WiFi
/// وWardriving، البلوتوث للفحص، الإشعارات للتنبيهات). نوحد
/// الطلب والفحص هنا حتى لا يتكرر المنطق في الويدجتس.
class PermissionService {
  const PermissionService();

  /// كل الصلاحيات التي يحتاجها التطبيق مع وصفها للعرض.
  List<PermissionRequirement> get requirements => const [
        PermissionRequirement(
          permission: Permission.locationWhenInUse,
          title: 'الموقع الجغرافي',
          body: 'لتحليل شبكات الواي فاي وتسجيلها على الخريطة (قيود أندرويد).',
          requiredFor: 'تحليل WiFi، Wardriving، الخرائط الحرارية',
        ),
        PermissionRequirement(
          permission: Permission.bluetoothScan,
          title: 'فحص البلوتوث',
          body: 'لاكتشاف أجهزة بلوتوث وBLE القريبة.',
          requiredFor: 'فحص الأجهزة القريبة',
        ),
        PermissionRequirement(
          permission: Permission.notification,
          title: 'الإشعارات',
          body: 'تنبيهات الأمان والأجهزة الجديدة في شبكتك.',
          requiredFor: 'التنبيهات الأمنية الفورية',
        ),
        PermissionRequirement(
          permission: Permission.ignoreBatteryOptimizations,
          title: 'العمل في الخلفية',
          body: 'مراقبة مستمرة للشبكة وكشف الانقطاعات.',
          requiredFor: 'المراقبة المستمرة',
        ),
      ];

  /// هل الصلاحية ممنوحة حالياً؟
  Future<bool> isGranted(Permission permission) =>
      permission.isGranted;

  /// يطلب صلاحية ويعيد نتيجة المنح النهائية.
  Future<bool> request(Permission permission) async {
    try {
      final status = await permission.request();
      return status.isGranted;
    } catch (e) {
      AppLogger.warning('فشل طلب الصلاحية ${permission.toString()}', error: e);
      return false;
    }
  }

  /// يطلب صلاحيات أساسية دفعة واحدة (الموقع أولاً فهو الأهم).
  Future<Map<Permission, bool>> requestEssential() async {
    final results = <Permission, bool>{};
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.notification,
    ].request();
    statuses.forEach((permission, status) {
      results[permission] = status.isGranted;
    });
    return results;
  }

  /// هل منع المستخدم الصلاحية نهائياً (يحتاج فتح الإعدادات)؟
  Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// يفتح إعدادات التطبيق (عند المنع الدائم).
  Future<void> openAppSettingsScreen() => openAppSettings();
}

final permissionServiceProvider =
    Provider<PermissionService>((ref) => const PermissionService());
