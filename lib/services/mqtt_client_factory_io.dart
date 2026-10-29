import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(String serverIp, String clientId) {
  final client = MqttServerClient.withPort(serverIp, clientId, 1883);
  client.logging(on: false);
  client.keepAlivePeriod = 20;
  client.connectTimeoutPeriod = 2500;
  client.autoReconnect = true;
  return client;
}
