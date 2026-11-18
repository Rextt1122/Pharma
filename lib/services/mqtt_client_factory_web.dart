// ============================================================================
// DOKUMENTASI: mqtt_client_factory_web.dart — Klien MQTT WebSocket
//
// Membuat MqttBrowserClient (ws://host:9001) untuk Flutter Web.
// Broker Mosquitto harus mengaktifkan listener WebSocket.
//
// Dibaca sebagai referensi implementasi; komentar menjelaskan alasan, bukan mengulang nama simbol.
// ============================================================================
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

// Membuat klien MQTT-over-WebSocket untuk Flutter Web (port 9001).
//
// Browser tidak bisa membuka TCP mentah, sehingga broker harus menyediakan
// listener WebSocket. Protokol diset ke "mqtt" agar cocok dengan Mosquitto.
MqttClient createMqttClient(String serverIp, String clientId) {
  final client = MqttBrowserClient('ws://$serverIp', clientId);
  client.port = 9001;
  client.logging(on: false);
  client.keepAlivePeriod = 20;
  client.autoReconnect = true;
  client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  return client;
}
