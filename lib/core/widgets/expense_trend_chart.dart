import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../../data/providers/finance_provider.dart';

class ExpenseTrendChart extends ConsumerStatefulWidget {
  const ExpenseTrendChart({super.key});

  @override
  ConsumerState<ExpenseTrendChart> createState() => _ExpenseTrendChartState();
}

class _ExpenseTrendChartState extends ConsumerState<ExpenseTrendChart> {
  ExpenseTrendTimeframe _selected = ExpenseTrendTimeframe.month1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendAsync = ref.watch(expenseTrendProvider(_selected));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trend Pengeluaran',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            trendAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (trend) => Text(
                CurrencyFormatter.formatCompact(trend.total),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray400,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _TimeframeFilter(
          selected: _selected,
          onChanged: (v) => setState(() => _selected = v),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: trendAsync.when(
            loading: () => const Center(
              child: SizedBox(
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
              ),
            ),
            error: (_, __) => Center(
              child: Text('Gagal memuat', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54)),
            ),
            data: (trend) {
              if (trend.labels.isEmpty || trend.values.isEmpty) {
                return Center(
                  child: Text('Belum ada data', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.3))),
                );
              }
              return _TrendLineChart(trend: trend);
            },
          ),
        ),
      ],
    );
  }
}

class _TimeframeFilter extends StatelessWidget {
  final ExpenseTrendTimeframe selected;
  final ValueChanged<ExpenseTrendTimeframe> onChanged;

  const _TimeframeFilter({required this.selected, required this.onChanged});

  static const _items = [
    (ExpenseTrendTimeframe.week, '1M'),
    (ExpenseTrendTimeframe.month1, '3M'),
    (ExpenseTrendTimeframe.month3, '6M'),
    (ExpenseTrendTimeframe.month6, '1T'),
    (ExpenseTrendTimeframe.year1, '1T'),
    (ExpenseTrendTimeframe.all, 'Semua'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _items.map((item) {
        final (tf, label) = item;
        final isActive = tf == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onChanged(tf),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: isActive
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.black : Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  final ExpenseTrendData trend;

  const _TrendLineChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final values = trend.values;
    final maxY = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b) * 1.15;

    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    if (spots.length == 1) {
      spots.add(FlSpot(1.0, values[0]));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: _labelInterval(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= trend.labels.length) return const SizedBox.shrink();
                if (_shouldShowLabel(idx)) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      trend.labels[idx],
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.08),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        minY: 0,
        maxY: maxY,
        minX: 0,
        maxX: (values.length - 1).toDouble().clamp(1.0, double.infinity),
      ),
    );
  }

  double _labelInterval() {
    final count = trend.labels.length;
    if (count <= 5) return 1;
    if (count <= 10) return 2;
    if (count <= 20) return 4;
    return 6;
  }

  bool _shouldShowLabel(int idx) {
    final interval = _labelInterval();
    return idx % interval.toInt() == 0 || idx == trend.labels.length - 1;
  }
}
