import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppToastType { success, error, warning, info }

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
    IconData? customIcon,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    Color bg;
    IconData icon;

    switch (type) {
      case AppToastType.success:
        bg = AppColors.activeGreen;
        icon = Icons.check_circle_rounded;
        break;
      case AppToastType.error:
        bg = AppColors.alertRed;
        icon = Icons.error_outline_rounded;
        break;
      case AppToastType.warning:
        bg = AppColors.warningAmber;
        icon = Icons.warning_amber_rounded;
        break;
      case AppToastType.info:
        bg = AppColors.pharmaNavy;
        icon = Icons.info_outline_rounded;
        break;
    }

    if (customIcon != null) {
      icon = customIcon;
    }

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        duration: duration,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message, type: AppToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message, type: AppToastType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message, type: AppToastType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message, type: AppToastType.info);
  }
}
