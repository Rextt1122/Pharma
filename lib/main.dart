// main.dart — Bootstrap aplikasi
// Provider global, tema, rute /splash -> /login -> /main.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/sensor_provider.dart';
import 'providers/history_provider.dart';
import 'services/navigation_service.dart';
import 'theme/app_theme.dart';
import 'views/login_page.dart';
import 'views/main_navigation.dart';
import 'views/splash_page.dart';

// Entry point aplikasi. Menyiapkan binding Flutter dan dependency global sebelum UI dirender.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

// Akar widget aplikasi.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // SensorProvider dibuat sekali di root supaya koneksi MQTT/REST tidak terputus
        // saat pengguna berpindah halaman.
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        // HistoryProvider ikut di root karena halaman riwayat dan dashboard memakai
        // data yang sama; constructor-nya langsung memuat log awal.
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        // Navigator key global dipakai ApiService untuk memaksa kembali ke /login
        // ketika token kedaluwarsa (lihat navigation_service.dart).
        navigatorKey: appNavigatorKey,
        title: 'Pharma Medic',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashPage(),
          '/login': (context) => const LoginPage(),
          '/main': (context) => const MainNavigation(),
        },
      ),
    );
  }
}
