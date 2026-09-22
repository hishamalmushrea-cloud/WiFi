import 'package:flutter/widgets.dart';

import '../../constants/app_constants.dart';

/// فئات الشاشات حسب نقاط التوقف في مواصفات التصميم.
enum Breakpoint { mobile, tablet, desktop }

/// غلاف متجاوب يبني ويدجت مختلفاً حسب عرض الشاشة.
///
/// الاستخدام:
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileView(),
///   tablet: TabletView(),   // اختياري — يرجع للجوال إن غاب
///   desktop: DesktopView(), // اختياري — يرجع للتابلت/الجوال إن غاب
/// )
/// ```
/// الاعتماد على LayoutBuilder (لا MediaQuery فقط) يضمن صحّة
/// التخطيط داخل لوحات مقسّمة ونوافذ الديسكتوب المتغيرة الحجم.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  /// يصنّف العرض الحالي إلى فئة الشاشة.
  static Breakpoint breakpointOf(double width) {
    if (width >= AppConstants.breakpointTablet) return Breakpoint.desktop;
    if (width >= AppConstants.breakpointMobile) return Breakpoint.tablet;
    return Breakpoint.mobile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // نستخدم أقصى عرض فعلي متاح للويدجت لا عرض الشاشة كله،
        // فيعمل التصنيف صحيحاً داخل الحاويات المقسّمة أيضاً.
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return switch (breakpointOf(width)) {
          Breakpoint.desktop => desktop ?? tablet ?? mobile,
          Breakpoint.tablet => tablet ?? mobile,
          Breakpoint.mobile => mobile,
        };
      },
    );
  }
}

/// حاوية تضبط عدد أعمدة شبكة ديناميكياً حسب فئة الشاشة.
///
/// بدل تكرار صيغة GridView في كل شاشة، نوحد هنا:
///  - جوال: عمودان، تابلت: 3، ديسكتوب: 5 (حسب المواصفات)
///  - أقصى عرض للمحتوى موسّط على الشاشات الكبيرة.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileColumns = AppConstants.mobileGridColumns,
    this.tabletColumns = AppConstants.tabletGridColumns,
    this.desktopColumns = AppConstants.desktopGridColumns,
    this.spacing = 16,
    this.aspectRatio = 1.0,
    this.padding,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double aspectRatio;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = ResponsiveLayout.breakpointOf(constraints.maxWidth);
        final columns = switch (bp) {
          Breakpoint.desktop => desktopColumns,
          Breakpoint.tablet => tabletColumns,
          Breakpoint.mobile => mobileColumns,
        };
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
