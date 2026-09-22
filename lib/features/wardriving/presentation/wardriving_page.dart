import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/domain/entities/wardriving.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/presentation/widgets/app_background.dart';
import '../../../core/presentation/widgets/glass_card.dart';
import '../../../core/presentation/widgets/states.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/wardriving_repository_impl.dart';

/// شاشة Wardriving: تسجيل نقاط WiFi مع إحداثيات GPS على خريطة.
///
/// الوضع الحالي: تسجيل إحداثيات GPS لكل نقطة مسح + فحص بلوتوث
/// + إحصائيات وتصدير CSV. التقاط شبكات WiFi المحيطة أثناء الحركة
/// يعتمد القناة الأصلية (PHASE 11)؛ البنية والخريطة والـ GPS جاهزة.
class WardrivingPage extends ConsumerStatefulWidget {
  const WardrivingPage({super.key});

  @override
  ConsumerState<WardrivingPage> createState() => _WardrivingPageState();
}

class _WardrivingPageState extends ConsumerState<WardrivingPage> {
  bool _recording = false;
  LatLng? _current;
  final List<Marker> _markers = [];
  final MapController _mapController = MapController();

  Future<void> _toggleRecording() async {
    if (_recording) {
      setState(() => _recording = false);
      return;
    }

    // طلب صلاحية الموقع قبل بدء التسجيل.
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.errorPermission)),
        );
      }
      return;
    }

    setState(() => _recording = true);
    // جلب الموقع الأولي.
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _current = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _dropPoint() async {
    final pos = await Geolocator.getCurrentPosition();
    final point = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _current = point;
      _markers.add(Marker(
        point: point,
        width: 40,
        height: 40,
        child: const Icon(Icons.wifi_rounded, color: AppColors.accent, size: 32),
      ));
    });
    // احفظ النقطة في قاعدة البيانات (BSSID تجريبي حتى تكتمل قناة WiFi).
    final sample = WardrivingPoint(
      bssid: 'GPS-${pos.latitude.toStringAsFixed(4)},${pos.longitude.toStringAsFixed(4)}',
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracyMeters: pos.accuracy,
      altitude: pos.altitude,
      timestamp: DateTime.now(),
    );
    await ref.read(wardrivingRepositoryProvider).savePoints([sample]);
    _mapController.move(point, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(_wardrivingStatsProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.toolWardriving),
          actions: [
            IconButton(
              tooltip: AppStrings.export,
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: _exportCsv,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // الخريطة.
              Expanded(
                child: _current == null
                    ? EmptyState(
                        icon: Icons.map_rounded,
                        title: AppStrings.mapStartRecording,
                        message: AppStrings.needsLocation,
                        actionLabel: _recording ? AppStrings.recordingDots : AppStrings.start,
                        onAction: _recording ? null : _toggleRecording,
                      )
                    : Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _current!,
                              initialZoom: 16,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.netcontrol.app',
                              ),
                              MarkerLayer(markers: _markers),
                            ],
                          ),
                          if (_recording)
                            Positioned(
                              top: AppSpacing.lg,
                              left: AppSpacing.lg,
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(AppStrings.recordingPoints(_markers.length),
                                        style: context.textTheme.labelMedium),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              // لوحة التحكم والإحصائيات.
              Padding(
                padding: context.responsivePadding,
                child: Column(
                  children: [
                    stats.when(
                      loading: () => const ShimmerBox(height: 60),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (s) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatChip(label: AppStrings.statNetworks, value: '${s.totalNetworks}'),
                          _StatChip(label: AppStrings.statDistance, value: AppStrings.distanceKm(s.distanceKm)),
                          _StatChip(label: AppStrings.statOpen, value: '${s.openNetworks}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _toggleRecording,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  _recording ? AppColors.error : AppColors.primary,
                            ),
                            icon: Icon(_recording
                                ? Icons.stop_rounded
                                : Icons.fiber_manual_record_rounded),
                            label: Text(_recording ? AppStrings.stop : AppStrings.start),
                          ),
                        ),
                        if (_recording) ...[
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _dropPoint,
                              icon: const Icon(Icons.add_location_alt_rounded),
                              label: const Text(AppStrings.dropPoint),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final result = await ref.read(wardrivingRepositoryProvider).exportCsv();
    if (!mounted) return;
    result.when(
      onSuccess: (path) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.fileExported(path))),
      ),
      onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
    );
  }
}

/// يجلب إحصائيات الـ Wardriving من قاعدة البيانات.
final _wardrivingStatsProvider = FutureProvider<WardrivingStats>((ref) async {
  final result = await ref.watch(wardrivingRepositoryProvider).getStatistics();
  return result.dataOrNull ??
      const WardrivingStats();
});

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: context.textTheme.titleLarge
                ?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w800)),
        Text(label, style: context.textTheme.labelSmall),
      ],
    );
  }
}
