import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';
import 'climate_dashboard_page.dart';
import 'model_3d_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  Timer? _timer;
  late DateTime _currentTime;
  late final AnimationController _ambientController;
  late final AnimationController _tabTransitionController;
  late final Animation<double> _tabFade;
  late final Animation<Offset> _tabSlide;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
    _tabTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _tabFade = CurvedAnimation(
      parent: _tabTransitionController,
      curve: Curves.easeOutCubic,
    );
    _tabSlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _tabTransitionController,
        curve: Curves.easeOutCubic,
      ),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ambientController.dispose();
    _tabTransitionController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$dayName, $day $monthName $year • $hour:$minute:$second';
  }

  final List<String> _titles = const [
    'Monitoring Gudang Farmasi',
    'Miniatur 3D & Digital Twin',
    'Riwayat Log Gudang',
    'Pengaturan Sistem',
  ];

  void _showNotificationSheet(BuildContext context, SensorProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
      ),
      builder: (context) {
        return Consumer<SensorProvider>(
          builder: (context, p, child) {
            final list = p.notifications;
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md + 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: AppColors.pharmaNavy),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Notifikasi & Peringatan', style: AppTypography.subtitle),
                        ],
                      ),
                      if (list.isNotEmpty)
                        TextButton(
                          onPressed: () => p.clearNotifications(),
                          child: const Text('Hapus Semua', style: TextStyle(color: AppColors.alertRed)),
                        ),
                    ],
                  ),
                  const Divider(color: AppColors.containerLow),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 48, color: AppColors.activeGreen),
                            SizedBox(height: AppSpacing.sm),
                            Text('Tidak Ada Peringatan Baru', style: AppTypography.subtitle),
                            Text('Sistem dan lingkungan gudang dalam kondisi aman.', style: AppTypography.caption),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.containerLow),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final timeStr = '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: item.isCritical ? AppColors.alertRed.withAlpha(30) : AppColors.warningAmber.withAlpha(30),
                              child: Icon(
                                item.isCritical ? Icons.warning_amber_rounded : Icons.info_outline,
                                color: item.isCritical ? AppColors.alertRed : AppColors.warningAmber,
                              ),
                            ),
                            title: Text(item.title, style: AppTypography.subtitle.copyWith(fontSize: 14)),
                            subtitle: Text(item.message, style: AppTypography.caption),
                            trailing: Text(timeStr, style: AppTypography.caption),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sensorProvider = Provider.of<SensorProvider>(context);
    final count = sensorProvider.notificationCount;
    final badgeText = count > 5 ? '5+' : '$count';

    return Scaffold(
      backgroundColor: AppColors.pharmaNavy,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Animated organic leaves & floating orbs matching Login Page header
            Positioned(
              top: -8,
              left: -8,
              right: 0,
              height: 150,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _HeaderOrganicPainter(
                        progress: _ambientController.value,
                      ),
                    );
                  },
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Bar (Login-page style deep teal with white text)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md + 4,
                    AppSpacing.sm + 4,
                    AppSpacing.md + 4,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm + 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(45),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _titles[_selectedIndex],
                              style: AppTypography.heading.copyWith(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime(_currentTime),
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withAlpha(210),
                                fontSize: 11.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () =>
                            _showNotificationSheet(context, sensorProvider),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm + 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(28),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withAlpha(45),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.alertRed,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill,
                                    ),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    badgeText,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.badge.copyWith(
                                      color: Colors.white,
                                      fontSize: 9,
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

                // Curved Rounded-Top Body Sheet (matching Login Page sheet)
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: FadeTransition(
                        opacity: _tabFade,
                        child: SlideTransition(
                          position: _tabSlide,
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: [
                              const ClimateDashboardPage(),
                              Model3dPage(
                                key: ValueKey('model_3d_view_$_selectedIndex'),
                              ),
                              const HistoryPage(),
                              const SettingsPage(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.background,
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pharmaNavy.withAlpha(16),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: 62,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final isSelected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.pharmaNavy
                          : AppColors.textMuted,
                    );
                  }),
                ),
                child: NavigationBar(
                  height: 62,
                  elevation: 0,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    if (_selectedIndex != index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                      _tabTransitionController.forward(from: 0.0);
                    }
                  },
                  backgroundColor: AppColors.cardWhite,
                  indicatorColor: AppColors.pharmaTeal.withAlpha(35),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(
                        Icons.sensors_outlined,
                        size: 19,
                        color: AppColors.textMuted,
                      ),
                      selectedIcon: Icon(
                        Icons.sensors,
                        size: 19,
                        color: AppColors.pharmaNavy,
                      ),
                      label: 'Realtime',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.view_in_ar_outlined,
                        size: 19,
                        color: AppColors.textMuted,
                      ),
                      selectedIcon: Icon(
                        Icons.view_in_ar,
                        size: 19,
                        color: AppColors.pharmaNavy,
                      ),
                      label: 'Model 3D',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.show_chart_outlined,
                        size: 19,
                        color: AppColors.textMuted,
                      ),
                      selectedIcon: Icon(
                        Icons.show_chart,
                        size: 19,
                        color: AppColors.pharmaNavy,
                      ),
                      label: 'Riwayat',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.settings_outlined,
                        size: 19,
                        color: AppColors.textMuted,
                      ),
                      selectedIcon: Icon(
                        Icons.settings,
                        size: 19,
                        color: AppColors.pharmaNavy,
                      ),
                      label: 'Pengaturan',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderOrganicPainter extends CustomPainter {
  final double progress;

  _HeaderOrganicPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double angle = progress * 2 * math.pi;
    final double wave1 = math.sin(angle);
    final double wave2 = math.cos(angle);

    final leafMint = Paint()
      ..color = AppColors.pharmaTeal.withAlpha(95)
      ..style = PaintingStyle.fill;

    final leafSoft = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.fill;

    // Top-left organic leaf lobe
    final path1 = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        92 + wave1 * 10,
        4 + wave2 * 5,
        74 + wave2 * 8,
        52 + wave1 * 6,
      )
      ..quadraticBezierTo(
        50 + wave1 * 6,
        82 + wave2 * 6,
        0,
        68 + wave1 * 5,
      )
      ..close();
    canvas.drawPath(path1, leafMint);

    // Secondary soft lobe
    final path2 = Path()
      ..moveTo(0, 26 + wave2 * 3)
      ..quadraticBezierTo(
        64 + wave2 * 8,
        36 + wave1 * 6,
        44 + wave1 * 7,
        88 + wave2 * 6,
      )
      ..quadraticBezierTo(
        24 + wave2 * 5,
        106 + wave1 * 5,
        0,
        98 + wave2 * 4,
      )
      ..close();
    canvas.drawPath(path2, leafSoft);

    // Floating ambient orbs on the right side of header
    canvas.drawCircle(
      Offset(size.width * 0.82 + wave1 * 7, 28 + wave2 * 5),
      22 + wave1 * 2.5,
      leafSoft,
    );
    canvas.drawCircle(
      Offset(size.width * 0.66 - wave2 * 5, 54 + wave1 * 4),
      10 + wave2 * 1.5,
      leafMint,
    );
  }

  @override
  bool shouldRepaint(covariant _HeaderOrganicPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
