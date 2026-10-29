import 'package:flutter/foundation.dart';
import '../models/sensor_model.dart';
import '../services/api_service.dart';
import '../services/mqtt_service.dart';
import '../services/storage_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isCritical;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isCritical = false,
  });
}

class SensorProvider extends ChangeNotifier {
  final MqttService _mqttService = MqttService();
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  
  SensorModel _device1Data = SensorModel(
    deviceId: 'device_1',
    suhu: 4.2,
    kelembapan: 45.0,
    kadarGas: 12.0,
    cahaya: 210.0,
    statusKipas: 0,
    statusBuzzer: 0,
    statusPompa: 0,
    status: 'Normal (Suhu & Udara Gudang)',
  );
  SensorModel _device2Data = SensorModel(
    deviceId: 'device_2',
    deteksiGerak: 0,
    statusPintu: 0,
    jarakStok: 28.0,
    statusUv: 0,
    statusLed: 0,
    status: 'Siaga (Sterilisasi & Pintu)',
  );
  String _selectedDeviceId = 'device_1';
  bool _buzzerActive = false;

  bool _isConnected = false;
  bool _isInitialLoading = true;
  bool _isOperator = true;
  final List<AppNotification> _notifications = [];
  
  // Threshold values (loaded from storage)
  double _tempMin = StorageService.defaultTempMin;
  double _tempMax = StorageService.defaultTempMax;
  double _humidityMin = StorageService.defaultHumidityMin;
  double _humidityMax = StorageService.defaultHumidityMax;
  double _gasMax = StorageService.defaultGasMax;
  
  // Track recent notifications to avoid duplicates within time window
  final Map<String, DateTime> _lastNotificationTime = {};
  static const int _notificationCooldownMs = 300000; // 5 minutes

  SensorModel get sensorData => _selectedDeviceId == 'device_1' ? _device1Data : _device2Data;
  SensorModel get device1Data => _device1Data;
  SensorModel get device2Data => _device2Data;
  String get selectedDeviceId => _selectedDeviceId;
  bool get buzzerActive => _buzzerActive;
  bool get isConnected => _isConnected;
  bool get isInitialLoading => _isInitialLoading;
  bool get isOperator => _isOperator;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get notificationCount => _notifications.length;
  
  // Getters for thresholds
  double get tempMin => _tempMin;
  double get tempMax => _tempMax;
  double get humidityMin => _humidityMin;
  double get humidityMax => _humidityMax;
  double get gasMax => _gasMax;

  // Context-aware zone thresholds
  bool get isVaccineRack => _selectedDeviceId == 'device_1';
  double get currentTempMin => isVaccineRack ? _tempMin : 15.0;
  double get currentTempMax => isVaccineRack ? _tempMax : 25.0;
  double get currentHumidityMin => isVaccineRack ? _humidityMin : 45.0;
  double get currentHumidityMax => isVaccineRack ? _humidityMax : 60.0;
  String get currentZoneName =>
      isVaccineRack ? 'Rak Vaksin (Cold Storage)' : 'Ruang Steril (Cleanroom)';

  SensorProvider() {
    _initThresholds();
    _initMqtt();
    refreshUserRole();
  }

  Future<void> refreshUserRole() async {
    _isOperator = await _storageService.isOperator();
    notifyListeners();
  }

  void selectDevice(String id) {
    if (_selectedDeviceId != id) {
      _selectedDeviceId = id;
      notifyListeners();
    }
  }

  // Device 1 Actuator 1: Fan / Kipas Darurat
  bool toggleKipas() {
    if (!_isOperator) return false;
    final nextState = _device1Data.statusKipas == 1 ? 0 : 1;
    _device1Data = _device1Data.copyWith(statusKipas: nextState);
    _mqttService.publish('pharma/control/device_1', '{"actuator":"fan","state":$nextState}');
    _mqttService.publish('pharma/control/fan', '{"device_id":"device_1","state":$nextState}');
    notifyListeners();
    return true;
  }

  // Device 1 Actuator 2: Sirine Buzzer Alarm
  bool toggleBuzzer() {
    if (!_isOperator) return false;
    final nextState = _device1Data.statusBuzzer == 1 ? 0 : 1;
    _device1Data = _device1Data.copyWith(statusBuzzer: nextState);
    _buzzerActive = nextState == 1;
    _mqttService.publish('pharma/control/device_1', '{"actuator":"buzzer","state":$nextState}');
    _mqttService.publish('pharma/control/buzzer', '{"device_id":"device_1","state":$nextState}');
    notifyListeners();
    return true;
  }

  // Device 1 Actuator 3: Mini Water Pump
  bool togglePompa() {
    if (!_isOperator) return false;
    final nextState = _device1Data.statusPompa == 1 ? 0 : 1;
    _device1Data = _device1Data.copyWith(statusPompa: nextState);
    _mqttService.publish('pharma/control/device_1', '{"actuator":"pump","state":$nextState}');
    _mqttService.publish('pharma/control/pump', '{"device_id":"device_1","state":$nextState}');
    notifyListeners();
    return true;
  }

  // Device 2 Actuator 1: Lampu UV Sterilisasi (Dengan Human Interlock Protection)
  bool toggleUv() {
    if (!_isOperator) return false;
    if (_device2Data.isGerakTerdeteksi && _device2Data.statusUv == 0) {
      _addNotification(
        id: 'uv_safety_lock',
        title: 'Safety Interlock Aktif',
        message: 'Lampu UV dicegah menyala: terdeteksi manusia di dalam ruangan!',
        isCritical: true,
      );
      return false;
    }
    final nextState = _device2Data.statusUv == 1 ? 0 : 1;
    _device2Data = _device2Data.copyWith(statusUv: nextState);
    _mqttService.publish('pharma/control/device_2', '{"actuator":"uv","state":$nextState}');
    _mqttService.publish('pharma/control/uv', '{"device_id":"device_2","state":$nextState}');
    notifyListeners();
    return true;
  }

  // Device 2 Actuator 2: LED Indikator Ruangan Aman/Bahaya
  bool toggleLed() {
    if (!_isOperator) return false;
    final nextState = _device2Data.statusLed == 1 ? 0 : 1;
    _device2Data = _device2Data.copyWith(statusLed: nextState);
    _mqttService.publish('pharma/control/device_2', '{"actuator":"led","state":$nextState}');
    _mqttService.publish('pharma/control/led', '{"device_id":"device_2","state":$nextState}');
    notifyListeners();
    return true;
  }

  Future<void> _initThresholds() async {
    final thresholds = await _storageService.getThresholds();
    _tempMin = thresholds['tempMin'] ?? StorageService.defaultTempMin;
    _tempMax = thresholds['tempMax'] ?? StorageService.defaultTempMax;
    _humidityMin = thresholds['humidityMin'] ?? StorageService.defaultHumidityMin;
    _humidityMax = thresholds['humidityMax'] ?? StorageService.defaultHumidityMax;
    _gasMax = thresholds['gasMax'] ?? StorageService.defaultGasMax;
  }

  Future<void> _fetchInitialApiData() async {
    try {
      final history = await _apiService.fetchSensorHistory();
      if (history.isNotEmpty) {
        _device1Data = history.first.copyWith(deviceId: 'device_1');
        if (_device2Data.waktu == null) {
          _device2Data = _device2Data.copyWith(
            waktu: history.first.waktu,
          );
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void _initMqtt() {
    _fetchInitialApiData();
    
    // Timeout fallback: stop loading after 3 seconds even if no MQTT response
    Future.delayed(const Duration(seconds: 3), () {
      if (_isInitialLoading) {
        _isInitialLoading = false;
        final statusText1 = _isConnected ? 'Aktif (Telemetri)' : 'Offline (Data Terakhir)';
        final statusText2 = _isConnected ? 'Aktif (Telemetri)' : 'Offline (Data Terakhir)';
        _device1Data = _device1Data.copyWith(status: statusText1);
        _device2Data = _device2Data.copyWith(status: statusText2);
        notifyListeners();
      }
    });
    
    _mqttService.onDataReceived = (data) {
      if (data.deviceId == 'device_2') {
        _device2Data = data;
      } else {
        _device1Data = data;
      }
      _isInitialLoading = false;
      _checkAndAddNotifications(data);
      notifyListeners();
    };
    _mqttService.onConnectionChanged = (connected) {
      _isConnected = connected;
      _isInitialLoading = false;
      if (!connected) {
        _device1Data = _device1Data.copyWith(status: 'Terputus');
        _device2Data = _device2Data.copyWith(status: 'Terputus');
        _addNotification(
          id: 'conn_lost',
          title: 'Koneksi Terputus',
          message: 'Terputus dari broker MQTT',
          isCritical: true,
        );
      } else {
        _addNotification(
          id: 'conn_ok',
          title: 'Koneksi Terhubung',
          message: 'Terhubung ke broker MQTT',
          isCritical: false,
        );
      }
      notifyListeners();
    };
    _mqttService.connect();
  }

  void _checkAndAddNotifications(SensorModel data) {
    final double minT = _tempMin;
    final double maxT = _tempMax;

    if (data.deviceId == 'device_1') {
      if (data.kadarGas > _gasMax) {
        _addNotificationOnce(
          id: 'gas_alert',
          title: 'Bahaya Gas / Asap (MQ-2)',
          message: 'Asap/gas terdeteksi tinggi: ${data.kadarGas.toStringAsFixed(1)} PPM! Relay Fan & Sirine aktif.',
          isCritical: true,
        );
      }
      if (data.suhu < minT || data.suhu > maxT) {
        _addNotificationOnce(
          id: 'temp_alert',
          title: 'Suhu Cold Storage Kritis (DHT22)',
          message: 'Suhu terima ${data.suhu.toStringAsFixed(1)}°C (Standar: ${minT.toStringAsFixed(1)}°C - ${maxT.toStringAsFixed(1)}°C)',
          isCritical: false,
        );
      }
    } else {
      // Device 2
      if (data.isGerakTerdeteksi) {
        _addNotificationOnce(
          id: 'pir_alert',
          title: 'Deteksi Gerakan (PIR)',
          message: 'Aktivitas manusia terdeteksi di ruangan! Sistem UV wajib aman.',
          isCritical: false,
        );
        // Interlock: jika UV sedang menyala saat manusia masuk, matikan otomatis!
        if (_device2Data.isUvMenyala) {
          _device2Data = _device2Data.copyWith(statusUv: 0);
          _mqttService.publish('pharma/control/device_2', '{"actuator":"uv","state":0}');
          _mqttService.publish('pharma/control/uv', '{"device_id":"device_2","state":0}');
          _addNotification(
            id: 'uv_auto_off',
            title: 'UV Interlock Shutdown',
            message: 'Lampu UV dimatikan otomatis demi keselamatan personil!',
            isCritical: true,
          );
        }
      }
      if (data.isPintuTerbuka) {
        _addNotificationOnce(
          id: 'door_alert',
          title: 'Pintu Gudang Terbuka (Reed Switch)',
          message: 'Pintu gudang terbuka! Periksa akses ruangan.',
          isCritical: false,
        );
      }
    }
  }

  void _addNotificationOnce({
    required String id,
    required String title,
    required String message,
    required bool isCritical,
  }) {
    final now = DateTime.now();
    final lastTime = _lastNotificationTime[id];
    
    // Skip if alert fired recently (cooldown)
    if (lastTime != null && now.difference(lastTime).inMilliseconds < _notificationCooldownMs) {
      return;
    }
    
    _lastNotificationTime[id] = now;
    _addNotification(id: id, title: title, message: message, isCritical: isCritical);
  }

  void _addNotification({
    required String id,
    required String title,
    required String message,
    required bool isCritical,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: id,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        isCritical: isCritical,
      ),
    );
    if (_notifications.length > 20) {
      _notifications.removeLast();
    }
  }

  Future<void> updateThresholds({
    required double tempMin,
    required double tempMax,
    required double humidityMin,
    required double humidityMax,
    required double gasMax,
  }) async {
    await _storageService.saveThresholds(
      tempMin: tempMin,
      tempMax: tempMax,
      humidityMin: humidityMin,
      humidityMax: humidityMax,
      gasMax: gasMax,
    );
    _tempMin = tempMin;
    _tempMax = tempMax;
    _humidityMin = humidityMin;
    _humidityMax = humidityMax;
    _gasMax = gasMax;
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void reconnect() {
    _isInitialLoading = true;
    _device1Data = _device1Data.copyWith(status: 'Menghubungkan Ulang...');
    _device2Data = _device2Data.copyWith(status: 'Menghubungkan Ulang...');
    notifyListeners();
    _fetchInitialApiData();
    _mqttService.connect();
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }
}
