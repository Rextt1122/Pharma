import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_model.dart';
import 'storage_service.dart';

class MqttService {
  MqttServerClient? _client;
  Function(SensorModel)? onDataReceived;
  Function(bool)? onConnectionChanged;
  final StorageService _storageService = StorageService();

  Function(bool)? get onStatusChanged => onConnectionChanged;
  set onStatusChanged(Function(bool)? callback) => onConnectionChanged = callback;

  Future<void> connect() async {
    final clientId = 'flutter_pharma_${DateTime.now().millisecondsSinceEpoch}';
    final serverIp = await _storageService.getServerIp();
    _client = MqttServerClient.withPort(serverIp, clientId, 1883);
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 20;
    _client!.autoReconnect = true;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      _client!.disconnect();
      onConnectionChanged?.call(false);
      return;
    }

    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
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
    } else {
      _client!.disconnect();
      onConnectionChanged?.call(false);
    }
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
