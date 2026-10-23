import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import '../models/sensor_model.dart';
import 'mqtt_client_factory_io.dart'
    if (dart.library.js_interop) 'mqtt_client_factory_web.dart'
    if (dart.library.html) 'mqtt_client_factory_web.dart';
import 'storage_service.dart';

class MqttService {
  MqttClient? _client;
  Function(SensorModel)? onDataReceived;
  Function(bool)? onConnectionChanged;
  final StorageService _storageService = StorageService();

  Function(bool)? get onStatusChanged => onConnectionChanged;
  set onStatusChanged(Function(bool)? callback) => onConnectionChanged = callback;

  Future<void> connect() async {
    final savedIp = await _storageService.getServerIp();
    final candidates = <String>{
      savedIp,
      '192.168.33.10',
      '127.0.0.1',
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
        await _client!.connect();
      } catch (e) {
        _client!.disconnect();
        continue;
      }

      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        if (serverIp != savedIp) {
          await _storageService.saveServerIp(serverIp);
        }
        onConnectionChanged?.call(true);
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
            String inferredDeviceId = 'device_1';
            if (topic.contains('device2') || jsonMap['device_id'] == 'device_2' || jsonMap['device_id'] == '2') {
              inferredDeviceId = 'device_2';
            }
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

  void publish(String topic, String message) {
    if (_client != null && _client!.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    }
  }

  void disconnect() {
    _client?.disconnect();
    onConnectionChanged?.call(false);
  }
}
