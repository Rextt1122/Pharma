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
    statusPintu: 0,
    statusUv: 0,
    status: 'Normal (Cold Storage)',
  );
  SensorModel _device2Data = SensorModel(
    deviceId: 'device_2',
    suhu: 21.8,
    kelembapan: 53.0,
    kadarGas: 18.5,
    statusPintu: 0,
    statusUv: 1,
    status: 'Normal (Suhu Ruang & UV)',
  );
  String _selectedDeviceId = 'device_1';
  bool _buzzerActive = false;

  bool _isConnected = false;
  bool _isInitialLoading = true;
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
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get notificationCount => _notifications.length;
  
  // Getters for thresholds
  double get tempMin => _tempMin;
  double get tempMax => _tempMax;
  double get humidityMin => _humidityMin;
  double get humidityMax => _humidityMax;
  double get gasMax => _gasMax;

  SensorProvider() {
    _initThresholds();
    _initMqtt();
  }

  void selectDevice(String id) {
    if (_selectedDeviceId != id) {
      _selectedDeviceId = id;
      notifyListeners();
    }
  }

  void toggleUv() {
    final current = sensorData;
    final nextState = current.statusUv == 1 ? 0 : 1;
    final updated = current.copyWith(statusUv: nextState);
    if (_selectedDeviceId == 'device_1') {
      _device1Data = updated;
    } else {
      _device2Data = updated;
    }
    _mqttService.publish('pharma/control/$_selectedDeviceId', '{"actuator":"uv","state":$nextState}');
    _mqttService.publish('pharma/control/uv', '{"device_id":"$_selectedDeviceId","state":$nextState}');
    notifyListeners();
  }

  void toggleBuzzer() {
    _buzzerActive = !_buzzerActive;
    final state = _buzzerActive ? 1 : 0;
    _mqttService.publish('pharma/control/$_selectedDeviceId', '{"actuator":"buzzer","state":$state}');
    _mqttService.publish('pharma/control/buzzer', '{"device_id":"$_selectedDeviceId","state":$state}');
    notifyListeners();
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
    if (data.kadarGas > _gasMax) {
      _addNotificationOnce(
        id: 'gas_alert',
        title: 'Peringatan Gas / Asap',
        message: 'Kadar gas tinggi terdeteksi: ${data.kadarGas.toStringAsFixed(1)} PPM',
        isCritical: true,
      );
    }
    if (data.isPintuTerbuka) {
      _addNotificationOnce(
        id: 'door_alert',
        title: 'Pintu Gudang Terbuka',
        message: 'Pintu gudang dalam keadaan terbuka!',
        isCritical: false,
      );
    }
    if (data.suhu < _tempMin || data.suhu > _tempMax) {
      _addNotificationOnce(
        id: 'temp_alert',
        title: 'Suhu Tidak Normal',
        message: 'Suhu terima ${data.suhu.toStringAsFixed(1)}°C (Batas: ${_tempMin.toStringAsFixed(1)}°C - ${_tempMax.toStringAsFixed(1)}°C)',
        isCritical: false,
      );
    }
    if (data.kelembapan < _humidityMin || data.kelembapan > _humidityMax) {
      _addNotificationOnce(
        id: 'humidity_alert',
        title: 'Kelembapan Tidak Normal',
        message: 'Kelembapan terima ${data.kelembapan.toStringAsFixed(1)}% (Batas: ${_humidityMin.toStringAsFixed(1)}% - ${_humidityMax.toStringAsFixed(1)}%)',
        isCritical: false,
      );
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
