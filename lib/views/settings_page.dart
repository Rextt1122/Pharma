import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_loading.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storageService = StorageService();
  final TextEditingController _ipController = TextEditingController(text: StorageService.defaultIp);
  
  // Threshold values initialized with defaults
  double _tempMin = StorageService.defaultTempMin;
  double _tempMax = StorageService.defaultTempMax;
  double _humidityMin = StorageService.defaultHumidityMin;
  double _humidityMax = StorageService.defaultHumidityMax;
  double _gasMax = StorageService.defaultGasMax;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final ip = await _storageService.getServerIp();
    final thresholds = await _storageService.getThresholds();
    
    // Smooth skeleton duration so the shimmer is visible and fluid
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _ipController.text = ip;
        _tempMin = (thresholds['tempMin'] ?? StorageService.defaultTempMin).clamp(-20.0, 30.0);
        _tempMax = (thresholds['tempMax'] ?? StorageService.defaultTempMax).clamp(-10.0, 50.0);
        _humidityMin = (thresholds['humidityMin'] ?? StorageService.defaultHumidityMin).clamp(0.0, 80.0);
        _humidityMax = (thresholds['humidityMax'] ?? StorageService.defaultHumidityMax).clamp(20.0, 100.0);
        _gasMax = (thresholds['gasMax'] ?? StorageService.defaultGasMax).clamp(0.0, 500.0);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final newIp = _ipController.text.trim();
    if (newIp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IP Server tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tempMin >= _tempMax) {
      _showError('Suhu min harus kurang dari max');
      return;
    }
    if (_humidityMin >= _humidityMax) {
      _showError('Kelembapan min harus kurang dari max');
      return;
    }
    if (_gasMax < 0) {
      _showError('Gas max tidak boleh negatif');
      return;
    }

    // Save settings
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    await _storageService.saveServerIp(newIp);
    
    if (mounted) {
      context.read<SensorProvider>().updateThresholds(
        tempMin: _tempMin,
        tempMax: _tempMax,
        humidityMin: _humidityMin,
        humidityMax: _humidityMax,
        gasMax: _gasMax,
      );

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konfigurasi disimpan: $newIp'),
            backgroundColor: AppColors.pharmaNavy,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Widget _buildThresholdSlider({
    required String label,
    required String unit,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    final double safeMin = min;
    final double safeMax = max > min ? max : min + 1.0;
    final double safeValue = value.clamp(safeMin, safeMax);
    int divisions = ((safeMax - safeMin) * 2).round();
    if (divisions <= 0) divisions = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.pharmaNavy),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(label, style: AppTypography.caption),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.pharmaNavy.withAlpha(25),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                '${safeValue.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pharmaNavy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
            activeTrackColor: AppColors.pharmaNavy,
            inactiveTrackColor: AppColors.containerLow,
            thumbColor: AppColors.pharmaNavy,
            overlayColor: AppColors.pharmaNavy.withAlpha(51),
          ),
          child: Slider(
            min: safeMin,
            max: safeMax,
            divisions: divisions,
            value: safeValue,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm + 4,
        bottom: AppSpacing.lg,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.containerHigh, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: const BoxDecoration(
                      color: AppColors.containerLow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.dns_outlined, color: AppColors.pharmaNavy, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Konfigurasi Jaringan Gudang', style: AppTypography.subtitle),
                        Text('Server Telemetri FastAPI & MQTT Broker', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _ipController,
                style: AppTypography.body,
                decoration: InputDecoration(
                  labelText: 'IP Server Lokal',
                  hintText: '192.168.1.100',
                  prefixIcon: const Icon(Icons.wifi_outlined, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.restore, size: 20),
                    tooltip: 'Reset Default',
                    onPressed: () {
                      _ipController.text = StorageService.defaultIp;
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.pharmaNavy, width: 2.0),
                  ),
                  filled: true,
                  fillColor: AppColors.inputBg,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pharmaNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md - 2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    _isSaving ? 'Menyimpan...' : 'Simpan Konfigurasi',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.containerHigh, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: const BoxDecoration(
                      color: AppColors.containerLow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_outlined, color: AppColors.pharmaNavy, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Threshold Sensor', style: AppTypography.subtitle),
                        Text('Atur batas deteksi anomali peralatan', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Suhu with Sliders
              _buildThresholdSlider(
                label: 'Suhu Minimum',
                unit: '°C',
                value: _tempMin,
                min: -20,
                max: 30,
                onChanged: (val) => setState(() => _tempMin = val),
                icon: Icons.arrow_downward,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildThresholdSlider(
                label: 'Suhu Maximum',
                unit: '°C',
                value: _tempMax,
                min: -10,
                max: 50,
                onChanged: (val) => setState(() => _tempMax = val),
                icon: Icons.arrow_upward,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Kelembapan with Sliders
              _buildThresholdSlider(
                label: 'Kelembapan Minimum',
                unit: '%',
                value: _humidityMin,
                min: 0,
                max: 80,
                onChanged: (val) => setState(() => _humidityMin = val),
                icon: Icons.water_drop_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildThresholdSlider(
                label: 'Kelembapan Maximum',
                unit: '%',
                value: _humidityMax,
                min: 20,
                max: 100,
                onChanged: (val) => setState(() => _humidityMax = val),
                icon: Icons.water_drop,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Gas Max with Slider
              _buildThresholdSlider(
                label: 'Kadar Gas Maximum',
                unit: 'PPM',
                value: _gasMax,
                min: 0,
                max: 500,
                onChanged: (val) => setState(() => _gasMax = val),
                icon: Icons.cloud,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.containerHigh, width: 1.0),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.containerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.router_outlined, color: AppColors.pharmaNavy, size: 18),
                ),
                title: const Text('Broker MQTT Mosquitto', style: AppTypography.subtitle),
                subtitle: const Text('Port: 1883 | Topic: pharma/sensor', style: AppTypography.caption),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pharmaNavy,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '● Active',
                    textAlign: TextAlign.center,
                    style: AppTypography.badge.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg, color: AppColors.containerLow),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.containerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.api_outlined, color: AppColors.pharmaNavy, size: 18),
                ),
                title: const Text('Backend REST API FastAPI', style: AppTypography.subtitle),
                subtitle: const Text('Port: 8001 | Endpoint: /sensor', style: AppTypography.caption),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pharmaNavy,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '● Active',
                    textAlign: TextAlign.center,
                    style: AppTypography.badge.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md - 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          onPressed: () async {
            await StorageService().setLoggedIn(false);
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          icon: const Icon(Icons.logout, size: 18),
          label: const Text(
            'Keluar dari Aplikasi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              height: 1.1,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm + 4,
        bottom: AppSpacing.lg,
      ),
      children: [
        // Network configuration card skeleton
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.containerHigh, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShimmerLoading(height: 36, width: 36, radius: AppSpacing.radiusPill),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(height: 16, width: 180, radius: AppSpacing.radiusSm),
                      SizedBox(height: 6),
                      ShimmerLoading(height: 12, width: 220, radius: AppSpacing.radiusSm),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const ShimmerLoading(height: 52, radius: AppSpacing.radiusMd),
              const SizedBox(height: AppSpacing.md),
              const ShimmerLoading(height: 44, radius: AppSpacing.radiusMd),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        // Threshold sensor card skeleton
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.containerHigh, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShimmerLoading(height: 36, width: 36, radius: AppSpacing.radiusPill),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(height: 16, width: 140, radius: AppSpacing.radiusSm),
                      SizedBox(height: 6),
                      ShimmerLoading(height: 12, width: 200, radius: AppSpacing.radiusSm),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          ShimmerLoading(height: 14, width: 110, radius: AppSpacing.radiusSm),
                          ShimmerLoading(height: 18, width: 60, radius: AppSpacing.radiusSm),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs + 4),
                      const ShimmerLoading(height: 14, radius: AppSpacing.radiusPill),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        // Services info card skeleton
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.containerHigh, width: 1.0),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const ShimmerLoading(height: 32, width: 32, radius: AppSpacing.radiusPill),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(height: 14, width: 150, radius: AppSpacing.radiusSm),
                      SizedBox(height: 4),
                      ShimmerLoading(height: 11, width: 180, radius: AppSpacing.radiusSm),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.containerLow),
              Row(
                children: [
                  const ShimmerLoading(height: 32, width: 32, radius: AppSpacing.radiusPill),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(height: 14, width: 160, radius: AppSpacing.radiusSm),
                      SizedBox(height: 4),
                      ShimmerLoading(height: 11, width: 170, radius: AppSpacing.radiusSm),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const ShimmerLoading(height: 44, radius: AppSpacing.radiusMd),
      ],
    );
  }
}
