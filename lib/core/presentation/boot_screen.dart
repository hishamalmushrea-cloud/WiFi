import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../localization/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// شاشة إقلاع مؤقتة (مؤشر على اكتمال الإعداد).
///
/// ⚠️ هذه الشاشة البسيطة مؤقتة فقط لضمان أن المشروع يُبنى ويعمل
/// بعد PHASE 1. ستُستبدل بشاشة Splash متحركة كاملة (Lottie + لوجو)
/// ثم Onboarding ثم Root Check ضمن PHASE 8.
class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // شعار مؤقت: عقدة شبكة داخل دائرة متوهجة
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.glowPrimary,
                          blurRadius: AppColors.glowBlur,
                          spreadRadius: AppColors.glowSpread,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.appTagline,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppStrings.splashInitializing,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: AppSpacing.huge),
                  Text(
                    'الإصدار ${AppConstants.appVersion}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.darkTextTertiary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
