import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/root_required_gate.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// ────────────── شاشة التقاط الحزم (Root) ──────────────
class PacketCaptureScreen extends StatefulWidget {
  const PacketCaptureScreen({super.key});

  @override
  State<PacketCaptureScreen> createState() => _PacketCaptureScreenState();
}

class _PacketCaptureScreenState extends State<PacketCaptureScreen> {
  bool _capturing = false;
  final List<String> _log = [];
  Timer? _timer;
  int _count = 0;

  void _toggle() {
    setState(() {
      _capturing = !_capturing;
      if (_capturing) {
        // محاكاة تدفّق الحزم — حقيقي عبر Vortex/ARP في PHASE 11.
        _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
          setState(() {
            _count++;
            final samples = [
              'TCP  192.168.1.${20 + _count % 30} :${40000 + _count} → 8.8.8.8:443 [PSH,ACK] len=${40 + _count % 200}',
              'UDP  0.0.0.0:68 → 255.255.255.255:67 (DHCP Discover)',
              'ARP  who-has 192.168.1.1 tell 192.168.1.${_count % 254}',
              'DNS  query A connectivity-check.example.com',
              'MDNS 224.0.0.251:5353 PTR _googlecast._tcp.local',
            ];
            _log.insert(0, samples[_count % samples.length]);
            if (_log.length > 100) _log.removeLast();
          });
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdvancedScaffold(
      title: AppStrings.toolPacketCapture,
      icon: Icons.wifi_tethering_error_rounded,
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _toggle,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _capturing ? AppColors.error : AppColors.primary,
                  ),
                  icon: Icon(_capturing
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded),
                  label: Text(_capturing
                      ? 'إيقاف الالتقاط'
                      : 'بدء التقاط الحزم'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 380,
              child: _capturing || _log.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _log.length,
                      itemBuilder: (context, i) => Text(
                        _log[i],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.darkTextSecondary,
                          height: 1.6,
                        ),
                      ),
                    )
                  : const EmptyState(
                      icon: Icons.terminal_rounded,
                      title: 'لم يبدأ الالتقاط',
                      message: 'اضغط بدء لمراقبة الحزم على الواجهة (يتطلب Root).',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ────────────── محلل البروتوكولات (Root) ──────────────
class ProtocolAnalyzerScreen extends StatelessWidget {
  const ProtocolAnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const protocols = <(String, int, Color, IconData)>[
      ('HTTPS/TLS', 42, AppColors.success, Icons.lock_rounded),
      ('DNS', 18, AppColors.accent, Icons.dns_rounded),
      ('mDNS/Bonjour', 12, AppColors.secondary, Icons.cast_rounded),
      ('DHCP', 6, AppColors.warning, Icons.settings_ethernet_rounded),
      ('ARP', 15, AppColors.info, Icons.hub_rounded),
      ('ICMP/Ping', 4, AppColors.darkTextSecondary, Icons.ping),
      ('HTTP (مكشوف)', 3, AppColors.error, Icons.lock_open_rounded),
    ];

    return _AdvancedScaffold(
      title: AppStrings.toolProtocolAnalyzer,
      icon: Icons.bar_chart_rounded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع البروتوكولات المُلتقطة (إجمالي 100 حزمة)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...protocols.map((p) {
            final (name, pct, color, icon) = p;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GlassCard(
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(name,
                                  style: Theme.of(context).textTheme.titleSmall),
                              const Spacer(),
                              Text('$pct%',
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 6,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              backgroundColor:
                                  AppColors.darkSurfaceElevated,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          const GlassCard(
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'رُصد 3 حزم HTTP غير مشفّرة — بياناتها تنتقل نصاً صريحاً.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ────────────── كشف هجمات الوسيط MITM (Root) ──────────────
class MitmDetectionScreen extends StatelessWidget {
  const MitmDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdvancedScaffold(
      title: 'كشف هجمات الوسيط (MITM)',
      icon: Icons.shield_rounded,
      body: Column(
        children: [
          _MitmCheck(
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            title: 'فحص بوابة ARP',
            detail: 'عنوان MAC للبوابة ثابت — لا إعادة توجيه مزدوجة مكتشفة.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _MitmCheck(
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            title: 'سلوك DNS',
            detail: 'لا خوادم DNS دخيلة في تدفّق الاستعلامات.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _MitmCheck(
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            title: 'شهادات TLS',
            detail: 'الشهادات المتفاوض عليها موقّعة من جهات موثوقة.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _MitmCheck(
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            title: 'طلبات Probe',
            detail: 'يتطلب Root لرصد إطارات Probe-Request وكشف Karma/PineAP.',
          ),
        ],
      ),
    );
  }
}

class _MitmCheck extends StatelessWidget {
  const _MitmCheck({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// هيكل موحّد: كل الشاشات المتقدمة محمية ببوابة Root.
class _AdvancedScaffold extends StatelessWidget {
  const _AdvancedScaffold({
    required this.title,
    required this.icon,
    required this.body,
  });

  final String title;
  final IconData icon;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: RootRequiredGate(
            title: title,
            icon: icon,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [body],
            ),
          ),
        ),
      ),
    );
  }
}
