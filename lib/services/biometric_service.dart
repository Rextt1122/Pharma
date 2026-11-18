// ============================================================================
// DOKUMENTASI KODE: biometric_service.dart — Verifikasi biometrik untuk membuka sesi tersimpan
// Dibaca sebagai referensi implementasi; komentar hanya menjelaskan alur penting.
// ============================================================================
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

// Pembungkus local_auth. Biometrik hanya membuka sesi yang tokennya sudah
// tersimpan di perangkat; bukan pengganti autentikasi server.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // True bila perangkat punya sensor dan sudah mendaftarkan biometrik.
  // PlatformException (mis. emulator tanpa hardware) diperlakukan sebagai false.
  Future<bool> isDeviceSupported() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    }
  }

  // Daftar jenis biometrik terdaftar (sidik jari, wajah, iris) untuk
  // menyesuaikan ikon dan teks di halaman login.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  // Menampilkan dialog biometrik sistem.
  //
  // reason : teks yang tampil di dialog, jelaskan tujuannya ke pengguna.
  // biometricOnly=true mencegah PIN/pola perangkat dipakai sebagai jalan pintas.
  // persistAcrossBackgrounding menjaga dialog tetap valid saat aplikasi sempat
  // ke background (mis. menerima panggilan).
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
