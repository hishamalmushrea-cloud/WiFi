import '../../localization/app_strings.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/access_point.dart';
import '../../extensions/context_ext.dart';
import '../../theme/app_colors.dart';

/// رسم بياني لقوة إشارة نقاط الوصول عبر قنوات النطاق.
///
/// كل نقطة وصول عمود بلون (قوة إشارة dBm سالبة تُحوّل لعرض موجب
/// للرسم)، مع تظليل القناة الموصى بها. يعتمد على fl_chart.
class ChannelGraph extends StatelessWidget {
  const ChannelGraph({
    super.key,
    required this.accessPoints,
    this.recommendedChannel,
  });

  final List<AccessPoint> accessPoints;
  final int? recommendedChannel;

  @override
  Widget build(BuildContext context) {
    if (accessPoints.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text(AppStrings.noData)),
      );
    }

    // dBm سالبة (-40 أقوى من -90) نحوّلها لارتفاع موجب:
    // -40 → 80، -100 → 0.
    double barHeight(int rssi) => (rssi + 100).clamp(0, 60).toDouble();

    final bars = <BarChartGroupData>[];
    for (var i = 0; i < accessPoints.length; i++) {
      final ap = accessPoints[i];
      final isRecommended = ap.channel == recommendedChannel;
      bars.add(
        BarChartGroupData(
          x: ap.channel,
          barRods: [
            BarChartRodData(
              toY: barHeight(ap.rssi),
              width: 14,
              borderRadius: BorderRadius.circular(4),
              gradient: isRecommended
                  ? AppColors.gradientSuccess
                  : AppColors.gradientPrimary,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 65,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              // خلفية التلميح داكنة.
              // ignore: deprecated_member_use
              tooltipBgColor: AppColors.darkSurfaceElevated,
              getTooltipItem: (groupIndex, group, rodIndex, rod) {
                final ap = accessPoints[
                    groupIndex.clamp(0, accessPoints.length - 1)];
                return BarTooltipItem(
                  '${ap.displaySsid}\nCH ${ap.channel}  ${ap.rssi} dBm',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    value.toInt().toString(),
                    style: context.textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
