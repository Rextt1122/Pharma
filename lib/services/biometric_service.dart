// ============================================================================
// DOKUMENTASI KODE: biometric_service.dart — Verifikasi biometrik untuk membuka sesi tersimpan
// Dibaca sebagai referensi implementasi; komentar hanya menjelaskan alur penting.
// ============================================================================
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

// Memverifikasi biometrik hanya untuk membuka sesi bertoken yang sudah ada.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  Future<bool> authenticate({
    String reason = 'Verifikasi biometrik untuk akses sistem gudang farmasi',
  }) async {
    try {
      final supported = await isDeviceSupported();
      if (!supported) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }
}
