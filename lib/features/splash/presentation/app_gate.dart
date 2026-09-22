import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/providers/app_bootstrap_provider.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../permissions/presentation/permissions_screen.dart';
import '../../root_check/presentation/root_check_screen.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../shell/presentation/main_shell.dart';
import 'splash_screen.dart';

/// مرحلة تدفّق الإقلاع.
enum _GateStage { splash, onboarding, rootCheck, permissions, app }

/// بوابة التطبيق: تنسّق التدفّق من الإقلاع إلى اللوحة الرئيسية.
///
/// الترتيب: تهيئة (Splash) → إن لم تُنجز Onboarding → فحص Root →
/// طلب الصلاحيات → الهيكل الرئيسي. تُحفظ التقدّمات في الإعدادات
/// فلا يُعرض التعريف/الفحص إلا في أول تشغيل (ما لم يطلب المستخدم).
class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  _GateStage _stage = _GateStage.splash;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // ننتظر اكتمال التهيئة ثم نقرر المرحلة الأولى.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // لا حاجة لمواصلة الانتظار إن وصل المستخدم بعده.
    await ref.read(appBootstrapProvider.future);
    if (!mounted) return;

    final settings = ref.read(settingsProvider);
    setState(() {
      _initialized = true;
      if (!settings.onboardingComplete) {
        _stage = _GateStage.onboarding;
      } else {
        // الفحص والصلاحيات تُعرض مرة واحدة قبل دخول التطبيق.
        _stage = _GateStage.rootCheck;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SplashScreen();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      child: switch (_stage) {
        _GateStage.splash => const SplashScreen(),
        _GateStage.onboarding => OnboardingScreen(
            key: const ValueKey('onboarding'),
            onComplete: () => setState(() => _stage = _GateStage.rootCheck),
          ),
        _GateStage.rootCheck => RootCheckScreen(
            key: const ValueKey('root'),
            onContinue: () =>
                setState(() => _stage = _GateStage.permissions),
          ),
        _GateStage.permissions => PermissionsScreen(
            key: const ValueKey('permissions'),
            onContinue: () => setState(() => _stage = _GateStage.app),
          ),
        _GateStage.app => const MainShell(key: ValueKey('app')),
      },
    );
  }
}
