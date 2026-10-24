import 'package:flutter/material.dart';

/// Navigator global, dipakai service untuk redirect ke login saat sesi habis.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void redirectToLogin() {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;
  nav.pushNamedAndRemoveUntil('/login', (_) => false);
  final ctx = appNavigatorKey.currentContext;
  if (ctx != null) {
    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
      const SnackBar(content: Text('Sesi berakhir. Silakan login ulang.')),
    );
  }
}
