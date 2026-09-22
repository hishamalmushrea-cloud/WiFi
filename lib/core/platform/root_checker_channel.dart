import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import 'root_checker.dart';
import 'root_status.dart';

/// كشف صلاحيات الجذر عبر الجسر الأصلي (Method Channel).
///
/// يتوافق مع التنفيذين القادمين في PHASE 11:
///  - Android (Kotlin): فحص تطبيقات Magisk/SuperSU، بحث عن su binary
///    في مسارات متعددة، test-keys في build tag، ومحاولة تنفيذ su.
///  - iOS (Swift): فحص Cydia/Sileo/Zebra/Filza، ملفات النظام،
///    محاولة الكتابة خارج الـ Sandbox، وفحص dylibs والـ Fork test.
///
/// حتى وصول الكود الأصلي، يعمل التطبيق دون انهيار: أي خطأ في
/// القناة (MissingPluginException) يُعالَج بحالة «غير معروف».
class MethodChannelRootChecker implements RootChecker {
  MethodChannelRootChecker(this._channel);

  final MethodChannel _channel;

  @override
  Future<RootStatus> check() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('detect');
      if (result == null) {
        return const RootStatus(state: RootState.unknown);
      }

      final isRooted = result['isRooted'] == true;
      return RootStatus(
        state: isRooted ? RootState.granted : RootState.notGranted,
        methods: List<String>.from(result['methods'] as List? ?? const []),
        evidence: List<String>.from(result['evidence'] as List? ?? const []),
      );
    } on MissingPluginException {
      // الكود الأصلي لم يُسجَّل بعد (PHASE 11) — نسير بالتدهور الآمن.
      AppLogger.warning(
        'قناة فحص Root غير مسجلة بعد — متابعة بافتراض عدم وجود Root',
        tag: 'RootChecker',
      );
      return const RootStatus(state: RootState.unknown);
    } on PlatformException catch (e, st) {
      AppLogger.error('فشل فحص Root عبر القناة', error: e, stackTrace: st);
      return const RootStatus(state: RootState.unknown);
    }
  }

  @override
  Future<bool> isRooted() async => check().then((s) => s.isRooted);
}

/// مزود قابل للحقن — الواجهة تعتمد عليه فتُختبر بسهولة،
/// ويُستبدل التنفيذ الأصلي تلقائياً عند اكتمال PHASE 11.
final rootCheckerProvider = Provider<RootChecker>(
  (ref) => MethodChannelRootChecker(
    const MethodChannel(AppConstants.channelRootCheck),
  ),
);
