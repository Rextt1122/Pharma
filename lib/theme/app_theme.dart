import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF3F7F6);
  // Deep botanical-clinical teal palette matching the Login Page reference.
  static const Color pharmaNavy = Color(0xFF0E555A);
  static const Color pharmaBlue = Color(0xFF1F7A7C);
  static const Color pharmaTeal = Color(0xFF439A86);
  static const Color textDark = Color(0xFF102A2C);
  static const Color textMuted = Color(0xFF627D7F);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFEAF1F0);
  static const Color containerLow = Color(0xFFE1ECEA);
  static const Color containerHigh = Color(0xFFCCE0DC);
  static const Color activeGreen = Color(0xFF1E8E68);
  static const Color alertRed = Color(0xFFD63D42);
  static const Color tempRed = Color(0xFFE06358);
  static const Color warningAmber = Color(0xFFD9822B);
  static const Color humidityBlue = Color(0xFF287C9E);
  static const Color uvPurple = Color(0xFF6B5B95);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Unified shape radii:
  static const double radiusSm = 10.0;  // Small inner controls and tags
  static const double radiusMd = 18.0;  // Inputs and compact tiles
  static const double radiusLg = 24.0;  // Primary cards and containers
  static const double radiusPill = 999.0; // Rounded actions and status chips
}

class AppTypography {
  static const TextStyle heading = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.1,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0.3,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pharmaNavy,
        primary: AppColors.pharmaNavy,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFE0F2FE),
        onPrimaryContainer: const Color(0xFF0369A1),
        secondary: AppColors.pharmaBlue,
        surface: AppColors.background,
        surfaceContainerLowest: AppColors.background,
        surfaceContainerLow: AppColors.cardWhite,
        surfaceContainer: AppColors.cardWhite,
        surfaceContainerHigh: AppColors.cardWhite,
        surfaceContainerHighest: AppColors.containerLow,
        onSurface: AppColors.textDark,
        outline: AppColors.textMuted,
        outlineVariant: AppColors.containerHigh,
      ),
      scaffoldBackgroundColor: AppColors.background,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            height: 1.1,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            height: 1.1,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}
