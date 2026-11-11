import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../models/sensor_model.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/shimmer_loading.dart';

class ClimateDashboardPage extends StatelessWidget {
  const ClimateDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => Consumer<SensorProvider>(
        builder: (context, provider, child) => provider.isInitialLoading
            ? _loading()
            : _dashboard(context, provider, provider.sensorData),
      );

  Widget _loading() => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          ShimmerLoading(height: 48, radius: AppSpacing.radiusSm),
          SizedBox(height: AppSpacing.md),
          ShimmerLoading(height: 220, radius: AppSpacing.radiusMd),
          SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: ShimmerLoading(height: 120, radius: AppSpacing.radiusMd)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: ShimmerLoading(height: 120, radius: AppSpacing.radiusMd)),
          ]),
          SizedBox(height: AppSpacing.md),
          ShimmerLoading(height: 80, radius: AppSpacing.radiusMd),
        ],
      );

  Widget _dashboard(BuildContext context, SensorProvider p, SensorModel s) {
    final targetMin = p.currentTempMin;
    final targetMax = p.currentTempMax;
    final humMin = p.currentHumidityMin;
    final humMax = p.currentHumidityMax;

    final tempOk = s.suhu >= targetMin && s.suhu <= targetMax;
    final humOk = s.kelembapan >= humMin && s.kelembapan <= humMax;
    final safe = tempOk && humOk && !s.isGasBahaya && !s.isPintuTerbuka;

    final hero = p.isVaccineRack
        ? _buildHeroClimateDial(
            s: s,
            p: p,
            safe: safe,
            tempOk: tempOk,
            humOk: humOk,
            targetMin: targetMin,
            targetMax: targetMax,
            humMin: humMin,
            humMax: humMax,
          )
        : _buildCleanroomSecurityHero(
            context: context,
            s: s,
            p: p,
            safe: safe,
          );
    final metrics = _buildBentoEnvironmentMetrics(
      context: context,
      s: s,
      p: p,
    );
    final controls = _buildSmartControlTiles(context, p, s);

    return LayoutBuilder(
      builder: (context, box) {
        // Layar lebar (tablet / desktop): dua kolom penuh kiri-kanan.
        if (box.maxWidth >= 760) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              _selector(p),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: hero,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (p.isVaccineRack) ...[
                          _buildSectionTitle('PARAMETER LINGKUNGAN'),
                          metrics,
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        _buildSectionTitle('KONTROL AKTUATOR'),
                        controls,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _connection(p),
            ],
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          children: [
            // 1. Zone Selector
            _selector(p),
            const SizedBox(height: AppSpacing.md),

            // 2. Twin Climate Gauges / Hero Card
            hero,
            const SizedBox(height: AppSpacing.lg),

            // 3. Parameter Lingkungan (Khusus Rak Vaksin)
            if (p.isVaccineRack) ...[
              _buildSectionTitle('PARAMETER LINGKUNGAN'),
              metrics,
              const SizedBox(height: AppSpacing.lg),
            ],

            // 4. Tactile Smart Controls
            _buildSectionTitle('KONTROL AKTUATOR'),
            controls,
            const SizedBox(height: AppSpacing.lg),

            // 5. Connection Status
            _connection(p),
          ],
        );
      },
    );
  }

  Widget _selector(SensorProvider p) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.containerLow, width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C0E555A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(children: [
          _tab('Rak Vaksin', p.isVaccineRack, () => p.selectDevice('device_1')),
          _tab('Ruang Steril', !p.isVaccineRack, () => p.selectDevice('device_2')),
        ]),
      );

  Widget _tab(String label, bool on, VoidCallback tap) => Expanded(
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.pharmaNavy : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: on ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      );

  Widget _buildHeroClimateDial({
    required SensorModel s,
    required SensorProvider p,
    required bool safe,
    required bool tempOk,
    required bool humOk,
    required double targetMin,
    required double targetMax,
    required double humMin,
    required double humMax,
  }) {
    const double tempMinScale = 0.0;
    const double tempMaxScale = 12.0;
    const double humMinScale = 0.0;
    const double humMaxScale = 100.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: safe ? AppColors.containerLow : AppColors.alertRed.withAlpha(80),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0E555A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm + 4, AppSpacing.md, AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card: Zone Label & Live Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: safe ? AppColors.activeGreen : AppColors.alertRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'COLD STORAGE VAKSIN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: safe ? AppColors.pharmaNavy : AppColors.alertRed,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: (safe ? AppColors.activeGreen : AppColors.alertRed).withAlpha(16),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  safe ? 'KONDISI OPTIMAL' : 'PERINGATAN IKLIM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: safe ? AppColors.activeGreen : AppColors.alertRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Twin Gauges Row: Suhu (Kiri) & Kelembapan (Kanan)
          Row(
            children: [
              // Gauge 1: Suhu Vaksin
              Expanded(
                child: _buildCircularSubGauge(
                  label: 'Suhu Vaksin',
                  value: s.suhu,
                  unit: '°C',
                  valueDecimals: 1,
                  scaleMin: tempMinScale,
                  scaleMax: tempMaxScale,
                  targetMin: targetMin,
                  targetMax: targetMax,
                  isOk: tempOk,
                  primaryColor: tempOk ? AppColors.pharmaNavy : AppColors.alertRed,
                  accentGradient: tempOk
                      ? const SweepGradient(colors: [AppColors.pharmaTeal, AppColors.pharmaNavy])
                      : null,
                  statusBadgeText: tempOk
                      ? 'Target ${targetMin.toStringAsFixed(0)}–${targetMax.toStringAsFixed(0)}°C'
                      : 'Di Luar Batas',
                ),
              ),
              Container(
                width: 1,
                height: 125,
                color: AppColors.containerLow,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              // Gauge 2: Kelembapan
              Expanded(
                child: _buildCircularSubGauge(
                  label: 'Kelembapan',
                  value: s.kelembapan,
                  unit: '%',
                  valueDecimals: 0,
                  scaleMin: humMinScale,
                  scaleMax: humMaxScale,
                  targetMin: humMin,
                  targetMax: humMax,
                  isOk: humOk,
                  primaryColor: humOk ? AppColors.humidityBlue : AppColors.alertRed,
                  accentGradient: humOk
                      ? const SweepGradient(colors: [Color(0xFF38BDF8), AppColors.humidityBlue])
                      : null,
                  statusBadgeText: humOk
                      ? 'Target ${humMin.toStringAsFixed(0)}–${humMax.toStringAsFixed(0)}%'
                      : 'Di Luar Batas',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularSubGauge({
    required String label,
    required double value,
    required String unit,
    required int valueDecimals,
    required double scaleMin,
    required double scaleMax,
    required double targetMin,
    required double targetMax,
    required bool isOk,
    required Color primaryColor,
    SweepGradient? accentGradient,
    required String statusBadgeText,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 125,
          child: RepaintBoundary(
            child: SfRadialGauge(
              axes: [
                RadialAxis(
                  minimum: scaleMin,
                  maximum: scaleMax,
                  startAngle: 150,
                  endAngle: 30,
                  canScaleToFit: true,
                  radiusFactor: 0.95,
                  centerY: 0.52,
                  showTicks: false,
                  showLabels: false,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 9.0,
                    cornerStyle: CornerStyle.bothCurve,
                    color: AppColors.containerLow,
                  ),
                  ranges: [
                    GaugeRange(
                      startValue: targetMin,
                      endValue: targetMax,
                      color: (isOk ? primaryColor : AppColors.alertRed).withAlpha(35),
                      startWidth: 9.0,
                      endWidth: 9.0,
                      sizeUnit: GaugeSizeUnit.logicalPixel,
                    ),
                  ],
                  pointers: [
                    RangePointer(
                      value: value.clamp(scaleMin, scaleMax),
                      width: 9.0,
                      sizeUnit: GaugeSizeUnit.logicalPixel,
                      cornerStyle: CornerStyle.bothCurve,
                      color: primaryColor,
                      gradient: accentGradient,
                    ),
                    MarkerPointer(
                      value: value.clamp(scaleMin, scaleMax),
                      markerType: MarkerType.circle,
                      color: Colors.white,
                      borderColor: primaryColor,
                      borderWidth: 2.8,
                      markerWidth: 14,
                      markerHeight: 14,
                    ),
                  ],
                  annotations: [
                    GaugeAnnotation(
                      angle: 90,
                      positionFactor: 0.05,
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                value.toStringAsFixed(valueDecimals),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 21,
                                  letterSpacing: -0.5,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                unit,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: (isOk ? AppColors.activeGreen : AppColors.alertRed).withAlpha(16),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            statusBadgeText,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: isOk ? AppColors.activeGreen : AppColors.alertRed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanroomSecurityHero({
    required BuildContext context,
    required SensorModel s,
    required SensorProvider p,
    required bool safe,
  }) {
    final uvOn = p.isUvActive;
    final alert = s.isPintuTerbuka || s.isGerakTerdeteksi;
    final Color heroColor = uvOn
        ? AppColors.uvPurple
        : (alert ? AppColors.alertRed : AppColors.pharmaNavy);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: alert ? AppColors.alertRed.withAlpha(80) : AppColors.containerLow,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0E555A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: uvOn
                          ? AppColors.uvPurple
                          : (alert ? AppColors.alertRed : AppColors.activeGreen),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CLEANROOM & STERILISASI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: uvOn
                          ? AppColors.uvPurple
                          : (alert ? AppColors.alertRed : AppColors.pharmaNavy),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Text(
                  'Standar 15–25°C',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: uvOn ? AppColors.uvPurple.withAlpha(16) : AppColors.inputBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: uvOn ? AppColors.uvPurple.withAlpha(50) : AppColors.containerLow,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: heroColor.withAlpha(22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    uvOn ? Icons.cleaning_services_rounded : Icons.shield_outlined,
                    color: heroColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uvOn ? 'Sterilisasi Sinar UV-C Aktif' : 'Ruangan Steril Siaga',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: heroColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        uvOn
                            ? 'Lampu radiasi kuman 254nm aktif membasmi patogen'
                            : (s.isGerakTerdeteksi
                                ? 'Ada orang terdeteksi • Radiasi UV otomatis dikunci'
                                : 'Kondisi ruangan steril dan aman untuk personil'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.containerLow),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Suhu Ruangan',
                        style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            s.suhu.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                          const SizedBox(width: 2),
                          const Text('°C', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.pharmaNavy)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.containerLow),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelembapan Ruang',
                        style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            s.kelembapan.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                          const SizedBox(width: 2),
                          const Text('%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.humidityBlue)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.containerLow, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildDialSubStat(
                    'Pintu Akses',
                    s.isPintuTerbuka ? 'Terbuka' : 'Terkunci',
                    isAlert: s.isPintuTerbuka,
                  ),
                ),
                Container(height: 16, width: 1, color: AppColors.containerHigh),
                Expanded(
                  child: _buildDialSubStat(
                    'Sensor Gerak',
                    s.isGerakTerdeteksi ? 'Ada Orang' : 'Kosong',
                    isAlert: s.isGerakTerdeteksi,
                  ),
                ),
                Container(height: 16, width: 1, color: AppColors.containerHigh),
                Expanded(
                  child: _buildDialSubStat(
                    'Stok Obat',
                    '${s.jarakStok.toStringAsFixed(0)} cm',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialSubStat(String label, String value, {bool isAlert = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 1.5),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: isAlert ? AppColors.alertRed : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildBentoEnvironmentMetrics({
    required BuildContext context,
    required SensorModel s,
    required SensorProvider p,
  }) {
    return Column(
      children: [
        Row(
          children: [
            // Kadar Gas Tile
            Expanded(
              child: _buildBentoMetricTile(
                icon: Icons.cloud_outlined,
                iconColor: s.isGasBahaya ? AppColors.alertRed : AppColors.activeGreen,
                label: 'Kadar Gas MQ-2',
                value: '${s.kadarGas.toStringAsFixed(1)} PPM',
                targetText: s.isGasBahaya ? 'Bahaya Asap / Gas' : 'Udara Bersih',
                isSafe: !s.isGasBahaya,
                progressValue: (s.kadarGas / p.gasMax).clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Sensor Cahaya LDR Tile
            Expanded(
              child: _buildBentoMetricTile(
                icon: Icons.wb_sunny_outlined,
                iconColor: AppColors.warningAmber,
                label: 'Sensor Cahaya',
                value: '${s.cahaya.toStringAsFixed(0)} Lux',
                targetText: 'Pencahayaan Rak',
                isSafe: true,
                progressValue: (s.cahaya / 500.0).clamp(0.0, 1.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Door Security Bar
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AppToast.info(
                context,
                s.isPintuTerbuka
                    ? 'Sensor Pintu: Terbuka! Periksa fisik gudang atau simulasi web.'
                    : 'Sensor Pintu: Terkunci rapat dan aman.',
              );
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 11),
              decoration: BoxDecoration(
                color: s.isPintuTerbuka ? AppColors.alertRed.withAlpha(16) : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: s.isPintuTerbuka ? AppColors.alertRed.withAlpha(70) : AppColors.containerLow,
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C0E555A),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: (s.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen).withAlpha(22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      s.isPintuTerbuka ? Icons.door_sliding_outlined : Icons.lock_outline_rounded,
                      color: s.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pintu Gudang',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          s.isPintuTerbuka ? 'Terbuka • Perlu Ditutup' : 'Terkunci Rapat',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: s.isPintuTerbuka ? AppColors.alertRed : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (s.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen).withAlpha(20),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      s.isPintuTerbuka ? 'TERBUKA' : 'TERKUNCI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: s.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String targetText,
    required bool isSafe,
    required double progressValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isSafe ? AppColors.containerLow : AppColors.alertRed.withAlpha(70),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0E555A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSafe ? AppColors.activeGreen : AppColors.alertRed,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md - 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isSafe ? AppColors.textDark : AppColors.alertRed,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            targetText,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 4,
              backgroundColor: AppColors.containerLow,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSafe ? iconColor : AppColors.alertRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartControlTiles(BuildContext context, SensorProvider p, SensorModel s) {
    void guard(VoidCallback act) {
      if (!p.isOperator) {
        _showOperatorOnlySnack(context);
        return;
      }
      act();
    }

    if (p.isVaccineRack) {
      // NODE 1: RAK VAKSIN
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTactileActionCard(
                  title: 'Alarm Sirine',
                  status: p.buzzerActive ? 'Alarm Berbunyi' : 'Siaga Darurat',
                  icon: Icons.notifications_active_rounded,
                  isActive: p.buzzerActive,
                  activeColor: AppColors.warningAmber,
                  isRestricted: !p.isOperator,
                  onTap: () => guard(p.toggleBuzzer),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTactileActionCard(
                  title: 'Kipas Darurat',
                  status: p.device1Data.isKipasAktif ? 'Menyala' : 'Siaga',
                  icon: Icons.air_rounded,
                  isActive: p.device1Data.isKipasAktif,
                  activeColor: AppColors.humidityBlue,
                  isRestricted: !p.isOperator,
                  onTap: () => guard(p.toggleKipas),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTactileActionCard(
                  title: 'Pompa Mini',
                  status: p.device1Data.isPompaAktif ? 'Menyala' : 'Siaga',
                  icon: Icons.water_drop_outlined,
                  isActive: p.device1Data.isPompaAktif,
                  activeColor: AppColors.pharmaTeal,
                  isRestricted: !p.isOperator,
                  onTap: () => guard(p.togglePompa),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTactileActionCard(
                  title: 'Auto Climate',
                  status: p.isAutoClimate ? 'Otomatis Aktif' : 'Mode Manual',
                  icon: Icons.auto_mode_rounded,
                  isActive: p.isAutoClimate,
                  activeColor: AppColors.activeGreen,
                  isRestricted: !p.isOperator,
                  onTap: () => guard(p.toggleAutoClimate),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // NODE 2: RUANG STERIL & KEAMANAN
    return Row(
      children: [
        Expanded(
          child: _buildTactileActionCard(
            title: 'Sterilisasi UV-C',
            status: p.isUvActive ? 'Aktif (Steril)' : 'Mode Siaga',
            icon: Icons.cleaning_services_rounded,
            isActive: p.isUvActive,
            activeColor: AppColors.uvPurple,
            isRestricted: !p.isOperator,
            onTap: () {
              if (!p.isOperator) {
                _showOperatorOnlySnack(context);
                return;
              }
              final ok = p.toggleUv();
              if (!ok && p.device2Data.isGerakTerdeteksi) {
                AppToast.show(
                  context,
                  'Lampu UV dicegah: Ada orang terdeteksi di ruangan!',
                  type: AppToastType.warning,
                );
              }
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildTactileActionCard(
            title: 'LED Indikator',
            status: p.device2Data.isLedBahaya ? 'Mode Bahaya' : 'Mode Aman',
            icon: Icons.lightbulb_outline_rounded,
            isActive: p.device2Data.isLedBahaya,
            activeColor: AppColors.alertRed,
            isRestricted: !p.isOperator,
            onTap: () => guard(p.toggleLed),
          ),
        ),
      ],
    );
  }

  Widget _buildTactileActionCard({
    required String title,
    required String status,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
    bool isRestricted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withAlpha(22) : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isActive ? activeColor : AppColors.containerLow,
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isActive ? activeColor : AppColors.pharmaNavy).withAlpha(isActive ? 45 : 14),
                blurRadius: isActive ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isActive ? activeColor : AppColors.containerLow).withAlpha(isActive ? 40 : 255),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isActive ? activeColor : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive ? activeColor : AppColors.containerHigh,
                      shape: BoxShape.circle,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: activeColor.withAlpha(120),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isRestricted ? 'Akses Operator' : status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOperatorOnlySnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Akses terbatas: Hanya akun Operator yang dapat mengontrol aktuator.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.pharmaNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        margin: const EdgeInsets.all(AppSpacing.md),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _connection(SensorProvider p) {
    final online = p.isConnected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: online ? const Color(0xFFE2F2EC) : const Color(0xFFFCE8E8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: online ? AppColors.activeGreen.withAlpha(40) : AppColors.alertRed.withAlpha(40),
          width: 0.8,
        ),
      ),
      child: Row(children: [
        Icon(
          online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: online ? AppColors.activeGreen : AppColors.alertRed,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            p.isReconnecting
                ? 'Menghubungkan Ulang ke Broker...'
                : (online ? 'MQTT Terhubung • Telemetri Realtime' : 'MQTT Terputus • Data Terakhir'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
        ),
        IconButton(
          onPressed: p.isReconnecting ? null : p.reconnect,
          icon: p.isReconnecting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.pharmaNavy),
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: AppColors.pharmaNavy, size: 18),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
      ]),
    );
  }
}
