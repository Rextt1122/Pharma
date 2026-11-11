#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

#define WIFI_SSID "Wokwi-GUEST"
#define WIFI_PASSWORD ""

// Sambungkan ke Broker Cloud VPS kita
#define MQTT_SERVER "api.pharma.web.id"
#define MQTT_PORT 1883

#define DHT_PIN 15
#define DHT_TYPE DHT22
#define MQ2_PIN 1
#define LDR_PIN 2
#define BUZZER_PIN 16
#define RELAY_KIPAS_PIN 17

#define BATAS_SUHU_MAKS 8.0   // Standar Vaksin 2.0 - 8.0 C
#define BATAS_GAS_PPM 50.0

const char* TOPIK_TELEMETRI = "pharma/sensor";
const char* TOPIK_CONTROL_D1 = "pharma/control/device_1";

WiFiClient espClient;
PubSubClient mqtt(espClient);
DHT dht(DHT_PIN, DHT_TYPE);

float suhu = 4.5;
float kelembapan = 48.0;
float kadarGas = 12.0;
float nilaiLDR = 160.0;

int statusKipas = 0;
int statusBuzzer = 0;
int statusPompa = 0;
bool modeAuto = true;

unsigned long waktuKirimTerakhir = 0;

void aturBuzzer(int aktif) {
  statusBuzzer = aktif;
  if (aktif == 1) {
    tone(BUZZER_PIN, 2000);
  } else {
    noTone(BUZZER_PIN);
  }
}

void aturKipas(int aktif) {
  statusKipas = aktif;
  digitalWrite(RELAY_KIPAS_PIN, aktif ? HIGH : LOW);
}

// Callback menerima perintah JSON dari Mobile / Web Dashboard
void callbackMQTT(char* topic, byte* payload, unsigned int length) {
  StaticJsonDocument<256> doc;
  deserializeJson(doc, payload, length);

  const char* actuator = doc["actuator"]; // fan, buzzer, pump, auto_climate
  int state = doc["state"];

  if (doc.containsKey("actuator")) {
    if (strcmp(actuator, "fan") == 0) {
      modeAuto = false;
      aturKipas(state);
      Serial.printf("[AKTUATOR] Kipas diubah ke: %s\n", state ? "ON" : "OFF");
    } else if (strcmp(actuator, "buzzer") == 0) {
      aturBuzzer(state);
      Serial.printf("[AKTUATOR] Sirine diubah ke: %s\n", state ? "ON" : "OFF");
    } else if (strcmp(actuator, "pump") == 0) {
      statusPompa = state;
      Serial.printf("[AKTUATOR] Pompa diubah ke: %s\n", state ? "ON" : "OFF");
    } else if (strcmp(actuator, "auto_climate") == 0) {
      modeAuto = (state == 1);
      Serial.printf("[AKTUATOR] Auto Climate: %s\n", modeAuto ? "AKTIF" : "MANUAL");
    }
  }
}

void tungguWiFi() {
  Serial.println("[WIFI] Menghubungkan ke Wokwi-GUEST...");
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 25) {
    delay(500);
    Serial.print(".");
    retry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WIFI] Berhasil Terhubung!");
    Serial.print("[WIFI] IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[WIFI] Timeout, tetap lanjut ke sensor...");
  }
}

void koneksiMQTT() {
  if (mqtt.connected() || WiFi.status() != WL_CONNECTED) return;
  static unsigned long lastTry = 0;
  if (millis() - lastTry < 3000) return;
  lastTry = millis();

  String clientID = "ESP32_D1_" + String(random(0xffff), HEX);
  Serial.print("[MQTT] Menghubungkan ke broker: ");
  Serial.println(MQTT_SERVER);

  if (mqtt.connect(clientID.c_str())) {
    Serial.println("[MQTT] Berhasil Terhubung ke Broker Cloud!");
    mqtt.subscribe(TOPIK_CONTROL_D1);
    Serial.println("[MQTT] Subscribe kontrol: pharma/control/device_1");
  } else {
    Serial.print("[MQTT] Gagal konek, state: ");
    Serial.println(mqtt.state());
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000); // Jeda wajib agar Serial Monitor Wokwi siap menangkap teks boot

  Serial.println("\n========================================");
  Serial.println(" SMART PHARMA - NODE 1 (ESP32-S3)");
  Serial.println("========================================");

  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RELAY_KIPAS_PIN, OUTPUT);
  pinMode(MQ2_PIN, INPUT);
  pinMode(LDR_PIN, INPUT);
  aturBuzzer(0);
  aturKipas(0);

  dht.begin();
  tungguWiFi();

  mqtt.setServer(MQTT_SERVER, MQTT_PORT);
  mqtt.setCallback(callbackMQTT);
  mqtt.setBufferSize(512);

  Serial.println("[SISTEM] Device 1 Siap & Berjalan!\n");
}

void loop() {
  if (!mqtt.connected()) {
    koneksiMQTT();
  }
  mqtt.loop();

  // Kirim data setiap 2.5 detik
  if (millis() - waktuKirimTerakhir >= 2500) {
    waktuKirimTerakhir = millis();

    float t = dht.readTemperature();
    float h = dht.readHumidity();
    if (!isnan(t)) suhu = t;
    if (!isnan(h)) kelembapan = h;

    kadarGas = analogRead(MQ2_PIN) * (100.0 / 4095.0);
    nilaiLDR = analogRead(LDR_PIN) * (500.0 / 4095.0);

    // Kontrol Otomatis Pendingin Vaksin (Auto Climate)
    if (modeAuto) {
      if (suhu > BATAS_SUHU_MAKS) {
        aturKipas(1);
        statusPompa = 1;
      } else if (suhu <= 7.0) {
        aturKipas(0);
        statusPompa = 0;
      }
    }

    // Log ke Serial Monitor Wokwi
    Serial.printf("[SENSOR] Suhu: %.1f C | RH: %.0f %% | Gas: %.1f PPM | Lux: %.0f | Kipas: %d | Pompa: %d | Sirine: %d\n",
                  suhu, kelembapan, kadarGas, nilaiLDR, statusKipas, statusPompa, statusBuzzer);

    // Format JSON standar yang langsung dibaca oleh Backend FastAPI & HP
    StaticJsonDocument<300> doc;
    doc["device_id"] = "device_1";
    doc["suhu"] = suhu;
    doc["kelembapan"] = kelembapan;
    doc["kadar_gas"] = kadarGas;
    doc["cahaya"] = nilaiLDR;
    doc["status_kipas"] = statusKipas;
    doc["status_buzzer"] = statusBuzzer;
    doc["status_pompa"] = statusPompa;
    doc["status_pintu"] = 0;
    doc["status_uv"] = 0;

    char buffer[300];
    serializeJson(doc, buffer);
    if (mqtt.connected()) {
      mqtt.publish(TOPIK_TELEMETRI, buffer);
      Serial.println("[MQTT PUB] Data berhasil terkirim ke 'pharma/sensor'");
    }
  }
}
