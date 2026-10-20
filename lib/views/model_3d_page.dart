import 'package:flutter/material.dart';
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
  String _selectedView = 'ISO 3D';
  int _selectedZone = 0;

  final List<String> _views = const ['ISO 3D', 'Depan', 'Atas', 'Internal'];
  final List<String> _zones = const [
    'Semua Zona',
    'Cold Storage (2-8°C)',
    'Kamar UV Steril',
    'Pintu Utama',
    'Detektor Gas',
  ];

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
            bottom: AppSpacing.xl * 3,
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
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.pharmaNavy,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.pharmaNavy, width: 1.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: Warehouse3dPainter(
                        viewMode: _selectedView,
                        sensorMode: sensor,
                        selectedZone: _selectedZone,
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.threed_rotation, color: Colors.white, size: 20),
                            SizedBox(height: 2),
                            Text(
                              'Interactive',
                              style: TextStyle(color: Colors.white70, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: AppSpacing.md,
                      left: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: sensor.isGasBahaya || sensor.isPintuTerbuka ? AppColors.alertRed : AppColors.activeGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Kamera 3D: $_selectedView',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
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
        bottom: AppSpacing.xl * 3,
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
