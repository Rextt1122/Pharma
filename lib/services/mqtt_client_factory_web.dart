// mqtt_client_factory_web.dart — Klien MQTT WebSocket
// MqttBrowserClient port 9001 untuk Flutter Web.
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

// Membuat klien MQTT-over-WebSocket untuk Flutter Web (port 9001).
MqttClient createMqttClient(String serverIp, String clientId) {
  final client = MqttBrowserClient('ws://$serverIp', clientId);
  client.port = 9001;
  client.logging(on: false);
  client.keepAlivePeriod = 20;
  client.autoReconnect = true;
  client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  return client;
}
