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
            // Connection status badge at top
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.sm,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: isConnected ? AppColors.activeGreen : AppColors.alertRed,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isConnected ? 'Terhubung ke Broker MQTT' : 'Offline - Tidak dapat terhubung',
                    style: AppTypography.badge.copyWith(
                      color: Colors.white,
                      fontSize: 12,
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

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm + 4,
        bottom: AppSpacing.xl * 3,
      ),
      children: [
        // Gas skeleton
        const ShimmerLoading(height: 140, radius: AppSpacing.radiusLg),
        const SizedBox(height: AppSpacing.md - 2),
        // Door + Notification skeletons
        const Row(
          children: [
            Expanded(child: ShimmerLoading(height: 100, radius: AppSpacing.radiusLg)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: ShimmerLoading(height: 100, radius: AppSpacing.radiusLg)),
          ],
        ),
        const SizedBox(height: AppSpacing.md - 2),
        // Temperature gauge skeleton
        const ShimmerLoading(height: 180, radius: AppSpacing.radiusLg),
        const SizedBox(height: AppSpacing.md - 2),
        // Humidity gauge skeleton
        const ShimmerLoading(height: 180, radius: AppSpacing.radiusLg),
      ],
    );
  }

  Widget _buildContent(BuildContext context, SensorProvider provider, SensorModel sensor, bool isConnected) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm + 4,
        bottom: AppSpacing.xl * 3,
      ),
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          decoration: BoxDecoration(
            color: sensor.isGasBahaya ? AppColors.alertRed : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: sensor.isGasBahaya ? AppColors.alertRed : const Color(0xFFCBD5E1),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          sensor.isGasBahaya ? Icons.warning_amber_rounded : Icons.co2_outlined,
                          color: sensor.isGasBahaya ? Colors.white : AppColors.textDark,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs + 4),
                        Flexible(
                          child: Text(
                            'Kadar Gas / Asap Gudang',
                            style: TextStyle(
                              color: sensor.isGasBahaya ? Colors.white : AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 4,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: sensor.isGasBahaya ? Colors.white : (sensor.kadarGas > 30 ? AppColors.warningAmber : AppColors.activeGreen),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      sensor.kadarGas > provider.gasMax
                          ? 'BAHAYA'
                          : (sensor.kadarGas > provider.gasMax * 0.6 ? 'WASPADA' : 'NORMAL'),
                      textAlign: TextAlign.center,
                      style: AppTypography.badge.copyWith(
                        color: sensor.kadarGas > provider.gasMax ? AppColors.alertRed : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sensor.kadarGas.toStringAsFixed(1)} PPM',
                    style: AppTypography.heading.copyWith(
                      fontSize: 24,
                      color: sensor.isGasBahaya ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      sensor.isGasBahaya ? 'Terdeteksi Kebocoran Gas!' : 'Kualitas Udara Aman',
                      style: TextStyle(
                        fontSize: 12,
                        color: sensor.isGasBahaya ? Colors.white70 : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          sensor.isPintuTerbuka ? Icons.door_sliding_outlined : Icons.lock_outline,
                          color: sensor.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        const Flexible(
                          child: Text(
                            'Pintu Gudang',
                            style: AppTypography.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    Text(
                      sensor.isPintuTerbuka ? 'Terbuka' : 'Tertutup',
                      style: AppTypography.heading.copyWith(
                        fontSize: 17,
                        color: sensor.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      sensor.teksPintu,
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cleaning_services_outlined,
                          color: sensor.isUvMenyala ? AppColors.uvPurple : AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        const Flexible(
                          child: Text(
                            'Sterilisasi UV',
                            style: AppTypography.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    Text(
                      sensor.isUvMenyala ? 'Menyala' : 'Mati',
                      style: AppTypography.heading.copyWith(
                        fontSize: 17,
                        color: sensor.isUvMenyala ? AppColors.uvPurple : AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      sensor.teksUv,
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md - 2),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.thermostat_outlined, color: AppColors.pharmaNavy, size: 18),
                        SizedBox(width: AppSpacing.xs + 2),
                        Flexible(
                          child: Text(
                            'Suhu Storage',
                            style: AppTypography.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    Text(
                      '${sensor.suhu.toStringAsFixed(1)} °C',
                      style: AppTypography.heading.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      sensor.suhu < provider.tempMin
                          ? 'Terlalu Cold'
                          : (sensor.suhu <= provider.tempMax ? 'Standar Obat' : 'Suhu Tinggi'),
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.water_drop_outlined, color: AppColors.pharmaBlue, size: 18),
                        SizedBox(width: AppSpacing.xs + 2),
                        Flexible(
                          child: Text(
                            'Kelembapan',
                            style: AppTypography.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    Text(
                      '${sensor.kelembapan.toStringAsFixed(1)} %',
                      style: AppTypography.heading.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      sensor.kelembapan < provider.humidityMin
                          ? 'Kering'
                          : (sensor.kelembapan <= provider.humidityMax ? 'Standar Farmasi' : 'Lembap'),
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md - 2),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
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
                height: 115,
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: -10,
                      maximum: 50,
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
                          startValue: -10,
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
                          endValue: 50,
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
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.pharmaNavy,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.pharmaNavy, width: 1.0),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
                    SizedBox(width: AppSpacing.sm + 2),
                    Flexible(
                      child: Text(
                        'Status Keamanan',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: sensor.isGasBahaya || sensor.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  sensor.isGasBahaya || sensor.isPintuTerbuka ? 'BAHAYA' : 'AMAN & STERIL',
                  textAlign: TextAlign.center,
                  style: AppTypography.badge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.pharmaNavy,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.pharmaNavy, width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.activeGreen : AppColors.alertRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'Sistem Telemetri Gudang Aktif' : 'Terputus dari Broker',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    FutureBuilder<String>(
                      future: StorageService().getServerIp(),
                      builder: (context, snapshot) {
                        final ip = snapshot.data ?? '...';
                        return Text(
                          '$ip : 1883 • pharma/sensor',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              InkWell(
                onTap: () => provider.reconnect(),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
