import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/biometric_service.dart';
import '../services/storage_service.dart';
import '../services/update_service.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/botanic_vector_decor.dart';
import '../widgets/shimmer_loading.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storageService = StorageService();
  final TextEditingController _ipController = TextEditingController(
    text: StorageService.defaultIp,
  );

  // Threshold values initialized with defaults
  double _tempMin = StorageService.defaultTempMin;
  double _tempMax = StorageService.defaultTempMax;
  double _humidityMin = StorageService.defaultHumidityMin;
  double _humidityMax = StorageService.defaultHumidityMax;
  double _gasMax = StorageService.defaultGasMax;
  String _userName = 'Pengguna Farmasi';
  String _userEmail = 'user@smartpharma.id';
  String _authProvider = 'Smart Pharma';
  bool _isSaving = false;
  bool _isLoading = true;
  bool _isCheckingUpdate = false;

  final BiometricService _biometricService = BiometricService();
  bool _isBiometricSupported = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        _storageService.getServerIp(),
        _storageService.getThresholds(),
        _storageService.getUserProfile(),
        _storageService.isBiometricEnabled(),
        _biometricService.isDeviceSupported().timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => false,
        ),
      ]);

      if (!mounted) return;

      final ip = results[0] as String;
      final thresholds = results[1] as Map<String, double>;
      final profile = results[2] as Map<String, String>;
      final isBioEnabled = results[3] as bool;
      final isBioSupported = results[4] as bool;

      setState(() {
        _ipController.text = ip;
        _userName = profile['name'] ?? 'Pengguna Farmasi';
        _userEmail = profile['email'] ?? 'user@smartpharma.id';
        _authProvider = profile['provider'] ?? 'Smart Pharma';
        _isBiometricEnabled = isBioEnabled;
        _isBiometricSupported = isBioSupported;
        _tempMin = (thresholds['tempMin'] ?? StorageService.defaultTempMin)
            .clamp(-20.0, 30.0);
        _tempMax = (thresholds['tempMax'] ?? StorageService.defaultTempMax)
            .clamp(-10.0, 50.0);
        _humidityMin =
            (thresholds['humidityMin'] ?? StorageService.defaultHumidityMin)
                .clamp(0.0, 80.0);
        _humidityMax =
            (thresholds['humidityMax'] ?? StorageService.defaultHumidityMax)
                .clamp(20.0, 100.0);
        _gasMax = (thresholds['gasMax'] ?? StorageService.defaultGasMax).clamp(
          0.0,
          500.0,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => ModalSheetTopDecor(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md + 4,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.containerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.pharmaNavy.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.pharmaNavy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text(
                  'Edit Profil Pengguna',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pharmaNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md + 2),
            const Text(
              'Nama Pengguna',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: 'Nama lengkap / username',
                floatingLabelBehavior: FloatingLabelBehavior.never,
                filled: true,
                fillColor: AppColors.inputBg,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(color: AppColors.containerHigh),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Alamat Email',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'email@domain.com',
                floatingLabelBehavior: FloatingLabelBehavior.never,
                filled: true,
                fillColor: AppColors.inputBg,
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(color: AppColors.containerHigh),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.containerHigh),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pharmaNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      final newEmail = emailCtrl.text.trim();
                      if (newName.isEmpty || newEmail.isEmpty) {
                        return;
                      }
                      await _storageService.saveUserProfile(
                        name: newName,
                        email: newEmail,
                        provider: _authProvider,
                      );
                      if (!mounted) return;
                      setState(() {
                        _userName = newName;
                        _userEmail = newEmail;
                      });
                      if (sheetCtx.mounted) {
                        Navigator.pop(sheetCtx);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil berhasil diperbarui'),
                          backgroundColor: AppColors.pharmaNavy,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text(
                      'Simpan Profil',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
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

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Pindai sidik jari untuk mengaktifkan login biometrik',
      );
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi sidik jari tidak cocok / dibatalkan'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    await _storageService.setBiometricEnabled(value);
    if (value) {
      await _storageService.storeBiometricToken();
    } else {
      await _storageService.removeBiometricToken();
    }
    if (mounted) {
      setState(() => _isBiometricEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Login biometrik aktif'
                : 'Login biometrik dinonaktifkan',
          ),
          backgroundColor: AppColors.pharmaNavy,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs,
              ),
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
          child: BotanicVectorCardWatermark(
            size: 110,
            opacity: 0.045,
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md + 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.pharmaNavy.withAlpha(24),
                    child: Text(
                      _userName.isNotEmpty
                          ? _userName.substring(0, 1).toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pharmaNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: AppTypography.subtitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userEmail,
                          style: AppTypography.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _authProvider,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.pharmaNavy.withAlpha(180),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: _showEditProfileDialog,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.pharmaNavy,
                    tooltip: 'Edit Profil',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.containerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: const BoxDecoration(
                  color: AppColors.containerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: AppColors.pharmaNavy,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Login Biometrik',
                      style: AppTypography.subtitle,
                    ),
                    Text(
                      _isBiometricSupported
                          ? 'Akses cepat dengan sidik jari / Face ID'
                          : 'Perangkat belum mendukung biometrik',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isBiometricEnabled,
                onChanged: _isBiometricSupported ? _toggleBiometric : null,
                activeThumbColor: AppColors.pharmaNavy,
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: const BoxDecoration(
                      color: AppColors.containerLow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.dns_outlined,
                      color: AppColors.pharmaNavy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfigurasi Jaringan Gudang',
                          style: AppTypography.subtitle,
                        ),
                        Text(
                          'Server Telemetri FastAPI & MQTT Broker',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'IP Server Lokal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _ipController,
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: '192.168.1.100',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: const Icon(
                    Icons.wifi_outlined,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.restore, size: 20),
                    tooltip: 'Reset Default',
                    onPressed: () {
                      _ipController.text = StorageService.defaultIp;
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.containerHigh,
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.containerHigh,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.pharmaNavy,
                      width: 1.5,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md - 2,
                    ),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: const BoxDecoration(
                      color: AppColors.containerLow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune_outlined,
                      color: AppColors.pharmaNavy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Threshold Sensor', style: AppTypography.subtitle),
                        Text(
                          'Atur batas deteksi anomali peralatan',
                          style: AppTypography.caption,
                        ),
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
                  child: const Icon(
                    Icons.router_outlined,
                    color: AppColors.pharmaNavy,
                    size: 18,
                  ),
                ),
                title: const Text(
                  'Broker MQTT Mosquitto',
                  style: AppTypography.subtitle,
                ),
                subtitle: const Text(
                  'Port: 1883 | Topic: pharma/sensor',
                  style: AppTypography.caption,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pharmaNavy,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
              const Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
                color: AppColors.containerLow,
              ),
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
                  child: const Icon(
                    Icons.api_outlined,
                    color: AppColors.pharmaNavy,
                    size: 18,
                  ),
                ),
                title: const Text(
                  'Backend REST API FastAPI',
                  style: AppTypography.subtitle,
                ),
                subtitle: const Text(
                  'Port: 8001 | Endpoint: /sensor',
                  style: AppTypography.caption,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pharmaNavy,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
        const SizedBox(height: AppSpacing.md - 2),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: AppColors.containerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  color: AppColors.pharmaNavy,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pembaruan Aplikasi', style: AppTypography.subtitle),
                    SizedBox(height: 1),
                    Text('In-App OTA via GitHub Releases', style: AppTypography.caption),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pharmaNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                onPressed: _isCheckingUpdate
                    ? null
                    : () async {
                        setState(() => _isCheckingUpdate = true);
                        final info = await UpdateService.checkForUpdate();
                        if (!mounted) return;
                        setState(() => _isCheckingUpdate = false);
                        if (!context.mounted) return;
                        if (info.hasUpdate) {
                          UpdateService.showUpdateDialog(context, info);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Aplikasi sudah versi terbaru (v${info.currentVersion})',
                              ),
                              backgroundColor: AppColors.pharmaNavy,
                            ),
                          );
                        }
                      },
                child: _isCheckingUpdate
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Periksa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
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
            await StorageService().clearSession();
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
        const SizedBox(height: AppSpacing.sm),
        const PharmaBrandStamp(),
        const SizedBox(height: AppSpacing.md),
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
                children: [
                  const ShimmerLoading(
                    height: 36,
                    width: 36,
                    radius: AppSpacing.radiusPill,
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(
                        height: 16,
                        width: 180,
                        radius: AppSpacing.radiusSm,
                      ),
                      SizedBox(height: 6),
                      ShimmerLoading(
                        height: 12,
                        width: 220,
                        radius: AppSpacing.radiusSm,
                      ),
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
                children: [
                  const ShimmerLoading(
                    height: 36,
                    width: 36,
                    radius: AppSpacing.radiusPill,
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(
                        height: 16,
                        width: 140,
                        radius: AppSpacing.radiusSm,
                      ),
                      SizedBox(height: 6),
                      ShimmerLoading(
                        height: 12,
                        width: 200,
                        radius: AppSpacing.radiusSm,
                      ),
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
                          ShimmerLoading(
                            height: 14,
                            width: 110,
                            radius: AppSpacing.radiusSm,
                          ),
                          ShimmerLoading(
                            height: 18,
                            width: 60,
                            radius: AppSpacing.radiusSm,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs + 4),
                      const ShimmerLoading(
                        height: 14,
                        radius: AppSpacing.radiusPill,
                      ),
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
                children: [
                  const ShimmerLoading(
                    height: 32,
                    width: 32,
                    radius: AppSpacing.radiusPill,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(
                        height: 14,
                        width: 150,
                        radius: AppSpacing.radiusSm,
                      ),
                      SizedBox(height: 4),
                      ShimmerLoading(
                        height: 11,
                        width: 180,
                        radius: AppSpacing.radiusSm,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.containerLow),
              Row(
                children: [
                  const ShimmerLoading(
                    height: 32,
                    width: 32,
                    radius: AppSpacing.radiusPill,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(
                        height: 14,
                        width: 160,
                        radius: AppSpacing.radiusSm,
                      ),
                      SizedBox(height: 4),
                      ShimmerLoading(
                        height: 11,
                        width: 170,
                        radius: AppSpacing.radiusSm,
                      ),
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
