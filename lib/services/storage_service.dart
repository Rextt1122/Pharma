// ============================================================================
// DOKUMENTASI: storage_service.dart — Penyimpanan lokal dan siklus sesi
//
// SharedPreferences untuk data non-rahasia; FlutterSecureStorage untuk token JWT.
// Token backend 2 bagian (payload.signature); exp dicek sebelum dipakai.
// Berkas terkait: services/api_service.dart, providers/sensor_provider.dart, views/settings_page.dart
//
// Dibaca sebagai referensi implementasi; komentar menjelaskan alasan, bukan mengulang nama simbol.
// ============================================================================
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Penyimpanan konfigurasi, profil, dan status sesi lokal.
// Satu pintu untuk semua data lokal.
//
// Pembagian media penyimpanan:
//   - SharedPreferences : alamat server, profil, peran, preferensi biometrik,
//     ambang batas sensor. Bukan rahasia.
//   - FlutterSecureStorage : token JWT. Terenkripsi oleh Keystore/Keychain.
//
// Token disimpan di secure storage karena kebocoran token sama dengan
// kebocoran akun; data lain cukup di preferences.
class StorageService {
  static const String _keyServerIp = 'server_ip';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyBiometricToken = 'biometric_token';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyAuthProvider = 'auth_provider';
  static const String _keyUserAvatar = 'user_avatar';

  // Threshold keys
  static const String _keyTempMin = 'threshold_temp_min';
  static const String _keyTempMax = 'threshold_temp_max';
  static const String _keyHumidityMin = 'threshold_humidity_min';
  static const String _keyHumidityMax = 'threshold_humidity_max';
  static const String _keyGasMax = 'threshold_gas_max';

  // Default IP / Domain Cloud
  // Nilai bawaan produksi. Bisa diganti pengguna di halaman Pengaturan.
  static const String defaultIp = 'api.pharma.web.id';

  // Port untuk REST API FastAPI
  static const int apiPort = 8001;

  // Port untuk MQTT via WebSocket
  static const int mqttWsPort = 9001;

  // Default threshold values (farmasi storage)
  // Ambang rantai dingin vaksin: 2-8 °C. Nilai ini dipakai bila pengguna belum
  // mengubah ambang di Pengaturan.
  static const double defaultTempMin = 2.0;
  static const double defaultTempMax = 8.0;
  static const double defaultHumidityMin = 35.0;
  static const double defaultHumidityMax = 60.0;
  static const double defaultGasMax = 50.0;

  Future<void> saveServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerIp, ip.trim());
  }

  Future<String> getServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(_keyServerIp);
    if (ip == null || ip == '192.168.33.10' || ip == '192.168.1.100') {
      await prefs.setString(_keyServerIp, defaultIp);
      return defaultIp;
    }
    return ip;
  }

  // Auth persistence: token sesi disimpan terenkripsi (Keystore / Keychain)
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  // Menyimpan token sesi. Bila biometrik aktif, token biometrik ikut
  // disinkronkan agar sidik jari membuka sesi terbaru, bukan sesi lama.
  Future<void> saveAuthToken(String token) async {
    await _secure.write(key: _keyAuthToken, value: token);
    // Login password baru: segarkan token biometrik kalau fitur aktif.
    if (await isBiometricEnabled()) {
      await _secure.write(key: _keyBiometricToken, value: token);
    }
  }

  // Token yang masih berlaku, atau null bila tidak ada/kedaluwarsa.
  // Pemeriksaan kedaluwarsa dilakukan di klien supaya request yang pasti gagal
  // tidak perlu dikirim.
  Future<String?> getAuthToken() async {
    final token = await _secure.read(key: _keyAuthToken);
    if (token == null || _isExpired(token)) return null;
    return token;
  }

  // Dipakai splash screen untuk memilih rute awal.
  Future<bool> isLoggedIn() async => (await getAuthToken()) != null;

  /// Logout. Token biometrik ikut dihapus kecuali login biometrik aktif.
  // Logout biasa. Token biometrik dipertahankan bila pengguna mengaktifkan
  // login biometrik, supaya ia bisa masuk lagi tanpa mengetik sandi.
  Future<void> clearSession() async {
    await _secure.delete(key: _keyAuthToken);
    if (!await isBiometricEnabled()) {
      await _secure.delete(key: _keyBiometricToken);
    }
  }

  /// Sesi tidak valid (401 / kedaluwarsa): hapus semua token.
  // Sesi ditolak server (401) atau token rusak: hapus semuanya termasuk token
  // biometrik, karena token itu sudah tidak sah.
  Future<void> invalidateSession() async {
    await _secure.delete(key: _keyAuthToken);
    await _secure.delete(key: _keyBiometricToken);
  }

  Future<void> storeBiometricToken() async {
    final token = await getAuthToken();
    if (token != null) {
      await _secure.write(key: _keyBiometricToken, value: token);
    }
  }

  Future<void> removeBiometricToken() =>
      _secure.delete(key: _keyBiometricToken);

  Future<bool> hasBiometricToken() async {
    final token = await _secure.read(key: _keyBiometricToken);
    return token != null && !_isExpired(token);
  }

  /// Setelah biometrik lolos: pulihkan sesi dari token tersimpan.
  // Setelah biometrik lolos, token biometrik dipromosikan menjadi token sesi
  // aktif. Return false bila token tidak ada atau kedaluwarsa.
  Future<bool> restoreSessionFromBiometric() async {
    final token = await _secure.read(key: _keyBiometricToken);
    if (token == null || _isExpired(token)) return false;
    await _secure.write(key: _keyAuthToken, value: token);
    return true;
  }

  // Token backend hanya punya dua bagian (payload.signature), bukan tiga
  // seperti JWT standar. Payload adalah base64url JSON dengan field "exp" dalam
  // detik epoch. Format tak dikenal dianggap kedaluwarsa (fail closed).
  static bool _isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 2) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64.normalize(parts[0]))),
      ) as Map<String, dynamic>;
      final exp = (payload['exp'] as num?)?.toInt() ?? 0;
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
    } catch (_) {
      return true;
    }
  }

  // Payload token tanpa verifikasi tanda tangan. Hanya untuk membaca uid,
  // username, dan role; otorisasi tetap ditentukan server.
  Future<Map<String, dynamic>?> getTokenPayload() async {
    final token = await getAuthToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 2) return null;
      return jsonDecode(
        utf8.decode(base64Url.decode(base64.normalize(parts[0]))),
      ) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<int?> getUserId() async {
    final payload = await getTokenPayload();
    return (payload?['uid'] as num?)?.toInt();
  }

  Future<String?> getUsername() async {
    final payload = await getTokenPayload();
    return payload?['usr']?.toString();
  }

  // Biometric preference
  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, value);
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  Future<void> saveUserProfile({
    required String name,
    required String email,
    required String provider,
    String? role,
    String? avatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name.trim());
    await prefs.setString(_keyUserEmail, email.trim());
    await prefs.setString(_keyAuthProvider, provider.trim());
    if (role != null) {
      await prefs.setString(_keyUserRole, role.trim().toLowerCase());
    }
    if (avatar != null) {
      await prefs.setString(_keyUserAvatar, avatar);
    }
  }

  Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRole, role.trim().toLowerCase());
  }

  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyUserRole);
    if (saved != null && saved.isNotEmpty) return saved.toLowerCase();
    final token = await getAuthToken();
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 2) {
          final payload = jsonDecode(
            utf8.decode(base64Url.decode(base64.normalize(parts[0]))),
          ) as Map<String, dynamic>;
          final r = payload['role']?.toString();
          if (r != null && r.isNotEmpty) return r.toLowerCase();
        }
      } catch (_) {}
    }
    return 'user';
  }

  // Operator dan admin boleh mengendalikan aktuator; peran lain hanya melihat.
  Future<bool> isOperator() async {
    final role = await getUserRole();
    return role == 'operator' || role == 'admin';
  }

  Future<void> saveUserAvatar(String avatarData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserAvatar, avatarData);
  }

  Future<Map<String, String>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyUserName) ?? 'Pengguna Farmasi',
      'email': prefs.getString(_keyUserEmail) ?? 'user@smartpharma.id',
      'role': prefs.getString(_keyUserRole) ?? (await getUserRole()),
      'provider': prefs.getString(_keyAuthProvider) ?? 'Smart Pharma',
      'avatar': prefs.getString(_keyUserAvatar) ?? '',
    };
  }

  // Threshold methods
  // Menyimpan ambang sensor yang diubah pengguna. Dibaca kembali oleh
  // SensorProvider saat aplikasi dibuka.
  Future<void> saveThresholds({
    required double tempMin,
    required double tempMax,
    required double humidityMin,
    required double humidityMax,
    required double gasMax,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTempMin, tempMin);
    await prefs.setDouble(_keyTempMax, tempMax);
    await prefs.setDouble(_keyHumidityMin, humidityMin);
    await prefs.setDouble(_keyHumidityMax, humidityMax);
    await prefs.setDouble(_keyGasMax, gasMax);
  }

  Future<Map<String, double>> getThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'tempMin': prefs.getDouble(_keyTempMin) ?? defaultTempMin,
      'tempMax': prefs.getDouble(_keyTempMax) ?? defaultTempMax,
      'humidityMin': prefs.getDouble(_keyHumidityMin) ?? defaultHumidityMin,
      'humidityMax': prefs.getDouble(_keyHumidityMax) ?? defaultHumidityMax,
      'gasMax': prefs.getDouble(_keyGasMax) ?? defaultGasMax,
    };
  }
}
