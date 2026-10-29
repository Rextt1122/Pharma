import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import '../models/sensor_model.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/botanic_vector_decor.dart';
import '../widgets/shimmer_loading.dart';

class Model3dPage extends StatefulWidget {
  const Model3dPage({super.key});

  @override
  State<Model3dPage> createState() => _Model3dPageState();
}

class _Model3dPageState extends State<Model3dPage> {
  bool _is3dModel = true;
  bool _autoRotate = false;
  int _selectedZone = 0;

  final List<String> _zones = const [
    'Semua Zona',
    'Cold Storage',
    'Kamar UV',
    'Pintu Utama',
    'Detektor Gas',
  ];

  void _openFullScreenDenah() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ModalSheetTopDecor(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, color: AppColors.pharmaNavy, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Denah Ruang Vaksin & Legenda (12x8m)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pharmaNavy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.containerLow),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: Image.asset(
                      'assets/images/denah_ruang_vaksin.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  String _getCameraOrbit() {
    switch (_selectedZone) {
      case 1:
        return '35deg 65deg 55%';
      case 2:
        return '130deg 65deg 55%';
      case 3:
        return '-5deg 75deg 50%';
      case 4:
        return '210deg 65deg 55%';
      default:
        return '14deg 80deg 60%';
    }
  }

  String _getCameraTarget() {
    switch (_selectedZone) {
      case 1:
        return '2.5m 1.0m -4.0m';
      case 2:
        return '-1.5m 1.0m -6.0m';
      case 3:
        return '0.5m 1.0m 0.0m';
      case 4:
        return '3.0m 1.5m -5.0m';
      default:
        return '0.55m 1.0m -3.0m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, child) {
        if (provider.isInitialLoading) {
          return _buildLoadingSkeleton();
        }

        final sensor = provider.sensorData;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.sm + 4,
            bottom: AppSpacing.md,
          ),
          children: [
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: const BoxDecoration(
                          color: AppColors.containerLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.view_in_ar_outlined,
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
                              'Digital Twin Miniatur 3D',
                              style: AppTypography.subtitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Simulasi Layout & Posisi Sensor',
                              style: AppTypography.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 4,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pharmaNavy,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Text(
                          '3D LIVE',
                          textAlign: TextAlign.center,
                          style: AppTypography.badge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.containerHigh, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _is3dModel = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _is3dModel ? AppColors.pharmaNavy : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.view_in_ar,
                                    size: 15,
                                    color: _is3dModel ? Colors.white : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Model 3D',
                                    style: TextStyle(
                                      color: _is3dModel ? Colors.white : AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _is3dModel = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_is3dModel ? AppColors.pharmaNavy : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map_outlined,
                                    size: 15,
                                    color: !_is3dModel ? Colors.white : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Denah 2D',
                                    style: TextStyle(
                                      color: !_is3dModel ? Colors.white : AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md - 2),
            Container(
              height: 400,
              decoration: BoxDecoration(
                color: _is3dModel ? const Color(0xFF263238) : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.containerLow, width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x180E555A),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Stack(
                  children: [
                    if (_is3dModel)
                      ModelViewer(
                        key: ValueKey('3d-model-$_selectedZone-$_autoRotate-v6'),
                        src: 'assets/models/model_3d_v2.glb',
                        alt: 'Digital Twin Miniatur Gudang Farmasi 3D',
                        autoRotate: _autoRotate,
                        autoRotateDelay: 2000,
                        cameraControls: true,
                        cameraOrbit: _getCameraOrbit(),
                        cameraTarget: _getCameraTarget(),
                        fieldOfView: '20deg',
                        backgroundColor: const Color(0xFF263238),
                      )
                    else
                      InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.5,
                        child: Container(
                          color: Colors.white,
                          width: double.infinity,
                          height: double.infinity,
                          child: Center(
                            child: Image.asset(
                              'assets/images/denah_ruang_vaksin.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: AppSpacing.sm + 4,
                      right: AppSpacing.sm + 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _is3dModel = !_is3dModel),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(160),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _is3dModel ? Icons.threed_rotation : Icons.map_outlined,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _is3dModel ? 'Mode: 3D GLB' : 'Mode: 2D Denah',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (_is3dModel) ...[
                            GestureDetector(
                              onTap: () => setState(() => _autoRotate = !_autoRotate),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  border: Border.all(color: Colors.white24, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _autoRotate ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                      color: _autoRotate ? AppColors.activeGreen : Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _autoRotate ? 'Auto Putar: ON' : 'Auto Putar: OFF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedZone = 0;
                                  _autoRotate = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 0.8),
                                ),
                                child: const Icon(Icons.refresh, color: Colors.white, size: 14),
                              ),
                            ),
                          ] else ...[
                            GestureDetector(
                              onTap: _openFullScreenDenah,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  border: Border.all(color: Colors.white24, width: 0.8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fullscreen_rounded, color: Colors.white, size: 15),
                                    SizedBox(width: 4),
                                    Text(
                                      'Perbesar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: AppSpacing.sm + 4,
                      left: AppSpacing.sm + 4,
                      right: AppSpacing.sm + 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(170),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: sensor.isGasBahaya || sensor.isPintuTerbuka
                                          ? AppColors.alertRed
                                          : AppColors.activeGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _is3dModel
                                          ? 'Fokus: ${_zones[_selectedZone]}'
                                          : 'Denah: Ruang Vaksin & Kontrol (12x8m)',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(170),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.touch_app_outlined, color: Colors.white70, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  _is3dModel ? 'Geser/Cubit 360°' : 'Cubit untuk Zoom',
                                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Section Header: Fokus Sensor
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'FOKUS SENSOR',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            // Bento Focus Cards (Less Is More)
            _buildTactileZoneTile(
              idx: 0,
              icon: Icons.grid_view_rounded,
              title: 'Semua Zona',
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildTactileZoneTile(
                    idx: 1,
                    icon: Icons.ac_unit_rounded,
                    title: 'Cold Storage',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildTactileZoneTile(
                    idx: 2,
                    icon: Icons.cleaning_services_rounded,
                    title: 'Kamar UV',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildTactileZoneTile(
                    idx: 3,
                    icon: Icons.door_sliding_outlined,
                    title: 'Pintu Utama',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildTactileZoneTile(
                    idx: 4,
                    icon: Icons.cloud_outlined,
                    title: 'Detektor Gas',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Section Header: Spesifikasi
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'SPESIFIKASI GUDANG',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            // Bento Warehouse Specs
            Row(
              children: [
                Expanded(
                  child: _buildBentoSpecCard(
                    icon: Icons.warehouse_rounded,
                    title: 'Luas Storage',
                    value: '120 m²',
                    detail: 'Cold Storage A',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildBentoSpecCard(
                    icon: Icons.thermostat_rounded,
                    title: 'Sensor Suhu',
                    value: 'SHT31',
                    detail: 'Akurasi ±0.2°C',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildBentoSpecCard(
                    icon: Icons.co2_rounded,
                    title: 'Sensor Gas',
                    value: 'MQ-2 / 135',
                    detail: 'Deteksi Asap & Gas',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildBentoSpecCard(
                    icon: Icons.wb_iridescent_rounded,
                    title: 'Sterilisasi Ruang',
                    value: 'UV-C 254nm',
                    detail: 'Germicidal Disinfektan',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildBentoSpecCard(
              icon: Icons.lock_outline_rounded,
              title: 'Keamanan Pintu',
              value: 'Magnetic Switch',
              detail: 'Deteksi buka-tutup otomatis',
              isFullWidth: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTactileZoneTile({
    required int idx,
    required IconData icon,
    required String title,
  }) {
    final isSelected = _selectedZone == idx;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedZone = idx),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.pharmaNavy.withAlpha(20) : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.pharmaNavy : AppColors.containerLow,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? AppColors.pharmaNavy : const Color(0x0C0E555A))
                    .withAlpha(isSelected ? 30 : 10),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (isSelected ? AppColors.pharmaNavy : AppColors.containerLow)
                      .withAlpha(isSelected ? 30 : 255),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: isSelected ? AppColors.pharmaNavy : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.pharmaNavy : AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.pharmaNavy : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoSpecCard({
    required IconData icon,
    required String title,
    required String value,
    required String detail,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.pharmaNavy.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: AppColors.pharmaNavy, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
        bottom: AppSpacing.lg,
      ),
      children: [
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const ShimmerLoading(height: 36, width: 36, radius: AppSpacing.radiusPill),
                      const SizedBox(width: AppSpacing.sm + 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerLoading(height: 16, width: 150, radius: AppSpacing.radiusSm),
                          SizedBox(height: 6),
                          ShimmerLoading(height: 12, width: 110, radius: AppSpacing.radiusSm),
                        ],
                      ),
                    ],
                  ),
                  const ShimmerLoading(height: 24, width: 64, radius: AppSpacing.radiusSm),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: const [
                    ShimmerLoading(height: 32, width: 70, radius: AppSpacing.radiusSm),
                    SizedBox(width: AppSpacing.sm),
                    ShimmerLoading(height: 32, width: 65, radius: AppSpacing.radiusSm),
                    SizedBox(width: AppSpacing.sm),
                    ShimmerLoading(height: 32, width: 60, radius: AppSpacing.radiusSm),
                    SizedBox(width: AppSpacing.sm),
                    ShimmerLoading(height: 32, width: 75, radius: AppSpacing.radiusSm),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        const ShimmerLoading(height: 280, radius: AppSpacing.radiusMd),
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
              const ShimmerLoading(height: 16, width: 150, radius: AppSpacing.radiusSm),
              const SizedBox(height: AppSpacing.sm + 4),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs + 4,
                children: const [
                  ShimmerLoading(height: 30, width: 90, radius: AppSpacing.radiusSm),
                  ShimmerLoading(height: 30, width: 140, radius: AppSpacing.radiusSm),
                  ShimmerLoading(height: 30, width: 110, radius: AppSpacing.radiusSm),
                  ShimmerLoading(height: 30, width: 85, radius: AppSpacing.radiusSm),
                  ShimmerLoading(height: 30, width: 95, radius: AppSpacing.radiusSm),
                ],
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
              const ShimmerLoading(height: 16, width: 170, radius: AppSpacing.radiusSm),
              const SizedBox(height: AppSpacing.md),
              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerLoading(height: 14, width: 120, radius: AppSpacing.radiusSm),
                      ShimmerLoading(height: 14, width: 130, radius: AppSpacing.radiusSm),
                    ],
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

class Warehouse3dPainter extends CustomPainter {
  final String viewMode;
  final SensorModel sensorMode;
  final int selectedZone;

  Warehouse3dPainter({
    required this.viewMode,
    required this.sensorMode,
    required this.selectedZone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintFloor = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final paintWall = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintZoneCold = Paint()
      ..color = const Color(0xFF0284C7).withAlpha(60)
      ..style = PaintingStyle.fill;

    final paintZoneUv = Paint()
      ..color = AppColors.uvPurple.withAlpha(60)
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintFloor);

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paintGrid);
    }

    final coldRect = Rect.fromLTWH(20, 30, size.width * 0.4, size.height - 60);
    canvas.drawRect(coldRect, paintZoneCold);
    canvas.drawRect(coldRect, paintWall);

    final uvRect = Rect.fromLTWH(size.width * 0.45, 30, size.width * 0.5, size.height - 60);
    canvas.drawRect(uvRect, paintZoneUv);
    canvas.drawRect(uvRect, paintWall);

    final pTemp = Paint()
      ..color = AppColors.activeGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(coldRect.center.dx, coldRect.center.dy - 30), 10, pTemp);

    final pUv = Paint()
      ..color = sensorMode.isUvMenyala ? AppColors.uvPurple : Colors.grey
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(uvRect.center.dx - 20, uvRect.center.dy), 10, pUv);

    final pDoor = Paint()
      ..color = sensorMode.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(size.width - 25, size.height / 2 - 20, 10, 40), pDoor);

    final pGas = Paint()
      ..color = sensorMode.isGasBahaya ? AppColors.alertRed : AppColors.activeGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(uvRect.center.dx + 40, uvRect.center.dy + 30), 10, pGas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
