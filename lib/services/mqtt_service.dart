// ============================================================================
// DOKUMENTASI KODE: mqtt_service.dart — Koneksi MQTT, subscribe telemetri, dan publish kontrol
// Dibaca sebagai referensi implementasi; komentar hanya menjelaskan alur penting.
// ============================================================================
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import '../models/sensor_model.dart';
import 'api_service.dart';
import 'mqtt_client_factory_io.dart'
    if (dart.library.js_interop) 'mqtt_client_factory_web.dart'
    if (dart.library.html) 'mqtt_client_factory_web.dart';
import 'storage_service.dart';

// Mengelola koneksi broker, aliran telemetri, dan publish perintah aktuator.
// Satu koneksi MQTT untuk seluruh aplikasi.
//
// Tanggung jawab: memilih host broker yang hidup, berlangganan topik telemetri,
// mengubah payload JSON menjadi SensorModel, dan mengirim perintah aktuator.
// Callback onDataReceived/onConnectionChanged disediakan agar provider tidak
// perlu mengetahui detail protokol.
class MqttService {
  MqttClient? _client;
  Function(SensorModel)? onDataReceived;
  Function(bool)? onConnectionChanged;
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  Function(bool)? get onStatusChanged => onConnectionChanged;
  set onStatusChanged(Function(bool)? callback) => onConnectionChanged = callback;

  // Mencoba kandidat broker satu per satu hingga berhasil.
  //
  // Urutan kandidat: cloud (api.pharma.web.id), host hasil resolve REST, host
  // tersimpan, lalu beberapa IP lokal/Docker yang biasa dipakai saat demo.
  //
  // Timeout 2,5 detik per host: cukup untuk jaringan lokal, cukup singkat agar
  // tidak membuat splash screen menggantung saat host mati. Host yang berhasil
  // disimpan ke SharedPreferences sehingga percobaan berikutnya lebih cepat.
  Future<void> connect() async {
    final savedIp = await _storageService.getServerIp();
    final reachableIp = await _apiService.resolveReachableIp();
    final candidates = <String>{
      'api.pharma.web.id',
      '172.197.249.136',
      if (reachableIp.isNotEmpty) reachableIp,
      if (savedIp.isNotEmpty) savedIp,
      '127.0.0.1',
      '192.168.253.238',
      '192.168.1.25',
      '192.168.33.10',
      '192.168.1.21',
      '192.168.137.1',
      '192.168.33.12',
    }.where((ip) => ip.isNotEmpty && ip != '192.168.1.100').toList();

    for (final serverIp in candidates) {
      final clientId = 'flutter_pharma_${DateTime.now().millisecondsSinceEpoch}';
      _client = createMqttClient(serverIp, clientId);

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      try {
        await _client!.connect().timeout(const Duration(milliseconds: 2500));
      } catch (e) {
        try {
          _client!.disconnect();
        } catch (_) {}
        continue;
      }

      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        await _storageService.saveServerIp(serverIp);
        onConnectionChanged?.call(true);
        // Empat topik didukung untuk kompatibilitas: skema lama (pharma/sensor,
        // greenhouse/sensor) dan skema per-device (pharma/device1|device2/sensor).
        // QoS 0 dipilih karena telemetri dikirim periodik; paket hilang akan digantikan
        // pembacaan berikutnya dan latensi lebih penting daripada jaminan kirim.
        _client!.subscribe('pharma/sensor', MqttQos.atMostOnce);
        _client!.subscribe('greenhouse/sensor', MqttQos.atMostOnce);
        _client!.subscribe('pharma/device1/sensor', MqttQos.atMostOnce);
        _client!.subscribe('pharma/device2/sensor', MqttQos.atMostOnce);

        _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
          final recMess = messages[0].payload as MqttPublishMessage;
          final topic = messages[0].topic;
          final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          try {
            final jsonMap = jsonDecode(payload) as Map<String, dynamic>;
            // device_id ditentukan dari nama topik lebih dulu, lalu dari field payload.
            // Payload lama tidak selalu menyertakan device_id, sehingga topik menjadi
            // sumber kebenaran.
            String inferredDeviceId = 'device_1';
            if (topic.contains('device2') || jsonMap['device_id'] == 'device_2' || jsonMap['device_id'] == '2') {
              inferredDeviceId = 'device_2';
            }
            // Payload rusak diabaikan diam-diam: satu pesan cacat tidak boleh mematikan
            // aliran telemetri.
            final sensorModel = SensorModel.fromJson(jsonMap, defaultDeviceId: inferredDeviceId);
            onDataReceived?.call(sensorModel);
          } catch (_) {}
        });
        return;
      } else {
        _client!.disconnect();
      }
    }

    onConnectionChanged?.call(false);
  }

  // Mengirim perintah aktuator dalam bentuk JSON.
  //
  // Tidak melempar error bila broker terputus; pemanggil (provider) yang
  // bertanggung jawab memberi tahu pengguna. QoS 0 dipakai karena perintah
  // kontrol dikirim ulang oleh pengguna bila tidak bereaksi.
  void publish(String topic, String message) {
    if (_client != null && _client!.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    }
  }

  // Menutup koneksi dan memberi sinyal ke UI bahwa status menjadi offline.
  void disconnect() {
    _client?.disconnect();
    onConnectionChanged?.call(false);
  }
}
