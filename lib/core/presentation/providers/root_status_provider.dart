import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/root_checker_channel.dart';
import '../../platform/root_checker.dart';
import '../../platform/root_status.dart';

/// حالة فحص صلاحيات الجذر للواجهة.
///
/// تبدأ «غير معروفة» حتى يُستدعى الفحص، وتبقى النتيجة محفوظة
/// طوال عمر التطبيق لأنها لا تتغيّر أثناء التشغيل.
class RootStatusNotifier extends StateNotifier<RootStatus> {
  RootStatusNotifier(this._checker)
      : super(const RootStatus(state: RootState.unknown));

  final RootChecker _checker;

  Future<RootStatus> check() async {
    state = RootStatus.checking();
    final result = await _checker.check();
    state = result;
    return result;
  }
}

final rootStatusProvider =
    StateNotifierProvider<RootStatusNotifier, RootStatus>(
  (ref) => RootStatusNotifier(ref.watch(rootCheckerProvider)),
);
