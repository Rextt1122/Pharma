// sensor_provider.dart — State dashboard
// Gabungan REST + MQTT, ambang batas, notifikasi, kontrol aktuator.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/sensor_model.dart';
import '../services/api_service.dart';
import '../services/mqtt_service.dart';
import '../services/storage_service.dart';

// Entri notifikasi dalam aplikasi (bukan push notification).
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

// State pusat dashboard: telemetri dua node, status koneksi, peran pengguna,
// ambang batas, dan notifikasi.
class SensorProvider extends ChangeNotifier {
  final MqttService _mqttService = MqttService();
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  
  // Inisialisasi awal Node 1 (Rak Vaksin). Standar cold chain 2.0 - 8.0 C.
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

  // Inisialisasi awal Node 2 (Ruang Steril & Cleanroom).
  // Dokumentasi: Nilai default suhu (22.0 C) & kelembapan (50.0%) disesuaikan dengan
  // standar Cleanroom ISO/BPOM (15 - 25 C) agar saat aplikasi pertama kali dibuka
  // tidak menampilkan angka 0.0 C / 0% sebelum telemetri MQTT mengalir.
  SensorModel _device2Data = SensorModel(
    deviceId: 'device_2',
    suhu: 22.0,
    kelembapan: 50.0,
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
  bool get buzzerActive => _device1Data.isBuzzerAktif || _buzzerActive;
  bool get isUvActive => _device2Data.isUvMenyala || _device1Data.isUvMenyala;
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

  // Urutan inisialisasi: ambang batas dari penyimpanan, koneksi MQTT
  // (termasuk fetch REST awal), lalu peran pengguna.
  SensorProvider() {
    _initThresholds();
    _initMqtt();
    refreshUserRole();
  }

  // Membaca peran (operator/penonton) dari penyimpanan. Hanya operator yang
  // boleh menekan tombol aktuator; penonton tetap melihat nilai sensor.
  Future<void> refreshUserRole() async {
    _isOperator = await _storageService.isOperator();
    notifyListeners();
  }

  // Mengganti node yang ditampilkan dashboard. Data kedua node tetap
  // diperbarui di background, jadi perpindahan tidak menunggu koneksi.
  void selectDevice(String id) {
    if (_selectedDeviceId != id) {
      _selectedDeviceId = id;
      notifyListeners();
    }
  }

  // Device 1 Actuator 1: Fan / Kipas Darurat
  // Kipas Device 1. Dua topik dipublikasikan sekaligus agar firmware versi lama
  // (pharma/control/fan) dan versi baru (pharma/control/device_1) sama-sama
  // mendengar perintah.
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
  // Sirine Device 1. State dikirim ke topik per-device dan topik legacy.
  bool toggleBuzzer() {
    if (!_isOperator) return false;
    final nextState = buzzerActive ? 0 : 1;
    _device1Data = _device1Data.copyWith(statusBuzzer: nextState);
    _buzzerActive = nextState == 1;
    _mqttService.publish('pharma/control/device_1', '{"actuator":"buzzer","state":$nextState}');
    _mqttService.publish('pharma/control/buzzer', '{"device_id":"device_1","state":$nextState}');
    notifyListeners();
    return true;
  }

  // Device 1 Actuator 3: Mini Water Pump
  // Pompa air Device 1 untuk menurunkan kelembapan/mendinginkan ruang.
  bool togglePompa() {
    if (!_isOperator) return false;
    final nextState = _device1Data.statusPompa == 1 ? 0 : 1;
    _device1Data = _device1Data.copyWith(statusPompa: nextState);
    _mqttService.publish('pharma/control/device_1', '{"actuator":"pump","state":$nextState}');
    _mqttService.publish('pharma/control/pump', '{"device_id":"device_1","state":$nextState}');
    notifyListeners();
    return true;
  }

  // Device 1 Actuator 4: Smart Auto Climate Control
  bool _isAutoClimate = true;
  bool get isAutoClimate => _isAutoClimate;

  // Mode otomatis Device 1: firmware mengatur kipas sendiri berdasarkan suhu.
  // Saat mode ini aktif, tombol kipas manual sebaiknya tidak dipakai.
  bool toggleAutoClimate() {
    if (!_isOperator) return false;
    _isAutoClimate = !_isAutoClimate;
    _mqttService.publish(
      'pharma/control/device_1',
      '{"actuator":"auto_climate","state":${_isAutoClimate ? 1 : 0}}',
    );
    notifyListeners();
    return true;
  }

  // Device 2 Actuator 1: Lampu UV Sterilisasi (Dengan Human Interlock Protection)
  // Lampu UV-C Device 2 dengan pengaman manusia.
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
    _device1Data = _device1Data.copyWith(statusUv: nextState);
    _mqttService.publish('pharma/control/device_2', '{"actuator":"uv","state":$nextState}');
    _mqttService.publish('pharma/control/uv', '{"device_id":"device_2","state":$nextState}');
    notifyListeners();
    return true;
  }

  // Device 2 Actuator 2: LED Indikator Ruangan Aman/Bahaya
  // LED indikator ruangan (hijau aman / merah bahaya) pada Device 2.
  bool toggleLed() {
    if (!_isOperator) return false;
    final nextState = _device2Data.statusLed == 1 ? 0 : 1;
    _device2Data = _device2Data.copyWith(statusLed: nextState);
    _mqttService.publish('pharma/control/device_2', '{"actuator":"led","state":$nextState}');
    _mqttService.publish('pharma/control/led', '{"device_id":"device_2","state":$nextState}');
    notifyListeners();
    return true;
  }

  // Memuat ambang batas tersimpan; nilai default dari StorageService dipakai
  // bila pengguna belum pernah mengubahnya.
  Future<void> _initThresholds() async {
    final thresholds = await _storageService.getThresholds();
    _tempMin = thresholds['tempMin'] ?? StorageService.defaultTempMin;
    _tempMax = thresholds['tempMax'] ?? StorageService.defaultTempMax;
    _humidityMin = thresholds['humidityMin'] ?? StorageService.defaultHumidityMin;
    _humidityMax = thresholds['humidityMax'] ?? StorageService.defaultHumidityMax;
    _gasMax = thresholds['gasMax'] ?? StorageService.defaultGasMax;
  }

  // Mengisi data awal dari REST agar dashboard langsung berisi angka terakhir
  // sebelum MQTT mengalir.
  // Dokumentasi: Mencari entri terakhir untuk masing-masing device (device_1 dan device_2)
  // dari riwayat telemetri API agar kedua tab langsung sinkron saat cold start.
  Future<void> _fetchInitialApiData() async {
    try {
      final history = await _apiService.fetchSensorHistory();
      if (history.isNotEmpty) {
        // Cari data terbaru untuk device_1 (atau fallback ke history pertama)
        final dev1Entry = history.firstWhere(
          (h) => h.deviceId == 'device_1',
          orElse: () => history.first,
        );
        _device1Data = dev1Entry.copyWith(deviceId: 'device_1');
        _buzzerActive = _device1Data.isBuzzerAktif;

        // Cari data terbaru untuk device_2 jika ada di history
        final dev2Matches = history.where((h) => h.deviceId == 'device_2');
        if (dev2Matches.isNotEmpty) {
          _device2Data = dev2Matches.first;
        } else {
          // Jika backend belum memiliki log eksplisit device_2, sinkronkan waktu & parameter ruangan
          _device2Data = _device2Data.copyWith(
            waktu: history.first.waktu,
          );
        }
        notifyListeners();
      }
    } catch (_) {
    } finally {
      if (_isInitialLoading) {
        _isInitialLoading = false;
        notifyListeners();
      }
    }
  }

  // Menghubungkan callback MQTT ke state dan memasang batas waktu tampilan
  // loading (3 detik) supaya layar tidak terus menampilkan skeleton saat broker
  // tidak tersedia.
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
        _buzzerActive = data.isBuzzerAktif;
        // Getaran singkat saat sirine berbunyi: pengguna sering tidak melihat layar
        // ketika alarm terjadi.
        if (data.isBuzzerAktif) {
          try {
            HapticFeedback.vibrate();
          } catch (_) {}
        }
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

  // Menerjemahkan nilai sensor menjadi notifikasi yang bisa dibaca pengguna.
  void _checkAndAddNotifications(SensorModel data) {
    final double minT = _tempMin;
    final double maxT = _tempMax;

    if (data.deviceId == 'device_1') {
      if (data.isBuzzerAktif) {
        _addNotificationOnce(
          id: 'buzzer_alert',
          title: 'Sirine Alarm Aktif',
          message: 'Alarm sirine darurat berbunyi di Rak Penyimpanan Vaksin!',
          isCritical: true,
        );
      } else {
        _lastNotificationTime.remove('buzzer_alert');
      }
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

  // Menambahkan notifikasi dengan cooldown 5 menit per id. Tanpa cooldown,
  // sensor yang bertahan di luar ambang akan membanjiri daftar notifikasi.
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

  // Menyisipkan notifikasi terbaru di atas dan membatasi daftar 20 entri agar
  // memori tetap kecil.
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

  // Menyimpan ambang baru lalu langsung dipakai untuk evaluasi berikutnya.
  // Tidak memerlukan restart aplikasi.
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

  // Mengosongkan daftar notifikasi pengguna.
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  bool _isReconnecting = false;
  bool get isReconnecting => _isReconnecting;

  // Menghubungkan ulang secara manual.
  Future<void> reconnect() async {
    if (_isReconnecting) return;
    _isReconnecting = true;
    _device1Data = _device1Data.copyWith(status: 'Menghubungkan Ulang...');
    _device2Data = _device2Data.copyWith(status: 'Menghubungkan Ulang...');
    notifyListeners();

    final timer = Timer(const Duration(seconds: 4), () {
      if (_isReconnecting) {
        _isReconnecting = false;
        _isInitialLoading = false;
        notifyListeners();
      }
    });

    try {
      await Future.wait([
        _fetchInitialApiData(),
        _mqttService.connect(),
      ]).timeout(const Duration(seconds: 4));
    } catch (_) {
    } finally {
      timer.cancel();
      _isReconnecting = false;
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  @override
  // Menutup koneksi MQTT saat provider dibuang agar tidak ada socket menggantung.
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }
}
