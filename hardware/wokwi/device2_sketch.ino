#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

#define WIFI_SSID "Wokwi-GUEST"
#define WIFI_PASSWORD ""

// Broker Cloud VPS Azure
#define MQTT_SERVER "api.pharma.web.id"
#define MQTT_PORT 1883

// Pinout Hardware ESP32-S3 Wokwi Device 2
#define PIR_PIN 37
#define TRIG_PIN 5
#define ECHO_PIN 18
#define BUTTON_DOOR_PIN 13 // Reed Switch / Saklar Pintu Magnetik

#define RELAY_UV_PIN 17
#define BUZZER_PIN 20

#define LED_RED_PIN 42
#define LED_GREEN_PIN 41
#define LED_BLUE_PIN 40
#define LED_UV_PIN 39

#define RELAY_ACTIVE_LOW true
#define RGB_COMMON_ANODE true

const char* TOPIK_TELEMETRI = "pharma/sensor";
const char* TOPIK_CONTROL_D2 = "pharma/control/device_2";
const char* TOPIK_CONTROL_UV = "pharma/control/uv";

WiFiClient espClient;
PubSubClient mqtt(espClient);

// State Hardware Device 2
int statusPintu = 0;       // 0 = Terkunci (Aman), 1 = Terbuka
int deteksiGerak = 0;      // 0 = Ruangan Kosong, 1 = Ada Manusia (PIR)
int statusUV = 0;          // 0 = Siaga (Off), 1 = Sterilisasi UV Aktif (On)
int statusLED = 0;         // 0 = Hijau (Aman Masuk), 1 = Merah (Bahaya Akses)
float jarakStok = 22.0;    // Kapasitas tumpukan kardus obat (cm)

unsigned long waktuKirimTerakhir = 0;
unsigned long waktuBacaSensor = 0;

void aturRGB(bool merah, bool hijau, bool biru) {
  digitalWrite(LED_RED_PIN, RGB_COMMON_ANODE ? !merah : merah);
  digitalWrite(LED_GREEN_PIN, RGB_COMMON_ANODE ? !hijau : hijau);
  digitalWrite(LED_BLUE_PIN, RGB_COMMON_ANODE ? !biru : biru);
}

void aturRelayUV(int aktif) {
  statusUV = aktif;
  if (RELAY_ACTIVE_LOW) {
    digitalWrite(RELAY_UV_PIN, aktif ? LOW : HIGH);
  } else {
    digitalWrite(RELAY_UV_PIN, aktif ? HIGH : LOW);
  }
  digitalWrite(LED_UV_PIN, aktif ? HIGH : LOW);

  // Jika UV aktif, LED luar ruangan merah (bahaya masuk)
  if (aktif == 1) {
    statusLED = 1;
    aturRGB(true, false, false);
  }
}

void aturBuzzer(int aktif) {
  if (aktif == 1) {
    tone(BUZZER_PIN, 2000);
  } else {
    noTone(BUZZER_PIN);
  }
}

float ukurJarakUltrasonik() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  unsigned long durasi = pulseIn(ECHO_PIN, HIGH, 30000);
  if (durasi == 0) return 22.0;
  float jarak = durasi * 0.0343 / 2.0;
  if (jarak < 2.0 || jarak > 400.0) return 22.0;
  return jarak;
}

// Callback menerima perintah dari Flutter Mobile / Web Dashboard
void callbackMQTT(char* topic, byte* payload, unsigned int length) {
  StaticJsonDocument<256> doc;
  deserializeJson(doc, payload, length);

  int state = doc.containsKey("state") ? doc["state"].as<int>() : 0;
  const char* actuator = doc["actuator"] | "uv";

  // Perintah menyalakan / mematikan Sinar UV-C
  if (strcmp(actuator, "uv") == 0 || String(topic).endsWith("uv")) {
    if (state == 1) {
      // SAFETY INTERLOCK: Dilarang menyalakan UV jika ada orang atau pintu terbuka!
      if (deteksiGerak == 1 || statusPintu == 1) {
        Serial.println("\n[SAFETY INTERLOCK] UV DITOLAK: Pintu terbuka atau ada orang di ruangan!");
        aturRelayUV(0);
        aturBuzzer(1);
        delay(300);
        aturBuzzer(0);
      } else {
        Serial.println("\n[AKTUATOR] Sterilisasi Sinar UV-C DIHIDUPKAN!");
        aturRelayUV(1);
      }
    } else {
      Serial.println("\n[AKTUATOR] Lampu UV-C DIMATIKAN.");
      aturRelayUV(0);
    }
  } else if (strcmp(actuator, "led") == 0) {
    statusLED = state;
    aturRGB(state == 1, state == 0, false);
  }
}

void tungguWiFi() {
  Serial.println("[WIFI] Menghubungkan ke Wokwi-GUEST...");
  WiFi.mode(WIFI_STA);
  // Channel 6 agar langsung lock ke AP virtual Wokwi tanpa scan lama
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD, 6);

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 60) {
    delay(150);
    Serial.print(".");
    retry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WIFI] Berhasil Terhubung ke Wokwi-GUEST!");
    Serial.print("[WIFI] IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[WIFI] Timeout, tetap lanjut membaca sensor...");
  }
}

void koneksiMQTT() {
  if (mqtt.connected() || WiFi.status() != WL_CONNECTED) return;
  static unsigned long lastTry = 0;
  if (millis() - lastTry < 3000) return;
  lastTry = millis();

  String clientID = "ESP32_D2_" + String(random(0xffff), HEX);
  Serial.print("[MQTT] Menghubungkan ke broker: ");
  Serial.println(MQTT_SERVER);

  if (mqtt.connect(clientID.c_str())) {
    Serial.println("[MQTT] Berhasil Terhubung ke Broker Cloud!");
    mqtt.subscribe(TOPIK_CONTROL_D2);
    mqtt.subscribe(TOPIK_CONTROL_UV);
    Serial.println("[MQTT] Mendengarkan perintah di 'pharma/control/device_2'");
  } else {
    Serial.print("[MQTT] Gagal konek, state: ");
    Serial.println(mqtt.state());
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000); // Jeda wajib agar Serial Monitor Wokwi siap menangkap teks boot

  Serial.println("\n========================================");
  Serial.println(" SMART PHARMA - NODE 2 (ESP32-S3)");
  Serial.println(" STERILISASI UV & KEAMANAN RUANGAN");
  Serial.println("========================================");

  pinMode(PIR_PIN, INPUT);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(BUTTON_DOOR_PIN, INPUT_PULLUP);

  pinMode(RELAY_UV_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_RED_PIN, OUTPUT);
  pinMode(LED_GREEN_PIN, OUTPUT);
  pinMode(LED_BLUE_PIN, OUTPUT);
  pinMode(LED_UV_PIN, OUTPUT);

  aturRelayUV(0);
  aturBuzzer(0);
  aturRGB(false, true, false); // Hijau = Awal aman

  tungguWiFi();

  mqtt.setServer(MQTT_SERVER, MQTT_PORT);
  mqtt.setCallback(callbackMQTT);
  mqtt.setBufferSize(512);

  Serial.println("[SISTEM] Device 2 Siap & Berjalan!\n");
}

void loop() {
  if (!mqtt.connected()) {
    koneksiMQTT();
  }
  mqtt.loop();

  // 1. Baca Sensor Setiap 250ms
  if (millis() - waktuBacaSensor >= 250) {
    waktuBacaSensor = millis();

    // PIR Sensor: HIGH = Ada gerakan
    deteksiGerak = (digitalRead(PIR_PIN) == HIGH) ? 1 : 0;

    // Tombol / Reed Switch Pintu: LOW = Tombol ditekan / Pintu Terbuka
    statusPintu = (digitalRead(BUTTON_DOOR_PIN) == LOW) ? 1 : 0;

    // Ultrasonik Stok Obat
    jarakStok = ukurJarakUltrasonik();

    // 2. EMERGENCY INTERLOCK SHUTDOWN
    // Jika UV sedang menyala dan tiba-tiba ada orang masuk atau pintu dibuka:
    if (statusUV == 1 && (deteksiGerak == 1 || statusPintu == 1)) {
      Serial.println("\n[EMERGENCY SHUTDOWN] UV DIMATIKAN OTOMATIS: Personil Masuk / Pintu Dibuka!");
      aturRelayUV(0);
      aturBuzzer(1);
      delay(200);
      aturBuzzer(0);
    }

    // 3. Status Lampu Indikator RGB Luar Ruangan
    if (statusUV == 1) {
      statusLED = 1;
      aturRGB(true, false, false);  // Merah: UV Aktif (Dilarang Masuk)
    } else if (statusPintu == 1 || deteksiGerak == 1) {
      statusLED = 1;
      aturRGB(true, false, false);  // Merah: Pintu Terbuka / Ada Aktivitas
    } else {
      statusLED = 0;
      aturRGB(false, true, false);  // Hijau: Ruangan Aman & Steril
    }
  }

  // 4. Kirim Data Telemetri ke Cloud Setiap 2.5 Detik
  if (millis() - waktuKirimTerakhir >= 2500) {
    waktuKirimTerakhir = millis();

    // Log ke Serial Monitor Wokwi
    Serial.printf("[SENSOR D2] Pintu: %s | PIR: %s | UV: %s | Stok: %.0f cm | LED: %s\n",
                  statusPintu ? "TERBUKA" : "TERKUNCI",
                  deteksiGerak ? "ADA ORANG" : "KOSONG",
                  statusUV ? "ON (STERIL)" : "OFF",
                  jarakStok,
                  statusLED ? "MERAH" : "HIJAU");

    // Format JSON standar yang langsung sinkron dengan Mobile & Web
    StaticJsonDocument<300> doc;
    doc["device_id"] = "device_2";
    doc["suhu"] = 20.0;
    doc["kelembapan"] = 50.0;
    doc["kadar_gas"] = 8.5;
    doc["status_pintu"] = statusPintu;
    doc["deteksi_gerak"] = deteksiGerak;
    doc["status_uv"] = statusUV;
    doc["jarak_stok"] = jarakStok;
    doc["status_led"] = statusLED;

    char buffer[300];
    serializeJson(doc, buffer);
    if (mqtt.connected()) {
      mqtt.publish(TOPIK_TELEMETRI, buffer);
      Serial.println("[MQTT PUB] Data Device 2 terkirim ke 'pharma/sensor'");
    }
  }
}
