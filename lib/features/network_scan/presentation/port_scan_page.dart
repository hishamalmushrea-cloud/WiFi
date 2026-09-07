import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/domain/entities/vulnerability.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/app_progress_bar.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/port_utils.dart';
import 'port_scan_providers.dart';

/// شاشة فحص المنافذ: هدف + إعدادات سريعة + نتائج لحظية + تحذيرات.
class PortScanPage extends ConsumerStatefulWidget {
  const PortScanPage({super.key});

  @override
  ConsumerState<PortScanPage> createState() => _PortScanPageState();
}

class _PortScanPageState extends ConsumerState<PortScanPage> {
  final _ipController = TextEditingController();
  final _portsController = TextEditingController();
  bool _commonOnly = true;

  // تحذيرات أمنية معروفة لمنافذ خطرة (تعرض inline).
  static const _advisories = <int, String>{
    23: 'Telnet غير مشفّر — استخدم SSH',
    21: 'FTP ينقل كلمات المرور نصاً صريحاً',
    445: 'SMB — تأكد من تحديث النظام وتعطيل SMBv1',
    3389: 'RDP مكشوف — لا تعرضه على الشبكة العامة',
    6379: 'Redis غالباً بلا مصادقة',
    27017: 'MongoDB قد يكون بلا مصادقة',
    5900: 'VNC — قيّده بشبكة داخلية',
  };

  @override
  void dispose() {
    _ipController.dispose();
    _portsController.dispose();
    super.dispose();
  }

  List<int> get _ports {
    if (_commonOnly) return PortUtils.commonPorts();
    final custom = PortUtils.parseRange(_portsController.text);
    return custom.isEmpty ? PortUtils.commonPorts() : custom;
  }

  Future<void> _scan() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عنوان الهدف أولاً')),
      );
      return Future.value();
    }
    return ref.read(portScanProvider.notifier).scan(ip, _ports);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portScanProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text(AppStrings.portScanTitle)),
        body: SafeArea(
          child: ListView(
            padding: context.responsivePadding,
            children: [
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: AppStrings.targetHost,
                  hintText: '192.168.1.1',
                  prefixIcon: Icon(Icons.lan_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                value: _commonOnly,
                onChanged: (v) => setState(() => _commonOnly = v),
                title: const Text('فحص المنافذ الشائعة'),
                subtitle: Text('${AppConstants.commonPorts.length} منفذ خدمة معروفة'),
              ),
              if (!_commonOnly)
                TextField(
                  controller: _portsController,
                  decoration: const InputDecoration(
                    labelText: 'نطاق المنافذ',
                    hintText: 'مثال: 80,443,8000-8010',
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: state.scanning ? null : _scan,
                icon: state.scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.radar_rounded),
                label: Text(state.scanning
                    ? AppStrings.scanning
                    : AppStrings.scanStart),
              ),
              if (state.scanning) ...[
                const SizedBox(height: AppSpacing.lg),
                AppProgressBar(
                  progress: state.progress,
                  label: 'فُحص ${state.done} من ${state.total} منفذ',
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // النتائج.
              if (state.openPorts.isNotEmpty) ...[
                Text(
                  '${AppStrings.portOpen}: ${state.openPorts.length}',
                  style: context.textTheme.titleMedium
                      ?.copyWith(color: AppColors.success),
                ),
                const SizedBox(height: AppSpacing.md),
                ...state.openPorts.map((p) => _PortResultTile(
                      result: p,
                      advisory: _advisories[p.port],
                    )),
              ] else if (!state.scanning && state.target != null)
                const EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'لا منافذ مفتوحة',
                  message: 'لم يُعثر على منافذ مفتوحة في النطاق المفحوص.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortResultTile extends StatelessWidget {
  const _PortResultTile({required this.result, this.advisory});
  final PortScanResult result;
  final String? advisory;

  @override
  Widget build(BuildContext context) {
    final risky = advisory != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        glowColor: risky ? AppColors.glowError : null,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  risky ? Icons.warning_amber_rounded : Icons.open_in_new_rounded,
                  color: risky ? AppColors.warning : AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Text('${AppStrings.port} ${result.port}',
                    style: context.textTheme.titleSmall),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    result.service ?? AppStrings.portOpen,
                    style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (risky) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(advisory!,
                        style: context.textTheme.labelSmall
                            ?.copyWith(color: AppColors.warning)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
