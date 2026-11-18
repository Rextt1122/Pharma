// ============================================================================
// DOKUMENTASI KODE: navigation_service.dart — Navigator global untuk redirect sesi
// Dibaca sebagai referensi implementasi; komentar hanya menjelaskan alur penting.
// ============================================================================
import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';

/// Navigator global, dipakai service untuk redirect ke login saat sesi habis.
// Navigator global. Dibuat di luar widget tree agar service non-UI dapat
// mengarahkan ulang halaman tanpa BuildContext.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// Memaksa aplikasi kembali ke halaman login dan menampilkan toast.
//
// addPostFrameCallback dipakai karena fungsi ini sering dipanggil dari dalam
// respons HTTP (di luar fase build); navigasi langsung akan memicu error
// setState() or markNeedsBuild() called during build.
void redirectToLogin() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil('/login', (_) => false);
    final ctx = appNavigatorKey.currentContext;
    if (ctx != null) {
      AppToast.warning(ctx, 'Sesi berakhir. Silakan login kembali.');
    }
  });
}
