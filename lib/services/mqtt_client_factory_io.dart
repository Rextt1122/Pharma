// ============================================================================
// DOKUMENTASI: mqtt_client_factory_io.dart — Klien MQTT native
//
// Membuat MqttServerClient (TCP 1883) untuk Android dan desktop.
// Versi web ada di mqtt_client_factory_web.dart (WebSocket 9001).
//
// Dibaca sebagai referensi implementasi; komentar menjelaskan alasan, bukan mengulang nama simbol.
// ============================================================================
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// Membuat klien MQTT native (Android/desktop) ke port 1883.
//
// keepAlive 20 detik cukup agresif agar status koneksi cepat terdeteksi, tapi
// tetap ringan untuk broker Mosquitto. autoReconnect menangani putus jaringan
// singkat tanpa campur tangan UI.
MqttClient createMqttClient(String serverIp, String clientId) {
  final client = MqttServerClient.withPort(serverIp, clientId, 1883);
  client.logging(on: false);
  client.keepAlivePeriod = 20;
  client.connectTimeoutPeriod = 2500;
  client.autoReconnect = true;
  return client;
}
