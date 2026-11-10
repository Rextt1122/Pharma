import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/sensor_model.dart';
import '../theme/app_theme.dart';

enum ChartMetric { suhu, kelembapan, gas }

class SensorTrendChart extends StatefulWidget {
  final List<SensorModel> historyData;
  final double tempMin;
  final double tempMax;
  final double humidityMin;
  final double humidityMax;
  final double gasMax;
  final bool isVaccineRack;

  const SensorTrendChart({
    super.key,
    required this.historyData,
    this.tempMin = 2.0,
    this.tempMax = 8.0,
    this.humidityMin = 30.0,
    this.humidityMax = 50.0,
    this.gasMax = 50.0,
    this.isVaccineRack = true,
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

  double? get _upperThreshold {
    switch (_selectedMetric) {
      case ChartMetric.suhu:
        return widget.tempMax;
      case ChartMetric.kelembapan:
        return widget.humidityMax;
      case ChartMetric.gas:
        return widget.gasMax;
    }
  }

  double? get _lowerThreshold {
    switch (_selectedMetric) {
      case ChartMetric.suhu:
        return widget.tempMin;
      case ChartMetric.kelembapan:
        return widget.humidityMin;
      case ChartMetric.gas:
        return null;
    }
  }

  /// Garis batas bawah visual agar ketiga tab (Suhu, Kelembapan, Kadar Gas)
  /// konsisten memiliki bingkai Maks & Min seperti grafik Kelembapan.
  double get _lowerReferenceLine {
    switch (_selectedMetric) {
      case ChartMetric.suhu:
        return widget.tempMin;
      case ChartMetric.kelembapan:
        return widget.humidityMin;
      case ChartMetric.gas:
        return 5.0;
    }
  }

  static const int _maxPoints = 48;

  List<SensorModel> _prepareChronological(List<SensorModel> raw) {
    final filtered = widget.isVaccineRack
        ? raw.where((e) => e.deviceId != 'device_2').toList()
        : raw.where((e) => e.deviceId == 'device_2').toList();
    final base = filtered.length >= 2 ? filtered : raw.toList();

    final indexed = base.reversed.toList().asMap().entries.toList();
    indexed.sort((a, b) {
      final ta = DateTime.tryParse((a.value.waktu ?? '').trim());
      final tb = DateTime.tryParse((b.value.waktu ?? '').trim());
      if (ta != null && tb != null) {
        final cmp = ta.compareTo(tb);
        if (cmp != 0) return cmp;
      }
      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  /// Gabungkan data mentah ke maksimal [maxPoints] titik (rata-rata per bucket).
  List<SensorModel> _downsample(List<SensorModel> src, int maxPoints) {
    if (src.length <= maxPoints) return src;
    final out = <SensorModel>[];
    final size = src.length / maxPoints;
    for (int b = 0; b < maxPoints; b++) {
      final start = (b * size).floor();
      final end = ((b + 1) * size).floor().clamp(start + 1, src.length);
      final bucket = src.sublist(start, end);
      double avg(double Function(SensorModel) f) =>
          bucket.map(f).reduce((a, c) => a + c) / bucket.length;
      out.add(bucket.last.copyWith(
        suhu: avg((e) => e.suhu),
        kelembapan: avg((e) => e.kelembapan),
        kadarGas: avg((e) => e.kadarGas),
      ));
    }
    return out;
  }

  /// Haluskan gelombang kurva agar tidak patah/lancip tajam.
  List<double> _smoothSeries(List<double> vals) {
    if (vals.length < 3) return vals;
    final out = List<double>.filled(vals.length, 0.0);
    out[0] = (vals[0] * 0.75) + (vals[1] * 0.25);
    for (int i = 1; i < vals.length - 1; i++) {
      out[i] = (vals[i - 1] * 0.22) + (vals[i] * 0.56) + (vals[i + 1] * 0.22);
    }
    final last = vals.length - 1;
    out[last] = (vals[last - 1] * 0.25) + (vals[last] * 0.75);
    return out;
  }

  bool _isValAnomalous(double val) {
    if (_upperThreshold != null && val > _upperThreshold!) return true;
    if (_lowerThreshold != null && val < _lowerThreshold!) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.historyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final orderedItems = _prepareChronological(widget.historyData);
    final items = _downsample(orderedItems, _maxPoints);
    final rawVals = items.map(_extractValue).toList();
    final smoothVals = _smoothSeries(rawVals);

    final spots = <FlSpot>[];
    double minVal = double.infinity;
    double maxVal = -double.infinity;

    for (int i = 0; i < smoothVals.length; i++) {
      final val = smoothVals[i];
      spots.add(FlSpot(i.toDouble(), val));
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
      if (rawVals[i] < minVal) minVal = rawVals[i];
      if (rawVals[i] > maxVal) maxVal = rawVals[i];
    }

    // Selalu bingkai garis batas bawah & atas dengan ruang bernapas proporsional
    // agar tampilan Suhu, Kelembapan, dan Kadar Gas seragam di tengah area grafik.
    double effectiveMin = minVal < _lowerReferenceLine ? minVal : _lowerReferenceLine;
    double effectiveMax = _upperThreshold != null && _upperThreshold! > maxVal
        ? _upperThreshold!
        : maxVal;

    final range = (effectiveMax - effectiveMin).abs();
    final yMargin = range < 1.0 ? 2.0 : range * 0.18;
    double chartMinY = (effectiveMin - yMargin).floorToDouble();
    double chartMaxY = (effectiveMax + yMargin).ceilToDouble();
    if (minVal >= 0 && chartMinY < 0) {
      chartMinY = 0;
    }

    final double span = (chartMaxY - chartMinY).abs();
    double yInterval = 5.0;
    if (span <= 12) {
      yInterval = 2.0;
    } else if (span <= 25) {
      yInterval = 5.0;
    } else if (span <= 65) {
      yInterval = 10.0;
    } else {
      yInterval = 20.0;
    }
    chartMinY = (chartMinY / yInterval).floor() * yInterval;
    chartMaxY = (chartMaxY / yInterval).ceil() * yInterval;
    if (minVal >= 0 && chartMinY < 0) {
      chartMinY = 0;
    }

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
                _buildSegmentItem('Suhu', ChartMetric.suhu),
                _buildSegmentItem('Kelembapan', ChartMetric.kelembapan),
                _buildSegmentItem('Kadar Gas', ChartMetric.gas),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          // Threshold Limit Indicator Banner
          Builder(
            builder: (context) {
              final anomalousCount = items.where((e) => _isValAnomalous(_extractValue(e))).length;
              final String rangeText = _lowerThreshold != null
                  ? '${_lowerThreshold!.toStringAsFixed(0)}–${_upperThreshold!.toStringAsFixed(0)} $_metricUnit'
                  : '< ${_upperThreshold!.toStringAsFixed(0)} $_metricUnit';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (anomalousCount > 0 ? AppColors.alertRed : AppColors.activeGreen).withAlpha(16),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: (anomalousCount > 0 ? AppColors.alertRed : AppColors.activeGreen).withAlpha(50),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      anomalousCount > 0 ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
                      size: 15,
                      color: anomalousCount > 0 ? AppColors.alertRed : AppColors.activeGreen,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        anomalousCount > 0
                            ? '$anomalousCount Anomali • Batas Standar $rangeText'
                            : 'Normal • Seluruh Titik Dalam Batas $rangeText',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: anomalousCount > 0 ? AppColors.alertRed : AppColors.pharmaNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // FlChart LineChart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                clipData: const FlClipData.all(),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (_upperThreshold != null)
                      HorizontalLine(
                        y: _upperThreshold!,
                        color: AppColors.alertRed.withAlpha(220),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 8, bottom: 2),
                          style: const TextStyle(
                            color: AppColors.alertRed,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                          labelResolver: (line) =>
                              'Maks (${line.y.toStringAsFixed(0)} $_metricUnit)',
                        ),
                      ),
                    HorizontalLine(
                      y: _lowerReferenceLine,
                      color: const Color(0xFF0284C7),
                      strokeWidth: 1.3,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.bottomRight,
                        padding: const EdgeInsets.only(right: 8, top: 2),
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (line) =>
                            'Min (${line.y.toStringAsFixed(0)} $_metricUnit)',
                      ),
                    ),
                  ],
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min) {
                          return const SizedBox.shrink();
                        }
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
                      interval: items.length > 1
                          ? ((items.length - 1) / 4).ceilToDouble().clamp(1.0, 1000.0)
                          : 1.0,
                      getTitlesWidget: (value, meta) {
                        final idx = value.round();
                        if (idx >= 0 && idx < items.length) {
                          if ((value - idx).abs() > 0.05) return const SizedBox.shrink();
                          final timeStr = items[idx].waktu ?? '';
                          final parts = timeStr.split(' ');
                          String displayTime = parts.length > 1 ? parts[1] : timeStr;
                          if (displayTime.length >= 5) {
                            displayTime = displayTime.substring(0, 5); // HH:mm
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              displayTime,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
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
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: _metricColor.withAlpha(90),
                          strokeWidth: 1.2,
                          dashArray: [4, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, idx) =>
                              FlDotCirclePainter(
                            radius: 4.0,
                            color: _metricColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppColors.pharmaNavy,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.spotIndex;
                        final rawVal = (idx >= 0 && idx < rawVals.length)
                            ? rawVals[idx]
                            : spot.y;
                        return LineTooltipItem(
                          '${rawVal.toStringAsFixed(1)} $_metricUnit',
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
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: _metricColor,
                    barWidth: 2.6,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _metricColor.withAlpha(45),
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
      child: InkWell(
        onTap: () => setState(() => _selectedMetric = metric),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 8),
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
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
