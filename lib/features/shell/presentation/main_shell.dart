import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/modern_bottom_nav_bar.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/responsive_layout.dart';
import '../../devices/presentation/devices_page.dart';
import '../../home/presentation/home_dashboard.dart';
import '../../security/presentation/security_dashboard_page.dart';
import '../../tools/presentation/tools_hub_page.dart';
import '../../wifi_analysis/presentation/wifi_analysis_page.dart';

/// الهيكل الرئيسي: شريط تنقل سفلي زجاجي مع خمس صفحات.
///
/// نستخدم [IndexedStack] للحفاظ على حالة كل صفحة عند التبديل.
/// على الشاشات الكبيرة (ديسكتوب) يمكن لاحقاً إضافة NavigationRail
/// في نفس الملف دون تغيير الصفحات.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const <Widget>[
    HomeDashboard(),
    DevicesPage(),
    WifiAnalysisPage(),
    SecurityDashboardPage(),
    ToolsHubPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final items = <NavBarItem>[
      const NavBarItem(icon: Icons.dashboard_rounded, label: AppStrings.navHome),
      const NavBarItem(icon: Icons.devices_other_rounded, label: AppStrings.navNetwork),
      const NavBarItem(icon: Icons.wifi_rounded, label: AppStrings.navWifi),
      const NavBarItem(icon: Icons.security_rounded, label: AppStrings.navSecurity),
      const NavBarItem(icon: Icons.build_circle_outlined, label: AppStrings.navTools),
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: ResponsiveLayout(
          mobile: IndexedStack(index: _index, children: _pages),
          tablet: IndexedStack(index: _index, children: _pages),
          desktop: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: IndexedStack(index: _index, children: _pages),
            ),
          ),
        ),
        bottomNavigationBar: ModernBottomNavBar(
          currentIndex: _index,
          items: items,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
