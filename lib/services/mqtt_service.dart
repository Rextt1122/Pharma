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

      _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final recMess = messages[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        try {
          final jsonMap = jsonDecode(payload) as Map<String, dynamic>;
          final sensorModel = SensorModel.fromJson(jsonMap);
          onDataReceived?.call(sensorModel);
        } catch (_) {}
      });
    } else {
      _client!.disconnect();
      onConnectionChanged?.call(false);
    }
  }

  void disconnect() {
    _client?.disconnect();
    onConnectionChanged?.call(false);
  }
}
