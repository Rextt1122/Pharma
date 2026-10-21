import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';
import 'realtime_page.dart';
import 'model_3d_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    RealtimePage(),
    Model3dPage(),
    HistoryPage(),
    SettingsPage(),
  ];

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: AppSpacing.md,
        title: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: const BoxDecoration(
                  color: AppColors.cardWhite,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  size: 20,
                  color: AppColors.pharmaNavy,
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
                      style: AppTypography.heading.copyWith(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Smart Pharma Warehouse • 30 Sep 2026',
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => _showNotificationSheet(context, sensorProvider),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: const BoxDecoration(
                        color: AppColors.cardWhite,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                        color: AppColors.pharmaNavy,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.alertRed,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 52,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.pharmaNavy : AppColors.textMuted,
                  );
                }),
              ),
              child: NavigationBar(
                height: 52,
                elevation: 0,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: AppColors.cardWhite,
                indicatorColor: AppColors.pharmaNavy.withAlpha(20),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.sensors_outlined, size: 19, color: AppColors.textMuted),
                    selectedIcon: Icon(Icons.sensors, size: 19, color: AppColors.pharmaNavy),
                    label: 'Realtime',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.view_in_ar_outlined, size: 19, color: AppColors.textMuted),
                    selectedIcon: Icon(Icons.view_in_ar, size: 19, color: AppColors.pharmaNavy),
                    label: 'Model 3D',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.show_chart_outlined, size: 19, color: AppColors.textMuted),
                    selectedIcon: Icon(Icons.show_chart, size: 19, color: AppColors.pharmaNavy),
                    label: 'Riwayat',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined, size: 19, color: AppColors.textMuted),
                    selectedIcon: Icon(Icons.settings, size: 19, color: AppColors.pharmaNavy),
                    label: 'Pengaturan',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
