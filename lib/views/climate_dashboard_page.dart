import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../models/sensor_model.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/botanic_vector_decor.dart';
import '../widgets/shimmer_loading.dart';

class ClimateDashboardPage extends StatelessWidget {
  const ClimateDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => Consumer<SensorProvider>(
        builder: (context, provider, child) => provider.isInitialLoading
            ? _loading()
            : _dashboard(provider, provider.sensorData),
      );

  Widget _loading() => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          ShimmerLoading(height: 48, radius: AppSpacing.radiusSm),
          SizedBox(height: AppSpacing.md),
          ShimmerLoading(height: 170, radius: AppSpacing.radiusMd),
          SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: ShimmerLoading(height: 130, radius: AppSpacing.radiusMd)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: ShimmerLoading(height: 130, radius: AppSpacing.radiusMd)),
          ]),
        ],
      );

  Widget _dashboard(SensorProvider p, SensorModel s) {
    final targetMin = p.currentTempMin;
    final targetMax = p.currentTempMax;
    final humMin = p.currentHumidityMin;
    final humMax = p.currentHumidityMax;

    final tempOk = s.suhu >= targetMin && s.suhu <= targetMax;
    final humOk = s.kelembapan >= humMin && s.kelembapan <= humMax;
    final safe = tempOk && humOk && !s.isGasBahaya && !s.isPintuTerbuka;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      children: [
        _selector(p),
        const SizedBox(height: AppSpacing.md),
        _insight(safe, s, p, targetMin, targetMax),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: _metric(Icons.thermostat_rounded, 'Suhu', '${s.suhu.toStringAsFixed(1)}°C', 'Target ${targetMin.toStringAsFixed(0)}-${targetMax.toStringAsFixed(0)}°C', tempOk ? AppColors.pharmaBlue : AppColors.alertRed)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _metric(Icons.water_drop_outlined, 'Kelembapan', '${s.kelembapan.toStringAsFixed(0)}%', 'Target ${humMin.toStringAsFixed(0)}-${humMax.toStringAsFixed(0)}%', humOk ? AppColors.humidityBlue : AppColors.alertRed)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Expanded(child: _metric(s.isPintuTerbuka ? Icons.door_sliding_outlined : Icons.lock_outline, 'Pintu', s.isPintuTerbuka ? 'Terbuka' : 'Tertutup', s.isPintuTerbuka ? 'Perlu ditutup' : 'Terkunci rapat', s.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _metric(Icons.co2_outlined, 'Gas/Asap', '${s.kadarGas.toStringAsFixed(0)} PPM', 'Batas ${p.gasMax.toStringAsFixed(0)} PPM', s.isGasBahaya ? AppColors.alertRed : AppColors.activeGreen)),
        ]),
        const SizedBox(height: AppSpacing.md),
        _temperatureGauge(s, p, tempOk, targetMin, targetMax),
        const SizedBox(height: AppSpacing.md),
        _automation(Icons.cleaning_services_outlined, 'Sterilisasi UV', s.isUvMenyala ? 'Sterilisasi sedang berjalan' : 'Mode siaga', s.isUvMenyala, AppColors.uvPurple, p.toggleUv),
        const SizedBox(height: AppSpacing.sm),
        _automation(Icons.notifications_active_outlined, 'Buzzer dan LED alarm', p.buzzerActive ? 'Alarm aktif' : 'Aktifkan bila diperlukan', p.buzzerActive, AppColors.pharmaBlue, p.toggleBuzzer),
        const SizedBox(height: AppSpacing.md),
        _connection(p),
      ],
    );
  }

  Widget _selector(SensorProvider p) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: _cardShadow,
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
            height: 42,
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

  Widget _insight(bool safe, SensorModel s, SensorProvider p, double targetMin, double targetMax) {
    final safeText = p.isVaccineRack
        ? 'Suhu penyimpanan vaksin aman.'
        : 'Kondisi ruang steril optimal.';
    final alertText = p.isVaccineRack
        ? 'Suhu vaksin di luar batas ${targetMin.toStringAsFixed(0)}-${targetMax.toStringAsFixed(0)}°C.'
        : 'Suhu ruang steril di luar batas ${targetMin.toStringAsFixed(0)}-${targetMax.toStringAsFixed(0)}°C.';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: _cardShadow,
      ),
      child: BotanicVectorCardWatermark(
        size: 130,
        opacity: 0.045,
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('RINGKASAN SAAT INI', style: _section),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (safe ? AppColors.activeGreen : AppColors.alertRed).withAlpha(24),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    p.isVaccineRack ? 'COLD STORAGE' : 'CLEANROOM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: safe ? AppColors.activeGreen : AppColors.alertRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              safe ? safeText : alertText,
              style: TextStyle(
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: safe ? AppColors.pharmaNavy : AppColors.alertRed,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(child: _smallStat('Target suhu', '${targetMin.toStringAsFixed(0)}-${targetMax.toStringAsFixed(0)}°C')),
              Container(height: 30, width: 1, color: AppColors.containerHigh),
              Expanded(child: _smallStat('Status pintu', s.isPintuTerbuka ? 'Terbuka' : 'Tertutup')),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _smallStat(String a, String b) => Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a, style: AppTypography.caption), const SizedBox(height: 3), Text(b, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark))]));

  Widget _metric(IconData icon, String label, String value, String detail, Color color) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: _cardShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)), child: Icon(icon, color: color, size: 19)),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(detail, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
        ]),
      );

  Widget _temperatureGauge(SensorModel s, SensorProvider p, bool safe, double targetMin, double targetMax) {
    final double gaugeMin = p.isVaccineRack ? 0.0 : 10.0;
    final double gaugeMax = p.isVaccineRack ? 12.0 : 35.0;

    final targetDesc = p.isVaccineRack
        ? (safe ? 'Suhu penyimpanan vaksin dalam batas aman' : 'Peringatan: Suhu vaksin di luar rentang aman!')
        : (safe ? 'Kondisi suhu ruang steril optimal' : 'Peringatan: Suhu ruang steril di luar batas!');

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md + 4, AppSpacing.md, AppSpacing.md + 4, AppSpacing.md + 4),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: _cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('STABILITAS SUHU', style: _section),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.containerLow, width: 0.8),
              ),
              child: Text(
                'Target ${targetMin.toStringAsFixed(0)}°C – ${targetMax.toStringAsFixed(0)}°C',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pharmaNavy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: RepaintBoundary(
            child: SfRadialGauge(
              axes: [
                RadialAxis(
                  minimum: gaugeMin,
                  maximum: gaugeMax,
                  startAngle: 170,
                  endAngle: 10,
                  showTicks: false,
                  showLabels: false,
                  radiusFactor: 0.95,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 14,
                    cornerStyle: CornerStyle.bothCurve,
                    color: AppColors.containerLow,
                  ),
                  ranges: [
                    // Target safe zone subtle highlight
                    GaugeRange(
                      startValue: targetMin,
                      endValue: targetMax,
                      color: AppColors.activeGreen.withAlpha(50),
                      startWidth: 14,
                      endWidth: 14,
                      sizeUnit: GaugeSizeUnit.logicalPixel,
                    ),
                  ],
                  pointers: [
                    // Modern gradient active range fill
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
                    // Elegant circular knob at current value
                    MarkerPointer(
                      value: s.suhu.clamp(gaugeMin, gaugeMax),
                      markerType: MarkerType.circle,
                      color: Colors.white,
                      borderColor: safe ? AppColors.pharmaNavy : AppColors.alertRed,
                      borderWidth: 3.5,
                      markerWidth: 20,
                      markerHeight: 20,
                    ),
                  ],
                  annotations: [
                    GaugeAnnotation(
                      angle: 90,
                      positionFactor: 0.22,
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
                                  color: AppColors.pharmaNavy,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Text(
                                '°C',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.pharmaTeal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: (safe ? AppColors.activeGreen : AppColors.alertRed).withAlpha(22),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: safe ? AppColors.activeGreen : AppColors.alertRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  safe ? 'Suhu Optimal' : 'Suhu Anomali',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: safe ? AppColors.activeGreen : AppColors.alertRed,
                                  ),
                                ),
                              ],
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
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${gaugeMin.toStringAsFixed(0)}°C', style: AppTypography.caption),
              Text(
                targetDesc,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: safe ? AppColors.pharmaNavy.withAlpha(200) : AppColors.alertRed,
                ),
              ),
              Text('${gaugeMax.toStringAsFixed(0)}°C', style: AppTypography.caption),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _automation(IconData icon, String title, String sub, bool on, Color color, VoidCallback tap) => InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: _cardShadow,
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)), child: Icon(icon, color: color)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)), const SizedBox(height: 2), Text(sub, style: AppTypography.caption)])),
            Switch(value: on, onChanged: (_) => tap(), activeThumbColor: color),
          ]),
        ),
      );

  Widget _connection(SensorProvider p) {
    final online = p.isConnected;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: online ? const Color(0xFFE2F2EC) : const Color(0xFFFCE8E8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(children: [
        Icon(online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, color: online ? AppColors.activeGreen : AppColors.alertRed),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(online ? 'Broker MQTT terhubung. Telemetri masuk langsung.' : 'Broker MQTT terputus. Menampilkan data terakhir.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark))),
        IconButton(onPressed: p.reconnect, icon: const Icon(Icons.refresh_rounded, color: AppColors.pharmaNavy)),
      ]),
    );
  }
}

const List<BoxShadow> _cardShadow = [
  BoxShadow(
    color: Color(0x140E555A),
    blurRadius: 14,
    offset: Offset(0, 4),
  ),
];

const TextStyle _section = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.8);
