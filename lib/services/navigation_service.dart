import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';

/// Navigator global, dipakai service untuk redirect ke login saat sesi habis.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void redirectToLogin() {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;
  nav.pushNamedAndRemoveUntil('/login', (_) => false);
  final ctx = appNavigatorKey.currentContext;
  if (ctx != null) {
    AppToast.warning(ctx, 'Sesi berakhir. Silakan login ulang.');
  }
}
