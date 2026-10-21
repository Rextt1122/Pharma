import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF1F5F9);
  // Brand palette: calm, clinical primary with a high-visibility action color.
  static const Color pharmaNavy = Color(0xFF2C3E50);
  static const Color pharmaBlue = Color(0xFFE67E22); // Secondary / action amber.
  static const Color pharmaTeal = Color(0xFF0D9488);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardWhite = Colors.white;
  static const Color inputBg = Color(0xFFF8FAFC);
  static const Color containerLow = Color(0xFFE2E8F0);
  static const Color containerHigh = Color(0xFFCBD5E1);
  static const Color activeGreen = Color(0xFF10B981);
  static const Color alertRed = Color(0xFFDC2626);
  static const Color tempRed = Color(0xFFE87A72);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color humidityBlue = Color(0xFF4A80A0);
  static const Color uvPurple = Color(0xFF7C3AED);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Unified shape radii:
  static const double radiusSm = 8.0;   // Inner tags, chips, sub-elements
  static const double radiusMd = 14.0;  // Buttons, text inputs, metric tiles
  static const double radiusLg = 20.0;  // All primary cards & containers
  static const double radiusPill = 999.0; // Clean rounded badges & pills
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
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.0,
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
