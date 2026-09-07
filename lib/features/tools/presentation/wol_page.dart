import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/network_tools.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/network_tools_repository_impl.dart';

/// شاشة إيقاظ الأجهزة عبر Wake-on-LAN (Magic Packet).
class WakeOnLanPage extends ConsumerStatefulWidget {
  const WakeOnLanPage({super.key});

  @override
  ConsumerState<WakeOnLanPage> createState() => _WakeOnLanPageState();
}

class _WakeOnLanPageState extends ConsumerState<WakeOnLanPage> {
  final _mac = TextEditingController();
  final _ip = TextEditingController(text: '192.168.1.255');
  final _port = TextEditingController(text: '9');
  bool _busy = false;
  String? _result;

  Future<void> _wake() async {
    setState(() {
      _busy = true;
      _result = null;
    });
    final result =
        await ref.read(networkToolsRepositoryProvider).wakeOnLan(WakeOnLanTarget(
              mac: _mac.text.trim(),
              ip: _ip.text.trim(),
              port: int.tryParse(_port.text) ?? 9,
            ));
    setState(() {
      _busy = false;
      result.when(
        onSuccess: (_) => _result = 'أُرسلت حزمة الإيقاظ بنجاح ✓',
        onFailure: (f) => _result = f.message,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text(AppStrings.toolWol)),
        body: SafeArea(
          child: ListView(
            padding: context.responsivePadding,
            children: [
              GlassCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _mac,
                      decoration: const InputDecoration(
                        labelText: 'عنوان MAC للجهاز',
                        hintText: 'AA:BB:CC:DD:EE:FF',
                        prefixIcon: Icon(Icons.memory_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _ip,
                      decoration: const InputDecoration(
                        labelText: 'عنوان البث (Broadcast)',
                        hintText: '192.168.1.255',
                        prefixIcon: Icon(Icons.lan_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _port,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المنفذ',
                        prefixIcon: Icon(Icons.settings_ethernet_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _busy ? null : _wake,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.power_settings_new_rounded),
                label: const Text('إيقاظ الجهاز'),
              ),
              if (_result != null) ...[
                const SizedBox(height: AppSpacing.lg),
                GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(_result!)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
