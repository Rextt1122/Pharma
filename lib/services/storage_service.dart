import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyServerIp = 'server_ip';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyAuthProvider = 'auth_provider';

  // Threshold keys
  static const String _keyTempMin = 'threshold_temp_min';
  static const String _keyTempMax = 'threshold_temp_max';
  static const String _keyHumidityMin = 'threshold_humidity_min';
  static const String _keyHumidityMax = 'threshold_humidity_max';
  static const String _keyGasMax = 'threshold_gas_max';

  // IP VirtualBox Host-Only (192.168.33.10).
  static const String defaultIp = '192.168.33.10';

  // Port untuk REST API FastAPI
  static const int apiPort = 8001;

  // Port untuk MQTT via WebSocket (Mosquitto harus listen di 9001)
  static const int mqttWsPort = 9001;

  // Default threshold values (farmasi storage)
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
    return prefs.getString(_keyServerIp) ?? defaultIp;
  }

  // Auth persistence
  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, value);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name.trim());
    await prefs.setString(_keyUserEmail, email.trim());
    await prefs.setString(_keyAuthProvider, provider.trim());
  }

  Future<Map<String, String>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyUserName) ?? 'Fabian (Admin Farmasi)',
      'email': prefs.getString(_keyUserEmail) ?? 'fabian.pharma@smartpharma.id',
      'provider': prefs.getString(_keyAuthProvider) ?? 'Smart Pharma',
    };
  }

  // Threshold methods
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
