import 'package:flutter/material.dart';

import '../../domain/entities/device.dart';
import '../../extensions/context_ext.dart';
import '../../localization/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'glass_card.dart';

/// أيقونة نوع الجهاز.
IconData deviceTypeIcon(DeviceType type) => switch (type) {
      DeviceType.router => Icons.router_rounded,
      DeviceType.phone => Icons.smartphone_rounded,
      DeviceType.laptop => Icons.laptop_mac_rounded,
      DeviceType.desktop => Icons.computer_rounded,
      DeviceType.tablet => Icons.tablet_mac_rounded,
      DeviceType.tv => Icons.tv_rounded,
      DeviceType.camera => Icons.videocam_rounded,
      DeviceType.printer => Icons.print_rounded,
      DeviceType.iot ||
      DeviceType.smartHome => Icons.sensors_rounded,
      DeviceType.nas => Icons.storage_rounded,
      DeviceType.gameConsole => Icons.sports_esports_rounded,
      DeviceType.wearable => Icons.watch_rounded,
      DeviceType.unknown => Icons.devices_other_rounded,
    };

/// بطاقة جهاز تفاعلية مع مؤشر اتصال وشارات حالة وقائمة إجراءات.
class ModernDeviceCard extends StatelessWidget {
  const ModernDeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onToggleFavorite,
    this.onBlock,
  });

  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onBlock;

  Color get _statusColor =>
      device.isBlocked ? AppColors.error : (device.isOnline ? AppColors.success : AppColors.darkTextTertiary);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // أيقونة النوع في دائرة ملونة حسب الحالة.
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: _statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(deviceTypeIcon(device.type),
                    color: _statusColor, size: 22),
              ),
              const Spacer(),
              // نقطة الاتصال النابضة للمتصل.
              _StatusDot(online: device.isOnline, color: _statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // الاسم
          Text(
            device.displayName,
            style: context.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            device.ip,
            style: context.textTheme.labelSmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          // شارات الحالة.
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (device.isFavorite)
                const _Badge(icon: Icons.star_rounded, color: AppColors.warning),
              if (device.isBlocked)
                const _Badge(icon: Icons.block_rounded, color: AppColors.error),
              if (device.isRandomMac)
                _Badge(icon: Icons.shuffle_rounded, color: AppColors.accent,
                    tooltip: 'MAC عشوائي'),
              if (device.vendor != null)
                _Badge(
                  icon: Icons.business_rounded,
                  color: AppColors.secondary,
                  label: device.vendor!,
                ),
            ],
          ),
          const Spacer(),
          // إجراء سريع: المفضلة.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onToggleFavorite,
              icon: Icon(
                device.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 20,
                color: device.isFavorite
                    ? AppColors.warning
                    : context.colors.onSurfaceVariant,
              ),
              tooltip: AppStrings.deviceFavorite,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.online, required this.color});
  final bool online;
  final Color color;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // نبض خفيف متكرر للإشارة لاتصال حيّ.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.online) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            // ignore: deprecated_member_use
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4 + _controller.value * 0.4),
                blurRadius: 6 + _controller.value * 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.color,
    this.label,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final String? label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: content);
    }
    return content;
  }
}
