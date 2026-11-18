// ============================================================================
// DOKUMENTASI: main.dart — Titik masuk aplikasi Pharma Medic
//
// Menyiapkan binding Flutter, gaya system bar, provider global, dan tabel rute.
// Alur: main() -> MyApp -> SplashPage -> (sesi valid ? MainNavigation : LoginPage)
// Berkas terkait: providers/, services/navigation_service.dart, theme/app_theme.dart
//
// Dibaca sebagai referensi implementasi; komentar menjelaskan alasan, bukan mengulang nama simbol.
// ============================================================================
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
//
// Menyediakan dua ChangeNotifier global: SensorProvider (telemetri realtime) dan
// HistoryProvider (log historis). Keduanya hidup selama aplikasi berjalan sehingga
// perpindahan tab tidak memicu koneksi ulang.
//
// Rute: /splash (cek sesi) -> /login atau /main.
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
