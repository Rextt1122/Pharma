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
    final tempOk = s.suhu >= p.tempMin && s.suhu <= p.tempMax;
    final humOk = s.kelembapan >= p.humidityMin && s.kelembapan <= p.humidityMax;
    final safe = tempOk && humOk && !s.isGasBahaya && !s.isPintuTerbuka;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      children: [
        _selector(p),
        const SizedBox(height: AppSpacing.md),
        _insight(safe, s, p),
        const SizedBox(height: AppSpacing.md),
        _protectionCard(s),
        const SizedBox(height: AppSpacing.lg),
        const Text('KONDISI RUANGAN', style: _section),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Expanded(child: _metric(Icons.thermostat_rounded, 'Suhu saat ini', '${s.suhu.toStringAsFixed(1)}°C', 'Target ${p.tempMin.toStringAsFixed(0)}-${p.tempMax.toStringAsFixed(0)}°C', tempOk ? AppColors.pharmaBlue : AppColors.alertRed)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _metric(Icons.water_drop_outlined, 'Kelembapan', '${s.kelembapan.toStringAsFixed(0)}%', 'Target ${p.humidityMin.toStringAsFixed(0)}-${p.humidityMax.toStringAsFixed(0)}%', humOk ? AppColors.humidityBlue : AppColors.alertRed)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Expanded(child: _metric(s.isPintuTerbuka ? Icons.door_sliding_outlined : Icons.lock_outline, 'Pintu gudang', s.isPintuTerbuka ? 'Terbuka' : 'Tertutup', s.isPintuTerbuka ? 'Perlu ditutup' : 'Terkunci rapat', s.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _metric(Icons.co2_outlined, 'Gas dan asap', '${s.kadarGas.toStringAsFixed(0)} PPM', 'Batas ${p.gasMax.toStringAsFixed(0)} PPM', s.isGasBahaya ? AppColors.alertRed : AppColors.activeGreen)),
        ]),
        const SizedBox(height: AppSpacing.md),
        _temperatureGauge(s, p, tempOk),
        const SizedBox(height: AppSpacing.lg),
        const Text('AUTOMASI CEPAT', style: _section),
        const SizedBox(height: AppSpacing.sm),
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
        decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(AppSpacing.radiusSm), border: Border.all(color: AppColors.containerHigh)),
        child: Row(children: [
          _tab('Rak Vaksin', p.selectedDeviceId == 'device_1', () => p.selectDevice('device_1')),
          _tab('Ruang Steril', p.selectedDeviceId == 'device_2', () => p.selectDevice('device_2')),
        ]),
      );

  Widget _tab(String label, bool on, VoidCallback tap) => Expanded(child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(AppSpacing.radiusSm), child: AnimatedContainer(duration: const Duration(milliseconds: 180), height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: on ? AppColors.pharmaBlue : Colors.transparent, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)), child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: on ? Colors.white : AppColors.textMuted)))));

  Widget _insight(bool safe, SensorModel s, SensorProvider p) => Container(
        padding: const EdgeInsets.all(AppSpacing.md + 4),
        decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.containerHigh)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('RINGKASAN SAAT INI', style: _section),
          const SizedBox(height: AppSpacing.sm),
          Text(safe ? 'Rantai dingin dalam kondisi aman.' : 'Perlu pemeriksaan kondisi gudang.', style: const TextStyle(fontSize: 21, height: 1.2, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: _smallStat('Batas suhu', '${p.tempMin.toStringAsFixed(0)}-${p.tempMax.toStringAsFixed(0)}°C')),
            Container(height: 30, width: 1, color: AppColors.containerHigh),
            Expanded(child: _smallStat('Status pintu', s.isPintuTerbuka ? 'Terbuka' : 'Tertutup')),
          ]),
        ]),
      );

  Widget _smallStat(String a, String b) => Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a, style: AppTypography.caption), const SizedBox(height: 3), Text(b, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark))]));

  Widget _protectionCard(SensorModel s) {
    final danger = s.isGasBahaya;
    return Container(padding: const EdgeInsets.all(AppSpacing.md + 4), decoration: BoxDecoration(color: danger ? AppColors.alertRed : AppColors.pharmaBlue, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: Row(children: [const Icon(Icons.shield_outlined, color: Colors.white, size: 34), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(danger ? 'Gas atau asap terdeteksi' : 'Sistem perlindungan aktif', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(danger ? 'Periksa ventilasi dan sumber asap.' : 'Sensor, alarm, dan notifikasi siap merespons.', style: const TextStyle(color: Color(0xFFFFF0ED), fontSize: 12))]))]));
  }

  Widget _metric(IconData icon, String label, String value, String detail, Color color) => Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: const Color(0xFFFBECE9), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)), child: Icon(icon, color: color, size: 19)), const SizedBox(height: AppSpacing.md), Text(value, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark)), const SizedBox(height: 2), Text(detail, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)]));

  Widget _temperatureGauge(SensorModel s, SensorProvider p, bool safe) => Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md + 4, AppSpacing.md, AppSpacing.md + 4, AppSpacing.md + 4),
        decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.containerHigh)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('STABILITAS SUHU', style: _section),
          SizedBox(
            height: 150,
            child: SfRadialGauge(axes: [
              RadialAxis(
                minimum: 0,
                maximum: 12,
                interval: 2,
                startAngle: 180,
                endAngle: 0,
                showTicks: false,
                showLabels: true,
                axisLineStyle: const AxisLineStyle(thickness: 0.14, thicknessUnit: GaugeSizeUnit.factor, color: AppColors.containerLow),
                ranges: [
                  GaugeRange(startValue: 0, endValue: p.tempMin, color: const Color(0xFF9EC5DA), startWidth: 0.14, endWidth: 0.14, sizeUnit: GaugeSizeUnit.factor),
                  GaugeRange(startValue: p.tempMin, endValue: p.tempMax, color: AppColors.activeGreen, startWidth: 0.14, endWidth: 0.14, sizeUnit: GaugeSizeUnit.factor),
                  GaugeRange(startValue: p.tempMax, endValue: 12, color: AppColors.pharmaBlue, startWidth: 0.14, endWidth: 0.14, sizeUnit: GaugeSizeUnit.factor),
                ],
                pointers: [NeedlePointer(value: s.suhu, needleColor: AppColors.pharmaBlue, knobStyle: const KnobStyle(color: AppColors.pharmaBlue, borderColor: Colors.white, borderWidth: 0.05))],
                annotations: [GaugeAnnotation(widget: Text('${s.suhu.toStringAsFixed(1)}°C', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.textDark)), angle: 90, positionFactor: 0.58)],
              ),
            ]),
          ),
          Center(child: Text(safe ? 'Suhu berada dalam batas penyimpanan vaksin.' : 'Suhu di luar batas penyimpanan.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: safe ? AppColors.activeGreen : AppColors.alertRed))),
        ]),
      );

  Widget _automation(IconData icon, String title, String sub, bool on, Color color, VoidCallback tap) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), child: Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.containerHigh)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)), child: Icon(icon, color: color)), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)), const SizedBox(height: 2), Text(sub, style: AppTypography.caption)])), Switch(value: on, onChanged: (_) => tap(), activeThumbColor: color)])));

  Widget _connection(SensorProvider p) {
    final online = p.isConnected;
    return Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: online ? const Color(0xFFE8F3EC) : const Color(0xFFFBECE9), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: Row(children: [Icon(online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, color: online ? AppColors.activeGreen : AppColors.alertRed), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(online ? 'Broker MQTT terhubung. Telemetri masuk langsung.' : 'Broker MQTT terputus. Menampilkan data terakhir.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark))), IconButton(onPressed: p.reconnect, icon: const Icon(Icons.refresh_rounded, color: AppColors.textDark))]));
  }
}

const TextStyle _section = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.8);
