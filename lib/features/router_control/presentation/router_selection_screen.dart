import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/router.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/common_ui.dart';
import '../../../core/presentation/widgets/interactive_glass_card.dart';
import '../../../core/presentation/widgets/responsive_layout.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'router_dashboard_page.dart';
import 'router_providers.dart';

/// شاشة اختيار نوع الراوتر والاتصال به.
///
/// شبكة متجاوبة بكل الماركات مع «اكتشاف تلقائي»، ثم نموذج
/// اتصال (IP/مستخدم/كلمة مرور) يستدعي RouterNotifier.
class RouterSelectionScreen extends ConsumerWidget {
  const RouterSelectionScreen({super.key});

  static const _brands = <(RouterBrand, String, IconData)>[
    (RouterBrand.tpLink, 'TP-Link', Icons.router_rounded),
    (RouterBrand.dLink, 'D-Link', Icons.router_rounded),
    (RouterBrand.huawei, 'Huawei', Icons.router_rounded),
    (RouterBrand.xiaomi, 'Xiaomi', Icons.router_rounded),
    (RouterBrand.cisco, 'Cisco', Icons.business_rounded),
    (RouterBrand.asus, 'ASUS', Icons.router_rounded),
    (RouterBrand.netgear, 'NETGEAR', Icons.router_rounded),
    (RouterBrand.zte, 'ZTE', Icons.router_rounded),
    (RouterBrand.tenda, 'Tenda', Icons.router_rounded),
    (RouterBrand.generic, AppStrings.general, Icons.help_outline_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerState = ref.watch(routerProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text(AppStrings.routerSelection)),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bp = ResponsiveLayout.breakpointOf(constraints.maxWidth);
              final columns = switch (bp) {
                Breakpoint.desktop => 5,
                Breakpoint.tablet => 4,
                Breakpoint.mobile => 3,
              };
              return SingleChildScrollView(
                padding: context.responsivePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // زر الاكتشاف التلقائي.
                    InteractiveGlassCard(
                      gradient: AppColors.gradientAccent,
                      glowColor: AppColors.glowAccent,
                      onTap: () => _showConnectSheet(context, ref, null),
                      child: Row(
                        children: [
                          const Icon(Icons.travel_explore_rounded,
                              color: Colors.white, size: 32),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.routerAutoDetect,
                                    style: context.textTheme.titleMedium
                                        ?.copyWith(color: Colors.white)),
                                Text(AppStrings.autoDetectNote,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(color: Colors.white70)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded,
                              color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(title: AppStrings.chooseBrand),
                    const SizedBox(height: AppSpacing.lg),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _brands.length,
                      itemBuilder: (context, i) {
                        final (brand, name, icon) = _brands[i];
                        return InteractiveGlassCard(
                          onTap: routerState.phase ==
                                  RouterConnectionPhase.connecting
                              ? null
                              : () => _showConnectSheet(context, ref, brand),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: AppColors.primary, size: 30),
                              const SizedBox(height: AppSpacing.sm),
                              Text(name,
                                  style: context.textTheme.titleSmall,
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        );
                      },
                    ),
                    if (routerState.phase == RouterConnectionPhase.connected)
                      _ConnectedBanner(info: routerState.info!),
                    if (routerState.error != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      ErrorView(
                        message: routerState.error,
                        onRetry: () {},
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showConnectSheet(
    BuildContext context,
    WidgetRef ref,
    RouterBrand? brand,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _ConnectSheet(brand: brand),
    );
  }
}

class _ConnectedBanner extends StatelessWidget {
  const _ConnectedBanner({required this.info});
  final RouterInfo info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: GlassCard(
        glowColor: AppColors.glowPrimary,
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.routerConnected,
                      style: context.textTheme.titleSmall),
                  Text('${info.brand.name} • ${info.ip}',
                      style: context.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectSheet extends ConsumerStatefulWidget {
  const _ConnectSheet({this.brand});
  final RouterBrand? brand;

  @override
  ConsumerState<_ConnectSheet> createState() => _ConnectSheetState();
}

class _ConnectSheetState extends ConsumerState<_ConnectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _ip = TextEditingController(text: '192.168.1.1');
  final _username = TextEditingController(text: 'admin');
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ip.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    // نلتقط الـ Navigator قبل إغلاق الورقة لأن context المرتبط بها
    // يصبح غير صالح بعد pop.
    final navigator = Navigator.of(context);

    final ok = await ref.read(routerProvider.notifier).connect(
          ip: _ip.text.trim(),
          username: _username.text.trim(),
          password: _password.text,
          brand: widget.brand,
        );

    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      navigator.pop(); // إغلاق ورقة الاتصال
      // ننتقل للوحة التحكم بعد الاتصال الناجح.
      navigator.push(
        MaterialPageRoute(builder: (_) => const RouterDashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _busy,
      message: AppStrings.routerConnect,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.brand == null
                    ? AppStrings.routerAutoDetect
                    : AppStrings.connectingTo(widget.brand!.name),
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _ip,
                decoration: const InputDecoration(
                  labelText: AppStrings.routerIp,
                  prefixIcon: Icon(Icons.lan_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? AppStrings.requiredField : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: AppStrings.routerUsername,
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.routerPassword,
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? AppStrings.requiredField : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _busy ? null : _connect,
                child: const Text(AppStrings.routerConnect),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
