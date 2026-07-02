import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/audit_evaluation_chart.dart';

class AuditEvaluationChartWidget extends StatelessWidget {
  const AuditEvaluationChartWidget({super.key, required this.charts, required this.isLoading});

  final List<AuditEvaluationChart> charts;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: FastCircularProgressIndicator());
    }

    final chart = charts.isEmpty ? null : charts.first;
    if (chart == null || chart.weeklyTrends.isEmpty) {
      return const Center(
        child: AppTextView.body('No chart data found.', color: AppColors.textSecondary),
      );
    }

    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartLegend(chart: chart),
          const SizedBox(height: 10),
          Expanded(child: BarChart(_mainData(chart))),
        ],
      ),
    );
  }

  BarChartData _mainData(AuditEvaluationChart chart) {
    final trendsByWeek = {
      for (final trend in chart.weeklyTrends.where((item) => item.week >= 1 && item.week <= 13))
        trend.week: trend,
    };

    return BarChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 8,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [1, 1]),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final week = value.toInt();
              final text = week >= 1 && week <= 13 ? 'w$week' : '';
              return SideTitleWidget(
                meta: meta,
                space: 1,
                child: AppTextView.body2(text, color: Colors.white54, fontSize: 12),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 8,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value > 99 || value % 8 != 0) {
                return const SizedBox.shrink();
              }

              return AppTextView.body2(value.toInt().toString(), color: Colors.white54);
            },
            reservedSize: 30,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: 99,
      barGroups: List<BarChartGroupData>.generate(13, (index) {
        final week = index + 1;
        final trend = trendsByWeek[week];
        final great = (trend?.great ?? 0).clamp(0, 99).toDouble();
        final almostThere = (trend?.almostThere ?? 0).clamp(0, 99).toDouble();
        final needsImprovement = (trend?.needsImprovement ?? 0).clamp(0, 99).toDouble();
        final greatEnd = great;
        final almostThereEnd = (great + almostThere).clamp(0, 99).toDouble();
        final total = (great + almostThere + needsImprovement).clamp(0, 99).toDouble();

        return BarChartGroupData(
          x: week,
          barsSpace: 0,
          barRods: [
            BarChartRodData(
              toY: total,
              width: 12,
              borderRadius: BorderRadius.circular(3),
              color: total == 0 ? Colors.white12 : AppColors.green1,
              rodStackItems: total == 0
                  ? const <BarChartRodStackItem>[]
                  : [
                      if (great > 0) BarChartRodStackItem(0, greatEnd, AppColors.green1),
                      if (almostThere > 0)
                        BarChartRodStackItem(greatEnd, almostThereEnd, AppColors.orange1),
                      if (needsImprovement > 0)
                        BarChartRodStackItem(almostThereEnd, total, AppColors.red1),
                    ],
            ),
          ],
        );
      }, growable: false),
      groupsSpace: 8,
      barTouchData: BarTouchData(enabled: true),
      alignment: BarChartAlignment.spaceBetween,
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.chart});

  final AuditEvaluationChart chart;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        AppTextView.body2(
          '${chart.label} ${chart.year}',
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        const _LegendItem(label: 'Great', color: AppColors.green1),
        const _LegendItem(label: 'Almost There', color: AppColors.orange1),
        const _LegendItem(label: 'Needs Improvement', color: AppColors.red1),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(width: 6, height: 1.3, color: color),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Container(width: 6, height: 1.3, color: color),
          ],
        ),
        const SizedBox(width: 6),
        AppTextView.body3(label, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ],
    );
  }
}
