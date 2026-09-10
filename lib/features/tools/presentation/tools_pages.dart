import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/date_time_ext.dart';
import '../../../core/domain/entities/network_tools.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../network_scan/data/network_scanner_repository_impl.dart';
import '../data/network_tools_repository_impl.dart';

/// هيكل مشترك لصفحات الأدوات: حقل إدخال + زر تنفيذ + منطقة نتيجة.
class _ToolScaffold extends StatelessWidget {
  const _ToolScaffold({
    required this.title,
    required this.controller,
    required this.hint,
    required this.busy,
    required this.onRun,
    required this.result,
    this.buttonLabel = AppStrings.start,
    this.extra,
  });

  final String title;
  final TextEditingController controller;
  final String hint;
  final bool busy;
  final VoidCallback onRun;
  final Widget result;
  final String buttonLabel;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: ListView(
            padding: context.responsivePadding,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppStrings.targetHost,
                  hintText: hint,
                  prefixIcon: const Icon(Icons.computer_rounded),
                ),
              ),
              if (extra != null) ...[
                const SizedBox(height: AppSpacing.md),
                extra!,
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: busy ? null : onRun,
                child: Text(busy ? AppStrings.loading : buttonLabel),
              ),
              const SizedBox(height: AppSpacing.xl),
              result,
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────── Ping ───────────────────────────
class PingToolPage extends ConsumerStatefulWidget {
  const PingToolPage({super.key});
  @override
  ConsumerState<PingToolPage> createState() => _PingToolPageState();
}

class _PingToolPageState extends ConsumerState<PingToolPage> {
  final _controller = TextEditingController(text: 'google.com');
  PingResult? _result;
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    final r = await ref
        .read(networkScannerRepositoryProvider)
        .ping(_controller.text.trim());
    setState(() {
      _result = r.dataOrNull;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToolScaffold(
      title: AppStrings.toolPing,
      controller: _controller,
      hint: AppStrings.hintPing,
      busy: _busy,
      onRun: _run,
      result: _result == null
          ? const SizedBox.shrink()
          : GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(AppStrings.target, _result!.host),
                  _row(AppStrings.labelSentReceived,
                      '${_result!.sentCount} / ${_result!.receivedCount}'),
                  _row(AppStrings.labelPacketLoss,
                      '${_result!.packetLoss.toStringAsFixed(0)}%'),
                  _row(AppStrings.labelMinAvgMax,
                      '${_result!.minMs?.toStringAsFixed(0) ?? "-"} / '
                          '${_result!.avgMs?.toStringAsFixed(0) ?? "-"} / '
                          '${_result!.maxMs?.toStringAsFixed(0) ?? "-"} ${AppStrings.ms}'),
                ],
              ),
            ),
    );
  }
}

/// ──────────────────────── Traceroute ────────────────────────
class TracerouteToolPage extends ConsumerStatefulWidget {
  const TracerouteToolPage({super.key});
  @override
  ConsumerState<TracerouteToolPage> createState() => _TracerouteToolPageState();
}

class _TracerouteToolPageState extends ConsumerState<TracerouteToolPage> {
  final _controller = TextEditingController(text: '8.8.8.8');
  List<TracerouteHop> _hops = const [];
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    final r = await ref
        .read(networkScannerRepositoryProvider)
        .traceroute(_controller.text.trim());
    setState(() {
      _hops = r.dataOrNull ?? const [];
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToolScaffold(
      title: AppStrings.toolTraceroute,
      controller: _controller,
      hint: 'example.com',
      busy: _busy,
      onRun: _run,
      result: Column(
        children: _hops
            .map((h) => GlassCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text('${h.hop}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.primary)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(h.ip)),
                      Text(h.rttMs != null
                          ? '${h.rttMs!.toStringAsFixed(0)} ${AppStrings.ms}'
                          : '*'),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// ───────────────────────── WHOIS ────────────────────────────
class WhoisToolPage extends ConsumerStatefulWidget {
  const WhoisToolPage({super.key});
  @override
  ConsumerState<WhoisToolPage> createState() => _WhoisToolPageState();
}

class _WhoisToolPageState extends ConsumerState<WhoisToolPage> {
  final _controller = TextEditingController(text: 'example.com');
  WhoisResult? _result;
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    final r = await ref
        .read(networkToolsRepositoryProvider)
        .whois(_controller.text.trim());
    setState(() {
      _result = r.dataOrNull;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToolScaffold(
      title: AppStrings.toolWhois,
      controller: _controller,
      hint: 'example.com',
      busy: _busy,
      onRun: _run,
      result: _result == null
          ? const SizedBox.shrink()
          : GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(AppStrings.labelQuery, _result!.query),
                  if (_result!.country != null)
                    _row(AppStrings.labelCountry, _result!.country!),
                  if (_result!.registrar != null)
                    _row(AppStrings.labelRegistrar, _result!.registrar!),
                ],
              ),
            ),
    );
  }
}

/// ───────────────────────── DNS ──────────────────────────────
class DnsToolPage extends ConsumerStatefulWidget {
  const DnsToolPage({super.key});
  @override
  ConsumerState<DnsToolPage> createState() => _DnsToolPageState();
}

class _DnsToolPageState extends ConsumerState<DnsToolPage> {
  final _controller = TextEditingController(text: 'google.com');
  List<DnsRecord> _records = const [];
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    final r = await ref
        .read(networkToolsRepositoryProvider)
        .dnsLookup(_controller.text.trim(), 'A');
    setState(() {
      _records = r.dataOrNull ?? const [];
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToolScaffold(
      title: AppStrings.toolDns,
      controller: _controller,
      hint: AppStrings.hintDns,
      busy: _busy,
      onRun: _run,
      result: Column(
        children: _records
            .map((rec) => GlassCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.dns_rounded,
                          size: 20, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rec.recordType,
                                style: context.textTheme.labelSmall
                                    ?.copyWith(color: AppColors.accent)),
                            Text(rec.value,
                                style: context.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      if (rec.ttl != null) Text('TTL ${rec.ttl}'),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// ────────────────── حاسبة الشبكة الفرعية ────────────────────
class SubnetCalculatorPage extends StatefulWidget {
  const SubnetCalculatorPage({super.key});
  @override
  State<SubnetCalculatorPage> createState() => _SubnetCalculatorPageState();
}

class _SubnetCalculatorPageState extends State<SubnetCalculatorPage> {
  final _ip = TextEditingController(text: '192.168.1.10');
  double _prefix = 24;
  SubnetInfo? _info;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return AppBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(title: const Text(AppStrings.toolSubnet)),
            body: SafeArea(
              child: ListView(
                padding: context.responsivePadding,
                children: [
                  TextField(
                    controller: _ip,
                    decoration: const InputDecoration(
                      labelText: AppStrings.labelIpAddress,
                      prefixIcon: Icon(Icons.lan_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(AppStrings.prefixLabel(_prefix.toInt()),
                      style: context.textTheme.titleSmall),
                  Slider(
                    value: _prefix,
                    min: 8,
                    max: 32,
                    divisions: 24,
                    label: '/${_prefix.toInt()}',
                    onChanged: (v) => setState(() => _prefix = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () async {
                      final r = await ref
                          .read(networkToolsRepositoryProvider)
                          .calculateSubnet(
                              _ip.text.trim(), _prefix.toInt());
                      setState(() => _info = r.dataOrNull);
                    },
                    child: const Text(AppStrings.done),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_info != null)
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row('CIDR', _info!.cidr),
                          _row(AppStrings.labelSubnetMask, _info!.subnetMask),
                          _row(AppStrings.labelNetworkAddress, _info!.networkAddress),
                          _row(AppStrings.labelBroadcastAddress, _info!.broadcastAddress),
                          _row(AppStrings.labelFirstHost, _info!.firstHost),
                          _row(AppStrings.labelLastHost, _info!.lastHost),
                          _row(AppStrings.labelUsableHosts,
                              '${_info!.usableHosts}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ────────────────────── معرفة المصنّع ────────────────────────
class MacVendorToolPage extends ConsumerStatefulWidget {
  const MacVendorToolPage({super.key});
  @override
  ConsumerState<MacVendorToolPage> createState() => _MacVendorToolPageState();
}

class _MacVendorToolPageState extends ConsumerState<MacVendorToolPage> {
  final _controller = TextEditingController();
  String? _vendor;
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    final r = await ref
        .read(networkToolsRepositoryProvider)
        .macVendorLookup(_controller.text.trim());
    setState(() {
      _vendor = r.dataOrNull ?? r.failureOrNull?.message;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToolScaffold(
      title: AppStrings.toolMacVendor,
      controller: _controller,
      hint: 'AA:BB:CC:DD:EE:FF',
      busy: _busy,
      onRun: _run,
      result: _vendor == null
          ? const SizedBox.shrink()
          : GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.business_rounded, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(_vendor!)),
                ],
              ),
            ),
    );
  }
}

/// ────────────────────── فحص SSL ─────────────────────────────
class SslToolPage extends ConsumerStatefulWidget {
  const SslToolPage({super.key});
  @override
  ConsumerState<SslToolPage> createState() => _SslToolPageState();
}

class _SslToolPageState extends ConsumerState<SslToolPage> {
  final _controller = TextEditingController(text: 'google.com');
  SslCertificateInfo? _info;
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    final r = await ref
        .read(networkToolsRepositoryProvider)
        .inspectSsl(_controller.text.trim());
    setState(() {
      _info = r.dataOrNull;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToolScaffold(
      title: AppStrings.toolSsl,
      controller: _controller,
      hint: 'example.com',
      busy: _busy,
      onRun: _run,
      result: _info == null
          ? const SizedBox.shrink()
          : GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(AppStrings.labelHost, _info!.host),
                  if (_info!.issuer != null) _row(AppStrings.labelIssuer, _info!.issuer!),
                  if (_info!.validTo != null)
                    _row(AppStrings.labelValidTo, _info!.validTo!.formatted),
                  _row(AppStrings.status,
                      _info!.isExpired ? AppStrings.sslExpired : AppStrings.sslValid),
                  _row(AppStrings.sslSelfSigned,
                      _info!.isSelfSigned ? AppStrings.yes : AppStrings.no),
                ],
              ),
            ),
    );
  }
}

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.darkTextTertiary, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextPrimary)),
        ),
      ],
    ),
  );
}
