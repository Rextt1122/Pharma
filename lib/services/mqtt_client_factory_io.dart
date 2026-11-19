// mqtt_client_factory_io.dart — Klien MQTT TCP
// MqttServerClient port 1883 untuk Android/desktop.
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// Membuat klien MQTT native (Android/desktop) ke port 1883.
MqttClient createMqttClient(String serverIp, String clientId) {
  final client = MqttServerClient.withPort(serverIp, clientId, 1883);
  client.logging(on: false);
  client.keepAlivePeriod = 20;
  client.connectTimeoutPeriod = 2500;
  client.autoReconnect = true;
  return client;
}
