import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../models/sensor_model.dart';
import '../providers/sensor_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_loading.dart';

class RealtimePage extends StatelessWidget {
  const RealtimePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, child) {
        final sensor = provider.sensorData;
        final isConnected = provider.isConnected;
        final isLoading = provider.isInitialLoading;

        return Column(
          children: [
            // Segmented Device Switcher (Device 1 Sensor vs Device 2 Aktuator)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDeviceTab(
                      title: 'Node 1 (Suhu & Udara)',
                      subtitle: '3 Sensor · 3 Aktuator',
                      icon: Icons.thermostat_auto_rounded,
                      isSelected: provider.selectedDeviceId == 'device_1',
                      onTap: () => provider.selectDevice('device_1'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildDeviceTab(
                      title: 'Node 2 (UV & Keamanan)',
                      subtitle: '3 Sensor · 2 Aktuator',
                      icon: Icons.shield_rounded,
                      isSelected: provider.selectedDeviceId == 'device_2',
                      onTap: () => provider.selectDevice('device_2'),
                    ),
                  ),
                ],
              ),
            ),
            // Unobtrusive connection indicator
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md + 4,
                right: AppSpacing.md,
                top: AppSpacing.xs + 2,
                bottom: 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? AppColors.activeGreen : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected
                        ? 'ONLINE · terhubung ke MQTT'
                        : 'OFFLINE · data terakhir ${_formatLastUpdate(sensor.waktu)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isConnected ? AppColors.activeGreen : AppColors.alertRed,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    provider.selectedDeviceId == 'device_1'
                        ? 'DEV-1 (ESP32 Udara)'
                        : 'DEV-2 (ESP32 Steril)',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: isLoading
                  ? _buildLoadingSkeleton()
                  : _buildContent(context, provider, sensor, isConnected),
            ),
          ],
        );
      },
    );
  }

  String _formatLastUpdate(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return value;
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      children: [
        const ShimmerLoading(height: 100, radius: AppSpacing.radiusLg),
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            Expanded(child: ShimmerLoading(height: 90, radius: AppSpacing.radiusLg)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: ShimmerLoading(height: 90, radius: AppSpacing.radiusLg)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            Expanded(child: ShimmerLoading(height: 90, radius: AppSpacing.radiusLg)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: ShimmerLoading(height: 90, radius: AppSpacing.radiusLg)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const ShimmerLoading(height: 170, radius: AppSpacing.radiusLg),
      ],
    );
  }

  Widget _buildContent(BuildContext context, SensorProvider provider, SensorModel sensor, bool isConnected) {
    if (provider.selectedDeviceId == 'device_2') {
      return _buildActuatorNodeContent(context, provider, sensor, isConnected);
    }
    return _buildSensorNodeContent(context, provider, sensor, isConnected);
  }

  Widget _buildSensorNodeContent(BuildContext context, SensorProvider provider, SensorModel sensor, bool isConnected) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      children: [
        // Hero Header Card for Node 1
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.thermostat_auto_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemantauan Suhu & Udara (Node 1)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ESP32 • DHT22 · MQ-2 · LDR',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.pharmaNavy.withAlpha(180),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: Colors.white30, width: 0.8),
                ),
                child: const Text(
                  '3 SENSOR · 3 AKTUATOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 1. Gas & Smoke Metric Card (MQ-2)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: sensor.isGasBahaya ? AppColors.alertRed : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: sensor.isGasBahaya ? AppColors.alertRed : AppColors.containerHigh,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        sensor.isGasBahaya ? Icons.warning_amber_rounded : Icons.smoke_free_outlined,
                        color: sensor.isGasBahaya ? Colors.white : AppColors.pharmaNavy,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs + 4),
                      Text(
                        'Sensor Asap & Gas Bocor (MQ-2)',
                        style: TextStyle(
                          color: sensor.isGasBahaya ? Colors.white : AppColors.textDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: sensor.isGasBahaya
                          ? Colors.white
                          : (sensor.kadarGas > provider.gasMax * 0.6 ? AppColors.warningAmber : AppColors.activeGreen),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      sensor.kadarGas > provider.gasMax
                          ? 'BAHAYA'
                          : (sensor.kadarGas > provider.gasMax * 0.6 ? 'WASPADA' : 'NORMAL'),
                      style: AppTypography.badge.copyWith(
                        color: sensor.kadarGas > provider.gasMax ? AppColors.alertRed : Colors.white,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${sensor.kadarGas.toStringAsFixed(1)} PPM',
                    style: AppTypography.heading.copyWith(
                      fontSize: 22,
                      color: sensor.isGasBahaya ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Batas Maks: ${provider.gasMax.toStringAsFixed(0)} PPM',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: sensor.isGasBahaya ? Colors.white70 : AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. 2x2 Clean Sensor Metrics Grid
        Row(
          children: [
            // Suhu Storage (DHT22)
            Expanded(
              child: _buildMetricTile(
                title: 'Suhu Storage (DHT22)',
                value: '${sensor.suhu.toStringAsFixed(1)} °C',
                subtitle: 'Target: ${provider.tempMin.toStringAsFixed(0)}–${provider.tempMax.toStringAsFixed(0)}°C',
                icon: Icons.thermostat_outlined,
                valueColor: (sensor.suhu >= provider.tempMin && sensor.suhu <= provider.tempMax)
                    ? AppColors.textDark
                    : AppColors.alertRed,
                iconColor: AppColors.tempRed,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Kelembapan (DHT22)
            Expanded(
              child: _buildMetricTile(
                title: 'Kelembapan (DHT22)',
                value: '${sensor.kelembapan.toStringAsFixed(1)} %',
                subtitle: 'Target: ${provider.humidityMin.toStringAsFixed(0)}–${provider.humidityMax.toStringAsFixed(0)}%',
                icon: Icons.water_drop_outlined,
                valueColor: (sensor.kelembapan >= provider.humidityMin && sensor.kelembapan <= provider.humidityMax)
                    ? AppColors.textDark
                    : AppColors.alertRed,
                iconColor: AppColors.humidityBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            // Sensor 3: LDR Sensor Cahaya
            Expanded(
              child: _buildMetricTile(
                title: 'Sensor Cahaya (LDR)',
                value: '${sensor.cahaya.toStringAsFixed(0)} Lux',
                subtitle: sensor.cahaya < 80 ? 'Gudang Gelap (Aman)' : 'Cahaya Terang (Terbuka)',
                icon: Icons.light_mode_outlined,
                valueColor: AppColors.textDark,
                iconColor: AppColors.warningAmber,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Indikator Keselamatan / Api
            Expanded(
              child: _buildMetricTile(
                title: 'Status Kebakaran',
                value: sensor.isGasBahaya ? 'Bahaya Api!' : 'Aman',
                subtitle: sensor.isGasBahaya ? 'Asap Terdeteksi MQ-2' : 'Udara Bersih Optimal',
                icon: Icons.local_fire_department_outlined,
                valueColor: sensor.isGasBahaya ? AppColors.alertRed : AppColors.activeGreen,
                iconColor: sensor.isGasBahaya ? AppColors.alertRed : AppColors.activeGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.containerHigh, width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Gauge Suhu Ruang Obat',
                      style: AppTypography.subtitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 4,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pharmaNavy,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: const Text(
                      '°C',
                      textAlign: TextAlign.center,
                      style: AppTypography.badge,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 88,
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 12,
                      interval: 2,
                      startAngle: 180,
                      endAngle: 0,
                      canScaleToFit: true,
                      showTicks: true,
                      showLabels: true,
                      axisLineStyle: const AxisLineStyle(
                        thickness: 0.12,
                        thicknessUnit: GaugeSizeUnit.factor,
                        color: AppColors.containerLow,
                      ),
                      ranges: <GaugeRange>[
                        GaugeRange(
                          startValue: 0,
                          endValue: provider.tempMin,
                          color: const Color(0xFF94BBE9),
                          startWidth: 0.12,
                          endWidth: 0.12,
                          sizeUnit: GaugeSizeUnit.factor,
                        ),
                        GaugeRange(
                          startValue: provider.tempMin,
                          endValue: provider.tempMax,
                          color: AppColors.activeGreen,
                          startWidth: 0.12,
                          endWidth: 0.12,
                          sizeUnit: GaugeSizeUnit.factor,
                        ),
                        GaugeRange(
                          startValue: provider.tempMax,
                          endValue: 12,
                          color: AppColors.tempRed,
                          startWidth: 0.12,
                          endWidth: 0.12,
                          sizeUnit: GaugeSizeUnit.factor,
                        ),
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(
                          value: sensor.suhu,
                          needleColor: AppColors.pharmaNavy,
                          knobStyle: const KnobStyle(
                            color: AppColors.pharmaNavy,
                            borderColor: Colors.white,
                            borderWidth: 0.05,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${sensor.suhu.toStringAsFixed(1)} °C',
                style: AppTypography.heading.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                sensor.suhu >= provider.tempMin && sensor.suhu <= provider.tempMax
                    ? 'Standar Optimal (${provider.tempMin.toStringAsFixed(1)}-${provider.tempMax.toStringAsFixed(1)}°C)'
                    : 'Di Luar Batas Standar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sensor.suhu >= provider.tempMin && sensor.suhu <= provider.tempMax
                      ? AppColors.activeGreen
                      : AppColors.alertRed,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Panel Kontrol 3 Aktuator Node 1
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.containerHigh, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: AppColors.pharmaNavy, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Kontrol Aktuator (Device 1)',
                        style: AppTypography.subtitle,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.pharmaNavy.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: const Text('3 AKTUATOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.pharmaNavy)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Aktuator 1: Modul Relay Fan
              _buildActuatorRow(
                title: 'Relay 1: Fan / Kipas Darurat',
                subtitle: !provider.isOperator
                    ? 'Terkunci • Khusus akun Operator'
                    : (sensor.isKipasAktif ? 'Kipas Berputar • Pendinginan Aktif' : 'Nonaktif • Siaga Otomatis'),
                icon: Icons.mode_fan_off_rounded,
                isActive: sensor.isKipasAktif,
                activeColor: AppColors.pharmaTeal,
                onToggle: () {
                  if (!provider.isOperator) {
                    _showOperatorOnlySnack(context);
                    return;
                  }
                  provider.toggleKipas();
                },
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              // Aktuator 2: Sirine Buzzer Alarm
              _buildActuatorRow(
                title: 'Aktuator 2: Sirine Buzzer Alarm',
                subtitle: !provider.isOperator
                    ? 'Terkunci • Khusus akun Operator'
                    : (sensor.isBuzzerAktif || sensor.isGasBahaya ? 'Sirine Menyala • Peringatan Bahaya!' : 'Senyap • Kondisi Normal'),
                icon: Icons.notifications_active_rounded,
                isActive: sensor.isBuzzerAktif || sensor.isGasBahaya,
                activeColor: AppColors.alertRed,
                onToggle: () {
                  if (!provider.isOperator) {
                    _showOperatorOnlySnack(context);
                    return;
                  }
                  provider.toggleBuzzer();
                },
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              // Aktuator 3: Mini Water Pump
              _buildActuatorRow(
                title: 'Aktuator 3: Mini Water Pump',
                subtitle: !provider.isOperator
                    ? 'Terkunci • Khusus akun Operator'
                    : (sensor.isPompaAktif ? 'Pompa Menyala • Pemadam / Pendingin ON' : 'Nonaktif • Siaga Darurat'),
                icon: Icons.water_damage_rounded,
                isActive: sensor.isPompaAktif,
                activeColor: AppColors.pharmaBlue,
                onToggle: () {
                  if (!provider.isOperator) {
                    _showOperatorOnlySnack(context);
                    return;
                  }
                  provider.togglePompa();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Switch to Node 2 Hint Card
        InkWell(
          onTap: () => provider.selectDevice('device_2'),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.containerHigh, width: 1.0),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.pharmaNavy.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.pharmaNavy, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel Sterilisasi & Keamanan (Node 2)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'PIR, Pintu, Ultrasonik Stok, Lampu UV & LED Ruang.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTelemetryCard(
          isConnected: isConnected,
          nodeLabel: 'Node 1 (ESP32 Pemantau Udara) Aktif',
          topic: 'pharma/device1/sensor',
          onReconnect: () => provider.reconnect(),
        ),
      ],
    );
  }

  Widget _buildActuatorNodeContent(BuildContext context, SensorProvider provider, SensorModel sensor, bool isConnected) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      children: [
        // Hero Header Card for Node 2
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sterilisasi UV & Keamanan (Node 2)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ESP32 • PIR · Reed Switch · HC-SR04',
                      style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.uvPurple.withAlpha(180),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: Colors.white30, width: 0.8),
                ),
                child: const Text(
                  '3 SENSOR · 2 AKTUATOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 1. Sensor 1 & 2: PIR Gerak & Reed Switch Pintu
        Row(
          children: [
            // Sensor 1: PIR Pendeteksi Gerak Manusia
            Expanded(
              child: _buildMetricTile(
                title: 'Sensor Gerak (PIR)',
                value: sensor.isGerakTerdeteksi ? 'Ada Orang' : 'Kosong',
                subtitle: sensor.isGerakTerdeteksi ? 'UV Lock Aktif (Aman)' : 'Ruang Steril Kosong',
                icon: Icons.motion_photos_on_rounded,
                valueColor: sensor.isGerakTerdeteksi ? AppColors.alertRed : AppColors.activeGreen,
                iconColor: sensor.isGerakTerdeteksi ? AppColors.alertRed : AppColors.activeGreen,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Sensor 2: Reed Switch / Sensor Magnetik Pintu
            Expanded(
              child: _buildMetricTile(
                title: 'Pintu Gudang (Reed)',
                value: sensor.isPintuTerbuka ? 'Terbuka' : 'Tertutup',
                subtitle: sensor.isPintuTerbuka ? 'Akses Pintu Terbuka' : 'Terkunci Rapat (Aman)',
                icon: sensor.isPintuTerbuka ? Icons.door_sliding_outlined : Icons.lock_outline,
                valueColor: sensor.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen,
                iconColor: sensor.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Sensor 3: HC-SR04 Kapasitas Tumpukan Kardus Stok
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.containerHigh, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: AppColors.pharmaNavy, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Kapasitas Tumpukan Stok (HC-SR04)',
                        style: AppTypography.subtitle,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.pharmaNavy.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      sensor.teksKapasitasStok,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.pharmaNavy),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jarak Sensor: ${sensor.jarakStok.toStringAsFixed(1)} cm',
                    style: AppTypography.heading.copyWith(fontSize: 18),
                  ),
                  const Text(
                    'Ultrasonik Rak Kardus',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: LinearProgressIndicator(
                  value: (1.0 - (sensor.jarakStok / 60.0)).clamp(0.05, 1.0),
                  backgroundColor: AppColors.containerLow,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pharmaNavy),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Actuator 1: Modul Relay Lampu UV Sterilisasi
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: sensor.isUvMenyala ? AppColors.uvPurple.withAlpha(120) : AppColors.containerHigh,
              width: 1.0,
            ),
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
                          color: AppColors.uvPurple.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cleaning_services_rounded, color: AppColors.uvPurple, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('Aktuator 1: Lampu UV Sterilisasi', style: AppTypography.subtitle),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.uvPurple.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: const Text('Relay 1-Channel', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.uvPurple)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              _buildActuatorRow(
                title: 'Saklar Daya Lampu UV',
                subtitle: !provider.isOperator
                    ? 'Terkunci • Khusus akun Operator'
                    : (sensor.isGerakTerdeteksi
                        ? 'Terkunci Otomatis (Ada Manusia)'
                        : (sensor.isUvMenyala ? 'Aktif • Radiasi Sterilisasi ON' : 'Nonaktif • Mode Standby (Aman)')),
                icon: Icons.lightbulb_outline_rounded,
                isActive: sensor.isUvMenyala,
                activeColor: AppColors.uvPurple,
                onToggle: () {
                  if (!provider.isOperator) {
                    _showOperatorOnlySnack(context);
                    return;
                  }
                  provider.toggleUv();
                },
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              const Text(
                'Simulasi lampu sterilisator UV ruangan. Otomatis mati jika terdeteksi manusia di dalam.',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Actuator 2: LED RGB / Biasa Indikator Ruangan
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: sensor.isLedBahaya ? AppColors.alertRed.withAlpha(120) : AppColors.containerHigh,
              width: 1.0,
            ),
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
                          color: (sensor.isLedBahaya ? AppColors.alertRed : AppColors.activeGreen).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.traffic_rounded,
                          color: sensor.isLedBahaya ? AppColors.alertRed : AppColors.activeGreen,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('Aktuator 2: LED Indikator Ruang', style: AppTypography.subtitle),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (sensor.isLedBahaya ? AppColors.alertRed : AppColors.activeGreen).withAlpha(20),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      sensor.isLedBahaya ? 'MERAH (BAHAYA/UV)' : 'HIJAU (AMAN)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: sensor.isLedBahaya ? AppColors.alertRed : AppColors.activeGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              _buildActuatorRow(
                title: 'Indikator Akses Ruangan',
                subtitle: !provider.isOperator
                    ? 'Terkunci • Khusus akun Operator'
                    : (sensor.isLedBahaya ? 'Status: Merah (Jangan Masuk / Proses UV)' : 'Status: Hijau (Aman Dimasuki Staf)'),
                icon: Icons.lightbulb_rounded,
                isActive: sensor.isLedBahaya,
                activeColor: AppColors.alertRed,
                onToggle: () {
                  if (!provider.isOperator) {
                    _showOperatorOnlySnack(context);
                    return;
                  }
                  provider.toggleLed();
                },
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              const Text(
                'Indikator visual bagi personil di depan pintu untuk mengetahui keamanan ruangan.',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Safety Interlock Diagram Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: (sensor.isGerakTerdeteksi || sensor.isPintuTerbuka)
                ? AppColors.alertRed.withAlpha(15)
                : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: (sensor.isGerakTerdeteksi || sensor.isPintuTerbuka)
                  ? AppColors.alertRed
                  : AppColors.containerHigh,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    (sensor.isGerakTerdeteksi || sensor.isPintuTerbuka)
                        ? Icons.shield_rounded
                        : Icons.verified_user_outlined,
                    color: (sensor.isGerakTerdeteksi || sensor.isPintuTerbuka)
                        ? AppColors.alertRed
                        : AppColors.pharmaNavy,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs + 4),
                  Text(
                    'Interlock Keselamatan UV Manusia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: (sensor.isGerakTerdeteksi || sensor.isPintuTerbuka)
                          ? AppColors.alertRed
                          : AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sensor.isGerakTerdeteksi
                    ? 'PROTEKSI AKTIF: Sensor PIR mendeteksi personil manusia di dalam ruangan. Lampu UV otomatis terkunci MATI untuk mencegah radiasi mata dan kulit.'
                    : (sensor.isPintuTerbuka
                        ? 'PERINGATAN: Pintu gudang terbuka. Radiasi UV dinonaktifkan agar tidak terpapar ke koridor luar.'
                        : 'SISTEM AMAN: Ruangan kosong dan pintu tertutup rapat. Proses sterilisasi UV dapat dijalankan dengan aman.'),
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: (sensor.isGerakTerdeteksi || sensor.isPintuTerbuka)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: (sensor.isGerakTerdeteksi || sensor.isPintuTerbuka)
                      ? AppColors.alertRed
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Hint to Switch to Node 1
        InkWell(
          onTap: () => provider.selectDevice('device_1'),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.containerHigh, width: 1.0),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.pharmaNavy.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.thermostat_auto_rounded, color: AppColors.pharmaNavy, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monitoring Suhu & Udara (Node 1)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'DHT22, MQ-2, LDR, Kipas, Buzzer, dan Pompa di Node 1.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _buildTelemetryCard(
          isConnected: isConnected,
          nodeLabel: 'Node 2 (ESP32 Steril & Keamanan) Aktif',
          topic: 'pharma/device2/sensor',
          onReconnect: () => provider.reconnect(),
        ),
      ],
    );
  }

  Widget _buildTelemetryCard({
    required bool isConnected,
    required String nodeLabel,
    required String topic,
    required VoidCallback onReconnect,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.pharmaNavy,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.activeGreen : AppColors.alertRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? nodeLabel : 'Terputus dari Broker MQTT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FutureBuilder<String>(
                  future: StorageService().getServerIp(),
                  builder: (context, snapshot) {
                    final ip = snapshot.data ?? '127.0.0.1';
                    return Text(
                      '$ip:1883 • Topik: $topic',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onReconnect,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pharmaNavy : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.pharmaNavy : AppColors.containerHigh,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.pharmaNavy.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : AppColors.pharmaNavy,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFF94A3B8) : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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

  Widget _buildActuatorRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withAlpha(12) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isActive ? activeColor.withAlpha(90) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isActive ? activeColor.withAlpha(25) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? activeColor : AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isActive ? activeColor : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isActive,
              onChanged: (_) => onToggle(),
              activeThumbColor: activeColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color valueColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.containerHigh, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.heading.copyWith(
              fontSize: 16,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
