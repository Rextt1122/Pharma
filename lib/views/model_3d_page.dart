import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import '../models/sensor_model.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_loading.dart';

class Model3dPage extends StatefulWidget {
  const Model3dPage({super.key});

  @override
  State<Model3dPage> createState() => _Model3dPageState();
}

class _Model3dPageState extends State<Model3dPage> {
  bool _is3dModel = true;
  bool _autoRotate = false;
  String _selectedView = 'Depan';
  int _selectedZone = 0;

  final List<String> _views = const ['Depan', 'ISO 3D', 'Atas', 'Internal'];
  final List<String> _zones = const [
    'Semua Zona',
    'Cold Storage (2-8°C)',
    'Kamar UV Steril',
    'Pintu Utama',
    'Detektor Gas',
  ];

  String _getCameraOrbit() {
    if (_selectedZone == 1) return '35deg 65deg 55%';
    if (_selectedZone == 2) return '130deg 65deg 55%';
    if (_selectedZone == 3) return '-5deg 75deg 50%';
    if (_selectedZone == 4) return '210deg 65deg 55%';

    switch (_selectedView) {
      case 'Depan':
        return '-8deg 78deg 58%';
      case 'Atas':
        return '0deg 5deg 75%';
      case 'Internal':
        return '180deg 75deg 60%';
      case 'ISO 3D':
        return '45deg 65deg 70%';
      default:
        return '-8deg 78deg 58%';
    }
  }

  String _getCameraTarget() {
    if (_selectedZone == 1) return '2.5m 1.0m -4.0m';
    if (_selectedZone == 2) return '-1.5m 1.0m -6.0m';
    if (_selectedZone == 3) return '0.5m 1.0m 0.0m';
    if (_selectedZone == 4) return '3.0m 1.5m -5.0m';

    switch (_selectedView) {
      case 'Depan':
        return '1.2m 1.0m -3.0m';
      default:
        return 'auto auto auto';
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Digital Twin Miniatur 3D', style: AppTypography.subtitle),
                              Text('Simulasi Layout & Posisi Sensor', style: AppTypography.caption),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 4,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pharmaNavy,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
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
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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
                                    'Model 3D Blender',
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
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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
                                    'Denah Sensor (2D)',
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
                  const SizedBox(height: AppSpacing.sm + 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _views.map((viewMode) {
                        final isSelected = _selectedView == viewMode;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(viewMode),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedView = viewMode;
                                });
                              }
                            },
                            selectedColor: AppColors.pharmaNavy,
                            backgroundColor: AppColors.inputBg,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textDark,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              side: BorderSide(
                                color: isSelected ? AppColors.pharmaNavy : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md - 2),
            Container(
              height: 340,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.pharmaNavy, width: 1.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Stack(
                  children: [
                    if (_is3dModel)
                      ModelViewer(
                        key: ValueKey('3d-model-$_selectedView-$_selectedZone-$_autoRotate'),
                        src: 'assets/models/gudang_3d.glb',
                        alt: 'Digital Twin Miniatur Gudang Farmasi 3D',
                        autoRotate: _autoRotate,
                        autoRotateDelay: 2000,
                        cameraControls: true,
                        cameraOrbit: _getCameraOrbit(),
                        cameraTarget: _getCameraTarget(),
                        fieldOfView: '28deg',
                        backgroundColor: const Color(0xFF0F172A),
                      )
                    else
                      CustomPaint(
                        size: Size.infinite,
                        painter: Warehouse3dPainter(
                          viewMode: _selectedView,
                          sensorMode: sensor,
                          selectedZone: _selectedZone,
                        ),
                      ),
                    Positioned(
                      top: AppSpacing.sm + 4,
                      right: AppSpacing.sm + 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_is3dModel) ...[
                            GestureDetector(
                              onTap: () => setState(() => _autoRotate = !_autoRotate),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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
                                  _selectedView = 'Depan';
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
                          ] else
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(100),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.threed_rotation, color: Colors.white, size: 18),
                                  SizedBox(height: 2),
                                  Text(
                                    'Skematik 2D',
                                    style: TextStyle(color: Colors.white70, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
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
                                      'Kamera: $_selectedView ${_selectedZone > 0 ? "(${_zones[_selectedZone]})" : ""}',
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
                                  _is3dModel ? 'Geser/Cubit 360°' : 'Layout Denah',
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
            const SizedBox(height: AppSpacing.md - 2),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fokus Lokasi Sensor', style: AppTypography.subtitle),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: _zones.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final label = entry.value;
                      final isSelected = _selectedZone == idx;

                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedZone = idx;
                            });
                          }
                        },
                        selectedColor: AppColors.pharmaNavy,
                        backgroundColor: AppColors.inputBg,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          side: BorderSide(
                            color: isSelected ? AppColors.pharmaNavy : const Color(0xFFCBD5E1),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md - 2),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spesifikasi Miniatur Gudang', style: AppTypography.subtitle),
                  const SizedBox(height: AppSpacing.md),
                  _buildSpecRow('Luas Ruang Storage', '120 m² (Cold Storage Zone A)'),
                  const Divider(height: 16, color: AppColors.containerLow),
                  _buildSpecRow('Node Sensor Suhu/Lembap', 'SHT31 (Presisi Tinggi ±0.2°C)'),
                  const Divider(height: 16, color: AppColors.containerLow),
                  _buildSpecRow('Sensor Gas/Asap', 'MQ-2 / MQ-135 Gas Detector'),
                  const Divider(height: 16, color: AppColors.containerLow),
                  _buildSpecRow('Lampu Sterilisasi UV', 'UV-C Germicidal Lamp (254nm)'),
                  const Divider(height: 16, color: AppColors.containerLow),
                  _buildSpecRow('Sensor Pintu Utama', 'Magnetic Contact Switch Node'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpecRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.caption),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
        bottom: AppSpacing.md,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
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
                  const ShimmerLoading(height: 24, width: 64, radius: AppSpacing.radiusPill),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: const [
                    ShimmerLoading(height: 32, width: 70, radius: AppSpacing.radiusPill),
                    SizedBox(width: AppSpacing.sm),
                    ShimmerLoading(height: 32, width: 65, radius: AppSpacing.radiusPill),
                    SizedBox(width: AppSpacing.sm),
                    ShimmerLoading(height: 32, width: 60, radius: AppSpacing.radiusPill),
                    SizedBox(width: AppSpacing.sm),
                    ShimmerLoading(height: 32, width: 75, radius: AppSpacing.radiusPill),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        const ShimmerLoading(height: 280, radius: AppSpacing.radiusLg),
        const SizedBox(height: AppSpacing.md - 2),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
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
                  ShimmerLoading(height: 30, width: 90, radius: AppSpacing.radiusPill),
                  ShimmerLoading(height: 30, width: 140, radius: AppSpacing.radiusPill),
                  ShimmerLoading(height: 30, width: 110, radius: AppSpacing.radiusPill),
                  ShimmerLoading(height: 30, width: 85, radius: AppSpacing.radiusPill),
                  ShimmerLoading(height: 30, width: 95, radius: AppSpacing.radiusPill),
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
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
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
