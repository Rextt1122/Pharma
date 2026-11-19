// app_toast.dart — Notifikasi
// SnackBar seragam: sukses, gagal, peringatan, info.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Varian notifikasi. Tiap varian menentukan warna latar dan ikon bawaan.
enum AppToastType { success, error, warning, info }

// Pembungkus SnackBar agar semua umpan balik memakai bentuk, warna, dan jarak
// yang sama. Selalu pakai kelas ini, jangan memanggil ScaffoldMessenger langsung.
class AppToast {
  // Menampilkan satu notifikasi.
  static void show(
    BuildContext context,
    String message, {
    String? title,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
    IconData? customIcon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // maybeOf + return: aman dipanggil dari service setelah layar ditutup,
    // tidak melempar exception.
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

    // Antrian dibersihkan agar notifikasi baru tidak mengantre di belakang yang lama.
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(45),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 2),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty) ...[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withAlpha(title != null ? 230 : 255),
                      fontWeight: title != null ? FontWeight.w500 : FontWeight.w600,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withAlpha(40),
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        duration: duration,
      ),
    );
  }

  // Pintasan untuk pesan sukses (hijau, ikon centang).
  static void success(BuildContext context, String message, {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(context, message, title: title, type: AppToastType.success, actionLabel: actionLabel, onAction: onAction);
  }

  // Pintasan untuk pesan gagal (merah). Gunakan untuk kegagalan yang perlu
  // diketahui pengguna, bukan untuk error internal.
  static void error(BuildContext context, String message, {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(context, message, title: title, type: AppToastType.error, actionLabel: actionLabel, onAction: onAction);
  }

  // Pintasan untuk peringatan (oranye), mis. sensor mendekati ambang.
  static void warning(BuildContext context, String message, {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(context, message, title: title, type: AppToastType.warning, actionLabel: actionLabel, onAction: onAction);
  }

  // Pintasan untuk informasi netral (navy).
  static void info(BuildContext context, String message, {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(context, message, title: title, type: AppToastType.info, actionLabel: actionLabel, onAction: onAction);
  }
}
