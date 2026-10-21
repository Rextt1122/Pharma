import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyServerIp = 'server_ip';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // Threshold keys
  static const String _keyTempMin = 'threshold_temp_min';
  static const String _keyTempMax = 'threshold_temp_max';
  static const String _keyHumidityMin = 'threshold_humidity_min';
  static const String _keyHumidityMax = 'threshold_humidity_max';
  static const String _keyGasMax = 'threshold_gas_max';

  // Ubah defaultIp ke IP PC kamu di jaringan LAN (cek dengan `ipconfig`)
  // Bukan IP VirtualBox Host-Only (192.168.33.x) — HP tidak bisa reach itu.
  static const String defaultIp = '192.168.1.100';

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
