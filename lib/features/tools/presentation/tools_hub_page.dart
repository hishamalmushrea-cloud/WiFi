import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/common_ui.dart';
import '../../../core/presentation/widgets/responsive_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'tools_pages.dart';

/// مركز أدوات الشبكة: شبكة متجاوبة بكل الأدوات المتاحة.
class ToolsHubPage extends ConsumerWidget {
  const ToolsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tools = <ToolData>[
      ToolData(Icons.wifi_tethering_rounded, AppStrings.toolPing,
          AppColors.gradientPrimary, AppColors.glowPrimary,
          () => _open(context, const PingToolPage())),
      ToolData(Icons.route_rounded, AppStrings.toolTraceroute,
          AppColors.gradientAccent, AppColors.glowAccent,
          () => _open(context, const TracerouteToolPage())),
      ToolData(Icons.manage_search_rounded, AppStrings.toolWhois,
          AppColors.gradientSuccess, AppColors.glowAccent,
          () => _open(context, const WhoisToolPage())),
      ToolData(Icons.dns_rounded, AppStrings.toolDns,
          AppColors.gradientWarning, AppColors.glowError,
          () => _open(context, const DnsToolPage())),
      ToolData(Icons.calculate_rounded, AppStrings.toolSubnet,
          AppColors.gradientPrimary, AppColors.glowPrimary,
          () => _open(context, const SubnetCalculatorPage())),
      ToolData(Icons.power_settings_new_rounded, AppStrings.toolWol,
          AppColors.gradientSuccess, AppColors.glowAccent,
          () => _comingSoon(context)),
      ToolData(Icons.business_rounded, AppStrings.toolMacVendor,
          AppColors.gradientAccent, AppColors.glowAccent,
          () => _open(context, const MacVendorToolPage())),
      ToolData(Icons.https_rounded, AppStrings.toolSsl,
          AppColors.gradientWarning, AppColors.glowError,
          () => _open(context, const SslToolPage())),
      ToolData(Icons.map_rounded, AppStrings.toolHeatmap,
          AppColors.gradientPrimary, AppColors.glowPrimary,
          () => _comingSoon(context)),
      ToolData(Icons.terrain_rounded, AppStrings.toolSiteSurvey,
          AppColors.gradientSuccess, AppColors.glowAccent,
          () => _comingSoon(context)),
      ToolData(Icons.directions_car_rounded, AppStrings.toolWardriving,
          AppColors.gradientAccent, AppColors.glowAccent,
          () => _comingSoon(context)),
      ToolData(Icons.bug_report_rounded, AppStrings.toolPacketCapture,
          AppColors.gradientWarning, AppColors.glowError,
          () => _comingSoon(context)),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text(AppStrings.toolsTitle)),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bp = ResponsiveLayout.breakpointOf(constraints.maxWidth);
            final columns = switch (bp) {
              Breakpoint.desktop => 5,
              Breakpoint.tablet => 4,
              Breakpoint.mobile => 3,
            };
            return GridView.builder(
              padding: context.responsivePadding.copyWith(bottom: 100),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.95,
              ),
              itemCount: tools.length,
              itemBuilder: (context, i) {
                final t = tools[i];
                return QuickActionTile(
                  icon: t.icon,
                  label: t.label,
                  gradient: t.gradient,
                  glowColor: t.glow,
                  onTap: t.onTap,
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تتطلب صلاحيات Root أو قيد التطوير')),
    );
  }
}

class ToolData {
  const ToolData(
      this.icon, this.label, this.gradient, this.glow, this.onTap);
  final IconData icon;
  final String label;
  final Gradient gradient;
  final Color glow;
  final VoidCallback onTap;
}
