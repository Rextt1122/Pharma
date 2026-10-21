import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/sensor_provider.dart';
import 'providers/history_provider.dart';
import 'theme/app_theme.dart';
import 'views/login_page.dart';
import 'views/main_navigation.dart';
import 'views/splash_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
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
