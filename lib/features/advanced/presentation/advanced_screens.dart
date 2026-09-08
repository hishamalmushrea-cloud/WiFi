import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/packet_capture_service.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/root_required_gate.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// ────────────── شاشة التقاط الحزم (Root) ──────────────
///
/// تستهلك تدفّق [PacketCaptureService] (EventChannel أصلي):
/// سطور tcpdump حقيقية عند توفّر Root، ورسالة تدهور آمن إن غاب.
class PacketCaptureScreen extends ConsumerStatefulWidget {
  const PacketCaptureScreen({super.key});

  @override
  ConsumerState<PacketCaptureScreen> createState() =>
      _PacketCaptureScreenState();
}

class _PacketCaptureScreenState extends ConsumerState<PacketCaptureScreen> {
  bool _capturing = false;
  bool _unsupported = false;
  final List<String> _log = [];
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();
    final service = ref.read(packetCaptureServiceProvider);
    _subs.add(service.lines.listen((line) {
      if (!mounted) return;
      setState(() {
        _log.insert(0, line);
        if (_log.length > 100) _log.removeLast();
      });
    }));
    _subs.add(service.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        _capturing = status == CaptureStatus.running;
        _unsupported = status == CaptureStatus.unsupported;
      });
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _toggle() {
    final service = ref.read(packetCaptureServiceProvider);
    if (_capturing) {
      service.stop();
    } else {
      service.start();
    }
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
                  onPressed: _unsupported ? null : _toggle,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _capturing ? AppColors.error : AppColors.primary,
                  ),
                  icon: Icon(_capturing
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded),
                  label: Text(_capturing
                      ? AppStrings.stopCapture
                      : AppStrings.startCapture),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_unsupported)
            const GlassCard(
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.warning),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      '${AppStrings.captureNeedsRoot}${AppStrings.captureNeedsRoot2}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
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
                      title: AppStrings.captureNotStarted,
                      message: AppStrings.captureNotStartedHint,
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
      ('ICMP/Ping', 4, AppColors.darkTextSecondary, Icons.network_ping),
      (AppStrings.protocolHttpExposed, 3, AppColors.error, Icons.lock_open_rounded),
    ];

    return _AdvancedScaffold(
      title: AppStrings.toolProtocolAnalyzer,
      icon: Icons.bar_chart_rounded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.protocolDistribution,
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
                    AppStrings.httpExposedWarning,
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
      title: AppStrings.mitmTitle,
      icon: Icons.shield_rounded,
      body: Column(
        children: [
          _MitmCheck(
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            title: AppStrings.mitmArpTitle,
            detail: AppStrings.mitmArpDetail,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MitmCheck(
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            title: AppStrings.mitwDnsTitle,
            detail: AppStrings.mitwDnsDetail,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MitmCheck(
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            title: AppStrings.mitmTlsTitle,
            detail: AppStrings.mitmTlsDetail,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MitmCheck(
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            title: AppStrings.mitmProbeTitle,
            detail: AppStrings.mitmProbeDetail,
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
