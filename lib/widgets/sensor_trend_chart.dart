import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/sensor_model.dart';
import '../theme/app_theme.dart';

enum ChartMetric { suhu, kelembapan, gas }

class SensorTrendChart extends StatefulWidget {
  final List<SensorModel> historyData;

  const SensorTrendChart({
    super.key,
    required this.historyData,
  });

  @override
  State<SensorTrendChart> createState() => _SensorTrendChartState();
}

class _SensorTrendChartState extends State<SensorTrendChart> {
  ChartMetric _selectedMetric = ChartMetric.suhu;

  Color get _metricColor {
    switch (_selectedMetric) {
      case ChartMetric.suhu:
        return AppColors.tempRed;
      case ChartMetric.kelembapan:
        return AppColors.humidityBlue;
      case ChartMetric.gas:
        return AppColors.warningAmber;
    }
  }

  String get _metricUnit {
    switch (_selectedMetric) {
      case ChartMetric.suhu:
        return '°C';
      case ChartMetric.kelembapan:
        return '%';
      case ChartMetric.gas:
        return 'PPM';
    }
  }

  double _extractValue(SensorModel model) {
    switch (_selectedMetric) {
      case ChartMetric.suhu:
        return model.suhu;
      case ChartMetric.kelembapan:
        return model.kelembapan;
      case ChartMetric.gas:
        return model.kadarGas;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.historyData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Prepare chronological list (oldest to newest for graph)
    final items = widget.historyData.reversed.toList();
    final spots = <FlSpot>[];
    double minVal = double.infinity;
    double maxVal = -double.infinity;
    double sumVal = 0.0;

    for (int i = 0; i < items.length; i++) {
      final val = _extractValue(items[i]);
      spots.add(FlSpot(i.toDouble(), val));
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
      sumVal += val;
    }

    final avgVal = sumVal / items.length;
    final yMargin = (maxVal - minVal).abs() < 1.0 ? 2.0 : (maxVal - minVal) * 0.15;
    final chartMinY = (minVal - yMargin).floorToDouble();
    final chartMaxY = (maxVal + yMargin).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.containerLow, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140E555A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _metricColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(Icons.show_chart_rounded, color: _metricColor, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Grafik Tren Sensor',
                    style: AppTypography.subtitle,
                  ),
                ],
              ),
              Text(
                '${items.length} Titik Data',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Metric Selector Segmented Box
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.containerLow, width: 0.8),
            ),
            child: Row(
              children: [
                _buildSegmentItem('Suhu (°C)', ChartMetric.suhu),
                _buildSegmentItem('Kelembapan (%)', ChartMetric.kelembapan),
                _buildSegmentItem('Kadar Gas', ChartMetric.gas),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Stats Row (Min, Avg, Max)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Min', '${minVal.toStringAsFixed(1)} $_metricUnit'),
                Container(height: 20, width: 1, color: const Color(0xFFCBD5E1)),
                _buildStatColumn('Rata-rata', '${avgVal.toStringAsFixed(1)} $_metricUnit'),
                Container(height: 20, width: 1, color: const Color(0xFFCBD5E1)),
                _buildStatColumn('Maks', '${maxVal.toStringAsFixed(1)} $_metricUnit'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md + 4),
          // FlChart LineChart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((chartMaxY - chartMinY) / 4).clamp(1.0, 100.0),
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: ((chartMaxY - chartMinY) / 4).clamp(1.0, 100.0),
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (items.length <= 4)
                          ? 1.0
                          : (items.length / 4).clamp(1.0, 50.0),
                      getTitlesWidget: (value, meta) {
                        final idx = value.round();
                        if (idx >= 0 && idx < items.length) {
                          // Only show title on integer steps
                          if ((value - idx).abs() > 0.05) return const SizedBox.shrink();
                          final timeStr = items[idx].waktu ?? '';
                          final parts = timeStr.split(' ');
                          String displayTime = parts.length > 1 ? parts[1] : timeStr;
                          if (displayTime.length >= 8) {
                            displayTime = displayTime.substring(0, 8); // HH:mm:ss
                          } else if (displayTime.length >= 5) {
                            displayTime = displayTime.substring(0, 5);
                          }
                          return Text(
                            displayTime,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (items.length - 1).toDouble().clamp(0.0, 1000.0),
                minY: chartMinY,
                maxY: chartMaxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppColors.pharmaNavy,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} $_metricUnit',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: _metricColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: items.length <= 15,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: _metricColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _metricColor.withAlpha(70),
                          _metricColor.withAlpha(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(String label, ChartMetric metric) {
    final isSelected = _selectedMetric == metric;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMetric = metric),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.pharmaNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
