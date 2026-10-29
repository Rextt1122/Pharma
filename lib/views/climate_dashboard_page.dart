import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../models/sensor_model.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';
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

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      children: [
        // 1. Zone Selector
        _selector(p),
        const SizedBox(height: AppSpacing.md),

        // 2. Hero Climate Dial
        _buildHeroClimateDial(
          s: s,
          p: p,
          safe: safe,
          targetMin: targetMin,
          targetMax: targetMax,
        ),
        const SizedBox(height: AppSpacing.lg),

        // 3. Bento Environment & Security Metrics
        _buildSectionTitle('PARAMETER LINGKUNGAN'),
        _buildBentoEnvironmentMetrics(
          s: s,
          p: p,
          humMin: humMin,
          humMax: humMax,
          humOk: humOk,
        ),
        const SizedBox(height: AppSpacing.lg),

        // 4. Tactile Smart Controls
        _buildSectionTitle('KONTROL AKTUATOR'),
        _buildSmartControlTiles(context, p, s),
        const SizedBox(height: AppSpacing.lg),

        // 5. Connection Status
        _connection(p),
      ],
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
    required double targetMin,
    required double targetMax,
  }) {
    final double defaultGaugeMin = p.isVaccineRack ? 0.0 : 10.0;
    final double defaultGaugeMax = p.isVaccineRack ? 12.0 : 35.0;
    final double gaugeMin = math.min(defaultGaugeMin, targetMin - 1.0).floorToDouble();
    final double gaugeMax = math.max(defaultGaugeMax, math.max(targetMax + 2.0, s.suhu + 2.0)).ceilToDouble();

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md - 2, AppSpacing.md, AppSpacing.sm + 2),
        child: Column(
          children: [
            // Clean Header: Zone Label & Target Range (No duplicate 2-8°C text)
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
                      p.isVaccineRack ? 'COLD STORAGE' : 'CLEANROOM',
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
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'Target ${targetMin.toStringAsFixed(0)}–${targetMax.toStringAsFixed(0)}°C',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Proportional true semi-circle radial gauge
            SizedBox(
              height: 165,
              child: RepaintBoundary(
                child: SfRadialGauge(
                  axes: [
                    RadialAxis(
                      minimum: gaugeMin,
                      maximum: gaugeMax,
                      startAngle: 180,
                      endAngle: 0,
                      canScaleToFit: true,
                      radiusFactor: 1.0,
                      centerY: 0.82,
                      showTicks: false,
                      showLabels: false,
                      axisLineStyle: const AxisLineStyle(
                        thickness: 14,
                        cornerStyle: CornerStyle.bothCurve,
                        color: AppColors.containerLow,
                      ),
                      ranges: [
                        GaugeRange(
                          startValue: targetMin,
                          endValue: targetMax,
                          color: AppColors.activeGreen.withAlpha(45),
                          startWidth: 14,
                          endWidth: 14,
                          sizeUnit: GaugeSizeUnit.logicalPixel,
                        ),
                      ],
                      pointers: [
                        RangePointer(
                          value: s.suhu.clamp(gaugeMin, gaugeMax),
                          width: 14,
                          sizeUnit: GaugeSizeUnit.logicalPixel,
                          cornerStyle: CornerStyle.bothCurve,
                          color: safe ? AppColors.pharmaNavy : AppColors.alertRed,
                          gradient: safe
                              ? const SweepGradient(
                                  colors: [AppColors.pharmaTeal, AppColors.pharmaNavy],
                                )
                              : null,
                        ),
                        MarkerPointer(
                          value: s.suhu.clamp(gaugeMin, gaugeMax),
                          markerType: MarkerType.circle,
                          color: Colors.white,
                          borderColor: safe ? AppColors.pharmaNavy : AppColors.alertRed,
                          borderWidth: 3.5,
                          markerWidth: 18,
                          markerHeight: 18,
                        ),
                      ],
                      annotations: [
                        GaugeAnnotation(
                          angle: 90,
                          positionFactor: 0.08,
                          widget: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.suhu.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 34,
                                      height: 1.0,
                                      letterSpacing: -1,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text(
                                      '°C',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: AppColors.pharmaTeal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: (safe ? AppColors.activeGreen : AppColors.alertRed).withAlpha(18),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Text(
                                  safe ? 'Suhu Aman' : 'Di Luar Batas',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: safe ? AppColors.activeGreen : AppColors.alertRed,
                                  ),
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
            // Dial Min & Max Scale Row (Clean, no overlap)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${gaugeMin.toStringAsFixed(0)}°C',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${gaugeMax.toStringAsFixed(0)}°C',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Micro-Stats Strip (Substantial IoT monitoring)
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
                      'Target Rentang',
                      '${targetMin.toStringAsFixed(0)}–${targetMax.toStringAsFixed(0)}°C',
                    ),
                  ),
                  Container(height: 16, width: 1, color: AppColors.containerHigh),
                  Expanded(
                    child: _buildDialSubStat(
                      'Stabilitas',
                      safe ? 'Stabil Normal' : 'Fluktuasi',
                      isAlert: !safe,
                    ),
                  ),
                  Container(height: 16, width: 1, color: AppColors.containerHigh),
                  Expanded(
                    child: _buildDialSubStat(
                      'Sensor Pintu',
                      s.isPintuTerbuka ? 'Terbuka' : 'Terkunci',
                      isAlert: s.isPintuTerbuka,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    required SensorModel s,
    required SensorProvider p,
    required double humMin,
    required double humMax,
    required bool humOk,
  }) {
    return Column(
      children: [
        Row(
          children: [
            // Kelembapan Tile
            Expanded(
              child: _buildBentoMetricTile(
                icon: Icons.water_drop_outlined,
                iconColor: AppColors.humidityBlue,
                label: 'Kelembapan',
                value: '${s.kelembapan.toStringAsFixed(0)}%',
                targetText: 'Target ${humMin.toStringAsFixed(0)}–${humMax.toStringAsFixed(0)}%',
                isSafe: humOk,
                progressValue: (s.kelembapan / 100.0).clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Kadar Gas Tile
            Expanded(
              child: _buildBentoMetricTile(
                icon: Icons.cloud_outlined,
                iconColor: s.isGasBahaya ? AppColors.alertRed : AppColors.activeGreen,
                label: 'Kadar Gas',
                value: '${s.kadarGas.toStringAsFixed(0)} PPM',
                targetText: s.isGasBahaya ? 'Bahaya Asap' : 'Kondisi Bersih',
                isSafe: !s.isGasBahaya,
                progressValue: (s.kadarGas / p.gasMax).clamp(0.0, 1.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Door Security Bar
        Container(
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
    return Row(
      children: [
        // UV Sterilization Tile
        Expanded(
          child: _buildTactileActionCard(
            title: 'Sterilisasi UV-C',
            status: s.isUvMenyala ? 'Aktif (Steril)' : 'Mode Siaga',
            icon: Icons.cleaning_services_rounded,
            isActive: s.isUvMenyala,
            activeColor: AppColors.uvPurple,
            isRestricted: !p.isOperator,
            onTap: () {
              if (!p.isOperator) {
                _showOperatorOnlySnack(context);
                return;
              }
              p.toggleUv();
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Buzzer Alarm Tile
        Expanded(
          child: _buildTactileActionCard(
            title: 'Alarm Sirine',
            status: p.buzzerActive ? 'Alarm Berbunyi' : 'Siaga Darurat',
            icon: Icons.notifications_active_rounded,
            isActive: p.buzzerActive,
            activeColor: AppColors.warningAmber,
            isRestricted: !p.isOperator,
            onTap: () {
              if (!p.isOperator) {
                _showOperatorOnlySnack(context);
                return;
              }
              p.toggleBuzzer();
            },
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
