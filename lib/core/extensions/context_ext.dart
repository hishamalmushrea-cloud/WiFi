import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_spacing.dart';

/// امتدادات على [BuildContext] لاختصار الوصول للثيم والتخطيط.
///
/// السبب: تُستخدم في كل الويدجتس تقريباً؛ اختصارها يقلّل التكرار
/// ويجعل قراءة الويدجت أنظف، مع بقاء المنطق في طبقة العرض فقط.
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// هل العرض ضمن فئة الجوال؟
  bool get isMobile => screenSize.width < AppConstants.breakpointMobile;

  /// هل العرض ضمن فئة التابلت؟
  bool get isTablet =>
      screenSize.width >= AppConstants.breakpointMobile &&
      screenSize.width < AppConstants.breakpointTablet;

  /// هل العرض فئة الديسكتوب (الشاشات الكبيرة)؟
  bool get isDesktop => screenSize.width >= AppConstants.breakpointTablet;

  /// عدد أعمدة الشبكة حسب عرض الشاشة — يطبّق قواعد التصميم المتجاوب.
  int get gridColumns {
    if (isDesktop) return AppConstants.desktopGridColumns;
    if (isTablet) return AppConstants.tabletGridColumns;
    return AppConstants.mobileGridColumns;
  }

  /// مساحة أفقية متجاوبة تضيق على الجوال وتتسع على الشاشات الكبيرة.
  EdgeInsets get responsivePadding => EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
        vertical: AppSpacing.lg,
      );
}
