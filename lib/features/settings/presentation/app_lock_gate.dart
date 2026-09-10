import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'settings_providers.dart';

/// بوابة قفل التطبيق — تغلّف المحتوى بالكامل وتظهر حاجزاً عند:
///  - بدء التشغيل والقفل مفعّل من الإعدادات.
///  - عودة التطبيق من الخلفية إلى المقدمة.
///
/// الخصوصية: المحتوى خلف الحاجز يُطمس بالكامل (BackdropFilter)
/// فلا يظهر أي محتوى حساس في قائمة التطبيقات الأخيرة.
///
/// حارس المصادقة: أثناء انتظار نافذة البصمة قد تتغير دورة حياة
/// التطبيق (paused→resumed على Android) — نتجاهل الأحداث حينها
/// حتى لا يُقفل التطبيق مجدداً لحظة نجاح المصادقة.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // بعد أول إطار: قفل إن كان مفعّلاً (الإعدادات تُقرأ من الذاكرة
    // لأن SharedPreferences هُيّئت قبل runApp).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLockFirstRun());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      // عودة حقيقية من الخلفية (وليست نافذة المصادقة) → أعد القفل.
      if (!_authenticating) _lockIfEnabled();
    }
  }

  Future<void> _maybeLockFirstRun() async {
    if (!mounted) return;
    _lockIfEnabled();

    // محاولة فتح تلقائية مباشرة عند الإقلاع (تجربة أسرع).
    if (_locked) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted && _locked) await _tryUnlock();
    }
  }

  void _lockIfEnabled() {
    final enabled = ref.read(settingsProvider).appLockEnabled;
    if (enabled && mounted && !_locked) {
      setState(() => _locked = true);
    } else if (enabled && !_locked) {
      _locked = true;
    }
  }

  Future<void> _tryUnlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final ok = await ref.read(appLockServiceProvider).authenticate();
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (ok) _locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // المحتوى دائماً مبني (يحفظ حالة التنقل) — الحاجز فوقه.
        widget.child,
        if (_locked) _buildBarrier(),
      ],
    );
  }

  Widget _buildBarrier() {
    return Positioned.fill(
      child: ExcludeSemantics(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: ColoredBox(
            // withOpacity بدل withValues — الثانية تتطلب Flutter 3.27+
            // بينما المشروع مثبّت على 3.24.5.
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.55),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_rounded,
                            color: Colors.white, size: 42),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        AppStrings.appLockTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppStrings.appLockHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: _authenticating ? null : _tryUnlock,
                        icon: _authenticating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.fingerprint_rounded),
                        label: Text(AppStrings.appLockUnlock),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
