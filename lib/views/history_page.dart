import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_model.dart';
import '../providers/history_provider.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_trend_chart.dart';
import '../widgets/shimmer_loading.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: () => provider.fetchHistory(),
            child: _buildBody(context, provider),
          ),
          floatingActionButton: SizedBox(
            height: 38,
            child: FloatingActionButton.extended(
              onPressed: provider.historyList.isEmpty
                  ? null
                  : () async {
                      try {
                        final path = await provider.exportToCsv();
                        if (path != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Berhasil diexport ke:\n$path'),
                              duration: const Duration(seconds: 4),
                              backgroundColor: AppColors.pharmaNavy,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      }
                    },
              elevation: 2,
              highlightElevation: 3,
              backgroundColor: AppColors.pharmaNavy,
              icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 16),
              label: const Text(
                'Export CSV',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HistoryProvider provider) {
    return Consumer<SensorProvider>(
      builder: (context, sensorProvider, child) {
        if (provider.isLoading) {
          return _buildLoadingSkeleton();
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pharmaNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md - 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                    onPressed: () => provider.fetchHistory(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text(
                      'Coba Lagi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.historyList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Belum ada data log gudang farmasi.',
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pharmaNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md - 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  onPressed: () => provider.fetchHistory(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text(
                    'Muat Ulang',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final double avgSuhu = provider.historyList.map((e) => e.suhu).reduce((a, b) => a + b) / provider.historyList.length;
        final double avgGas = provider.historyList.map((e) => e.kadarGas).reduce((a, b) => a + b) / provider.historyList.length;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.sm + 4,
            bottom: 72,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricPillCard(
                    title: 'Total Log',
                    value: '${provider.historyList.length}',
                    dotColor: AppColors.pharmaNavy,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricPillCard(
                    title: 'Rata Suhu',
                    value: '${avgSuhu.toStringAsFixed(1)} °C',
                    dotColor: AppColors.tempRed,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricPillCard(
                    title: 'Rata Gas',
                    value: '${avgGas.toStringAsFixed(1)} PPM',
                    dotColor: AppColors.warningAmber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SensorTrendChart(historyData: provider.historyList),
            const SizedBox(height: AppSpacing.md + 2),
            Row(
              children: [
                const Text(
                  'Catatan Terkini',
                  style: AppTypography.subtitle,
                ),
                const Spacer(),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.pharmaNavy.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${provider.historyList.length} Catatan',
                    textAlign: TextAlign.center,
                    style: AppTypography.badge.copyWith(
                      color: AppColors.pharmaNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.historyList.length,
              itemBuilder: (context, index) {
                final item = provider.historyList[index];
                final logNumber = provider.historyList.length - index;
                return _buildLogCard(item, logNumber, sensorProvider);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogCard(SensorModel item, int logNumber, SensorProvider sensorProvider) {
    final double minT = sensorProvider.currentTempMin;
    final double maxT = sensorProvider.currentTempMax;
    final bool tempAlert = item.suhu > maxT || item.suhu < minT;
    final bool gasAlert = item.kadarGas > sensorProvider.gasMax;
    final bool doorAlert = item.isPintuTerbuka;
    final bool isWarning = tempAlert || gasAlert || doorAlert;

    // Format cleaner time: only HH:mm:ss if today
    String displayTime = item.waktu ?? 'N/A';
    final parts = displayTime.split(' ');
    if (parts.length > 1) {
      displayTime = parts[1]; // show HH:mm:ss
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isWarning ? AppColors.alertRed.withAlpha(70) : AppColors.containerLow,
          width: 0.9,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0E555A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Log #$logNumber',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pharmaNavy,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayTime,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (isWarning ? AppColors.alertRed : AppColors.activeGreen).withAlpha(18),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  isWarning ? 'Peringatan' : 'Aman',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isWarning ? AppColors.alertRed : AppColors.activeGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              // Suhu
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.thermostat_rounded,
                      size: 15,
                      color: tempAlert ? AppColors.alertRed : AppColors.pharmaBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.suhu.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: tempAlert ? AppColors.alertRed : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              // Kelembapan
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_outlined, size: 15, color: AppColors.humidityBlue),
                    const SizedBox(width: 4),
                    Text(
                      '${item.kelembapan.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              // Kadar Gas
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.co2_outlined,
                      size: 15,
                      color: gasAlert ? AppColors.alertRed : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.kadarGas.toStringAsFixed(0)} PPM',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: gasAlert ? AppColors.alertRed : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              // Ikon Status Minimalis
              Row(
                children: [
                  Icon(
                    doorAlert ? Icons.door_sliding_outlined : Icons.lock_outline,
                    size: 14,
                    color: doorAlert ? AppColors.alertRed : AppColors.activeGreen,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.cleaning_services_outlined,
                    size: 14,
                    color: item.isUvMenyala ? AppColors.uvPurple : AppColors.textMuted.withAlpha(120),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPillCard({
    required String title,
    required String value,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm + 6,
        horizontal: AppSpacing.sm + 2,
      ),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(value, style: AppTypography.subtitle),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm + 4,
        bottom: 72,
      ),
      children: [
        const Row(
          children: [
            Expanded(child: ShimmerLoading(height: 72, radius: AppSpacing.radiusMd)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: ShimmerLoading(height: 72, radius: AppSpacing.radiusMd)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: ShimmerLoading(height: 72, radius: AppSpacing.radiusMd)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerLoading(height: 18, width: 140, radius: AppSpacing.radiusSm),
            ShimmerLoading(height: 22, width: 70, radius: AppSpacing.radiusPill),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const ShimmerLoading(height: 104, radius: AppSpacing.radiusMd),
        const SizedBox(height: AppSpacing.md),
        const ShimmerLoading(height: 104, radius: AppSpacing.radiusMd),
        const SizedBox(height: AppSpacing.md),
        const ShimmerLoading(height: 104, radius: AppSpacing.radiusMd),
      ],
    );
  }
}
