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
            // Segmented Device Switcher (Rak A vs Rak B)
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
                      title: 'Rak A (Vaksin)',
                      subtitle: 'Suhu 2°C – 8°C',
                      icon: Icons.ac_unit_rounded,
                      isSelected: provider.selectedDeviceId == 'device_1',
                      onTap: () => provider.selectDevice('device_1'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildDeviceTab(
                      title: 'Rak B (Steril)',
                      subtitle: 'Suhu 15°C – 25°C',
                      icon: Icons.wb_sunny_outlined,
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
                    provider.selectedDeviceId == 'device_1' ? 'DEV-1 (Chiller)' : 'DEV-2 (Steril)',
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
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      children: [
        // 1. Gas Metric Card (Clean & uncluttered)
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
                        sensor.isGasBahaya ? Icons.warning_amber_rounded : Icons.co2_outlined,
                        color: sensor.isGasBahaya ? Colors.white : AppColors.pharmaNavy,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs + 4),
                      Text(
                        'Kadar Gas & Udara',
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
                    'Batas: ${provider.gasMax.toStringAsFixed(0)} PPM',
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
            // Pintu Gudang
            Expanded(
              child: _buildMetricTile(
                title: 'Pintu Gudang',
                value: sensor.isPintuTerbuka ? 'Terbuka' : 'Tertutup',
                subtitle: sensor.isPintuTerbuka ? 'Perlu Ditutup' : 'Terkunci Rapat',
                icon: sensor.isPintuTerbuka ? Icons.door_sliding_outlined : Icons.lock_outline,
                valueColor: sensor.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen,
                iconColor: sensor.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Sterilisasi UV
            Expanded(
              child: _buildMetricTile(
                title: 'Sterilisasi UV',
                value: sensor.isUvMenyala ? 'Aktif' : 'Nonaktif',
                subtitle: sensor.isUvMenyala ? 'Sterilisasi ON' : 'Mode Standby',
                icon: Icons.cleaning_services_outlined,
                valueColor: sensor.isUvMenyala ? AppColors.uvPurple : AppColors.textDark,
                iconColor: sensor.isUvMenyala ? AppColors.uvPurple : AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            // Suhu Storage
            Expanded(
              child: _buildMetricTile(
                title: 'Suhu Storage',
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
            // Kelembapan
            Expanded(
              child: _buildMetricTile(
                title: 'Kelembapan',
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
        const SizedBox(height: AppSpacing.md - 2),
        // Actuator Control Card (Syarat Aktuator minimal 2: Buzzer/LED + Aktuator Lain)
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
                        'Kontrol Aktuator Cepat',
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
                      provider.selectedDeviceId == 'device_1' ? 'DEV-1' : 'DEV-2',
                      style: AppTypography.badge.copyWith(color: AppColors.pharmaNavy, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildActuatorRow(
                title: 'Lampu Sterilisasi UV',
                subtitle: sensor.isUvMenyala ? 'Aktif • Sedang Sterilisasi' : 'Nonaktif • Mode Standby',
                icon: Icons.cleaning_services_rounded,
                isActive: sensor.isUvMenyala,
                activeColor: AppColors.uvPurple,
                onToggle: () => provider.toggleUv(),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _buildActuatorRow(
                title: 'Buzzer & LED Alarm',
                subtitle: provider.buzzerActive ? 'Alarm Bunyi • Peringatan' : 'Senyap • Kondisi Normal',
                icon: Icons.notifications_active_rounded,
                isActive: provider.buzzerActive,
                activeColor: AppColors.alertRed,
                onToggle: () => provider.toggleBuzzer(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Unified Telemetri & Status Keamanan Card
        Container(
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
                      isConnected ? 'Sistem Terhubung • Status Aman' : 'Terputus dari Broker',
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
                          '$ip:1883 • Topik: pharma/sensor',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => provider.reconnect(),
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
        ),
      ],
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
