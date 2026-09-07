import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/router.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'router_providers.dart';

/// لوحة تحكم الراوتر بعد الاتصال: إحصائيات، عملاء، إعدادات واي فاي،
/// شبكة ضيوف، توجيه منافذ، وتصفية MAC.
class RouterDashboardPage extends ConsumerWidget {
  const RouterDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerState = ref.watch(routerProvider);

    if (!routerState.isConnected) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text(AppStrings.routerDashboard)),
          body: const EmptyState(
            icon: Icons.router_rounded,
            title: 'غير متصل بالراوتر',
            message: 'اتصل بالراوتر أولاً من شاشة الاختيار.',
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 6,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(routerState.info?.ip ?? AppStrings.routerDashboard),
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(icon: Icon(Icons.dashboard_rounded), text: 'نظرة عامة'),
                Tab(icon: Icon(Icons.people_alt_rounded), text: 'العملاء'),
                Tab(icon: Icon(Icons.wifi_rounded), text: 'الواي فاي'),
                Tab(icon: Icon(Icons.guest_rounded) , text: 'الضيوف'),
                Tab(icon: Icon(Icons.alt_route_rounded), text: 'المنافذ'),
                Tab(icon: Icon(Icons.filter_alt_rounded), text: 'تصفية MAC'),
              ],
            ),
          ),
          body: const SafeArea(
            child: TabBarView(
              children: [
                _OverviewTab(),
                _ClientsTab(),
                _WifiSettingsTab(),
                _GuestNetworkTab(),
                _PortForwardTab(),
                _MacFilterTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── نظرة عامة ─────────────────────────
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(routerStatsProvider);
    final routerState = ref.watch(routerProvider);

    return ListView(
      padding: context.responsivePadding,
      children: [
        GlassCard(
          glowColor: AppColors.glowPrimary,
          child: Column(
            children: [
              Icon(Icons.router_rounded,
                  size: 48, color: AppColors.primary),
              const SizedBox(height: AppSpacing.sm),
              Text('متصل: ${routerState.info?.brand.name ?? ""}',
                  style: context.textTheme.titleMedium),
              Text(routerState.info?.model ?? routerState.info!.ip,
                  style: context.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        stats.when(
          loading: () => const ShimmerCard(),
          error: (e, _) => const Text('تعذّرت قراءة الإحصائيات'),
          data: (s) {
            final st = s ?? const RouterTrafficStats();
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _StatBox(
                        icon: Icons.people_alt_rounded,
                        value: '${st.connectedClients}',
                        label: 'عميل متصل')),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _StatBox(
                        icon: Icons.schedule_rounded,
                        value: '${(st.uptimeSeconds / 3600).toStringAsFixed(0)}س',
                        label: 'مدة التشغيل')),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: _StatBox(
                        icon: Icons.download_rounded,
                        value: '${st.totalDownloadKbps ~/ 1024}',
                        label: 'تنزيل (Mbps)')),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _StatBox(
                        icon: Icons.upload_rounded,
                        value: '${st.totalUploadKbps ~/ 1024}',
                        label: 'رفع (Mbps)')),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
          onPressed: () async {
            final confirm = await _confirm(
              context,
              'إعادة تشغيل الراوتر',
              'سيُعاد تشغيل الراوتر وقد ينقطع الاتصال لدقيقة. متابعة؟',
            );
            if (confirm == true) {
              await ref.read(routerRepositoryProvider).reboot();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('أُرسل أمر إعادة التشغيل')),
                );
              }
            }
          },
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text(AppStrings.routerReboot),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: () async {
            final confirm = await _confirm(
              context,
              AppStrings.routerFactoryReset,
              AppStrings.routerFactoryResetWarn,
            );
            if (confirm == true) {
              await ref.read(routerRepositoryProvider).factoryReset();
            }
          },
          icon: const Icon(Icons.restore_rounded),
          label: const Text(AppStrings.routerFactoryReset),
        ),
      ],
    );
  }
}

// ───────────────────────── العملاء ─────────────────────────
class _ClientsTab extends ConsumerWidget {
  const _ClientsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(routerClientsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(routerClientsProvider),
      child: clients.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: const [
          EmptyState(icon: Icons.people_alt_rounded, title: 'تعذّر جلب العملاء')
        ]),
        data: (list) {
          if (list.isEmpty) {
            return ListView(children: const [
              EmptyState(
                  icon: Icons.people_alt_rounded,
                  title: 'لا عملاء',
                  message: 'لم يُعثر على عملاء من واجهة الراوتر.')
            ]);
          }
          return ListView.separated(
            padding: context.responsivePadding,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final c = list[i];
              return GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.devices_other_rounded,
                        color: AppColors.accent),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name.isEmpty ? c.mac : c.name,
                              style: context.textTheme.titleSmall),
                          Text('${c.ip} • ${c.mac}',
                              style: context.textTheme.labelSmall),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.deviceBlock,
                      icon: const Icon(Icons.block_rounded,
                          color: AppColors.error),
                      onPressed: () async {
                        await ref
                            .read(routerRepositoryProvider)
                            .blockDevice(c.mac);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────── إعدادات الواي فاي ───────────────────────
class _WifiSettingsTab extends ConsumerStatefulWidget {
  const _WifiSettingsTab();
  @override
  ConsumerState<_WifiSettingsTab> createState() => _WifiSettingsTabState();
}

class _WifiSettingsTabState extends ConsumerState<_WifiSettingsTab> {
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  int _channel = 6;
  bool _loaded = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(routerWifiSettingsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const EmptyState(
          icon: Icons.wifi_rounded, title: 'تعذّرت قراءة إعدادات الواي فاي'),
      data: (settings) {
        if (settings != null && !_loaded && settings.ssid.isNotEmpty) {
          _ssid.text = settings.ssid;
          _password.text = settings.password;
          _channel = settings.channel;
          _loaded = true;
        }
        return ListView(
          padding: context.responsivePadding,
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _ssid,
                    decoration:
                        const InputDecoration(labelText: 'اسم الشبكة (SSID)'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'كلمة المرور'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('القناة: $_channel',
                      style: context.textTheme.titleSmall),
                  Slider(
                    value: _channel.toDouble().clamp(1, 13),
                    min: 1,
                    max: 13,
                    divisions: 12,
                    label: '$_channel',
                    onChanged: (v) => setState(() => _channel = v.toInt()),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              await ref
                                  .read(routerRepositoryProvider)
                                  .setWifiSettings(RouterWifiSettings(
                                    ssid: _ssid.text.trim(),
                                    password: _password.text,
                                    channel: _channel,
                                  ));
                              if (context.mounted) setState(() => _saving = false);
                            },
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded),
                      label: const Text(AppStrings.save),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ───────────────────────── شبكة الضيوف ─────────────────────────
class _GuestNetworkTab extends ConsumerStatefulWidget {
  const _GuestNetworkTab();
  @override
  ConsumerState<_GuestNetworkTab> createState() => _GuestNetworkTabState();
}

class _GuestNetworkTabState extends ConsumerState<_GuestNetworkTab> {
  bool _enabled = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: context.responsivePadding,
      children: [
        GlassCard(
          child: Column(
            children: [
              SwitchListTile(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                title: const Text('تفعيل شبكة الضيوف'),
                secondary: const Icon(Icons.guest_rounded,
                    color: AppColors.accent),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('عزل الضيوف عن الشبكة الداخلية'),
                subtitle: const Text('لا يستطيع الضيوف رؤية أجهزتك'),
                trailing: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          await ref
                              .read(routerRepositoryProvider)
                              .setGuestNetwork(GuestNetwork(
                                ssid: 'Guest',
                                password: '',
                                isEnabled: _enabled,
                              ));
                          if (context.mounted) setState(() => _saving = false);
                        },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(AppStrings.save),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── توجيه المنافذ ─────────────────────────
class _PortForwardTab extends ConsumerWidget {
  const _PortForwardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: context.responsivePadding,
      children: const [
        GlassCard(
          child: Row(
            children: [
              Icon(Icons.alt_route_rounded, color: AppColors.primary),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'قواعد توجيه المنافذ تُقرأ من الراوتر عند الاتصال بواجهة تدعمها. '
                  'الماركات المدعومة بنمط JSON ستظهر قواعدها هنا تلقائياً.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── تصفية MAC ─────────────────────────
class _MacFilterTab extends ConsumerWidget {
  const _MacFilterTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: context.responsivePadding,
      children: const [
        GlassCard(
          child: Row(
            children: [
              Icon(Icons.filter_alt_rounded, color: AppColors.primary),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'قوائم السماح/الحظر تُدار عبر واجهة الراوتر. '
                  'يمكنك أيضاً حظر الأجهزة من تبويب «العملاء» أو من صفحة الجهاز.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: context.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: context.textTheme.labelSmall),
        ],
      ),
    );
  }
}

Future<bool?> _confirm(BuildContext context, String title, String body) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel)),
        FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.confirm)),
      ],
    ),
  );
}
