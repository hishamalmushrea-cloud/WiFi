import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/theme/app_colors.dart';

/// شاشة الإقلاع: لوجو متحرك (تكبير + توهج نابض) مع شريط تقدّم.
///
/// تبقى مرئية أثناء [appBootstrapProvider] ثم ينتقل التدفق
/// للتعريف أو اللوحة الرئيسية (يُدار في AppGate).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // اللوجو النابض.
              AnimatedBuilder(
                animation: Listenable.merge([_logoController, _glowController]),
                builder: (context, _) {
                  final scale =
                      Curves.easeOutBack.transform(_logoController.value);
                  return Transform.scale(
                    scale: 0.6 + scale * 0.4,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.glowPrimary
                                .withOpacity(0.4 + _glowController.value * 0.4),
                            blurRadius: 30 + _glowController.value * 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.hub_rounded,
                          size: 64, color: Colors.white),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.appTagline,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.splashInitializing,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
