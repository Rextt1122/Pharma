#include <Arduino.h>

#define PIR_PIN          37
#define TRIG_PIN          5
#define ECHO_PIN         18
#define DOOR_PIN         13
#define RELAY_PIN        17
#define LED_RED_PIN      42
#define LED_GREEN_PIN    41
#define LED_BLUE_PIN     40
#define UV_LED_PIN       29
#define BUZZER_PIN       20

const bool RELAY_ACTIVE_LOW = true;

const bool RGB_COMMON_ANODE = false;

const bool BUTTON_PRESSED_MEANS_OPEN = true;

const unsigned long NO_MOTION_REQUIRED = 60000UL; // 60 detik
const unsigned long DOOR_STABLE_TIME   = 1000UL;  // 1 detik
const unsigned long WARNING_DURATION   = 5000UL;  // 5 detik
const unsigned long MAX_UV_DURATION    = 300000UL; // 5 menit

const unsigned long SENSOR_INTERVAL    = 2500UL;
const unsigned long BUZZER_INTERVAL    = 300UL;
const unsigned long BLINK_INTERVAL     = 300UL;

const float STOCK_DISTANCE_LIMIT_CM = 20.0;
enum UVState {
  UV_IDLE,
  UV_WARNING,
  UV_RUNNING
};

UVState uvState = UV_IDLE;

bool uvRequested = false;
bool motionDetected = false;
bool doorOpen = false;
bool doorStableClosed = false;

unsigned long lastMotionTime = 0;
unsigned long doorClosedSince = 0;
unsigned long stateStartedAt = 0;
unsigned long lastSensorRead = 0;
unsigned long lastBuzzerToggle = 0;
unsigned long lastBlinkToggle = 0;

bool buzzerState = false;
bool blinkState = false;
float distanceCM = -1.0;
void setRGB(bool red, bool green, bool blue) {
  if (RGB_COMMON_ANODE) {
    red   = !red;
    green = !green;
    blue  = !blue;
  }
  digitalWrite(LED_RED_PIN, red ? HIGH : LOW);
  digitalWrite(LED_GREEN_PIN, green ? HIGH : LOW);
  digitalWrite(LED_BLUE_PIN, blue ? HIGH : LOW);
}
void ledSafe() {
  setRGB(false, true, false);
}
void ledDanger() {
  setRGB(true, false, false);
}
void ledUVActive() {
  setRGB(true, false, true);
}
void setRelay(bool active) {
  if (RELAY_ACTIVE_LOW) {
    digitalWrite(RELAY_PIN, active ? LOW : HIGH);
  } else {
    digitalWrite(RELAY_PIN, active ? HIGH : LOW);
  }
}
void setUV(bool active) {
  digitalWrite(UV_LED_PIN, active ? HIGH : LOW);
  setRelay(active);
}
void stopUV(const char *reason) {
  setUV(false);
  uvState = UV_IDLE;
  uvRequested = false;
  noTone(BUZZER_PIN);
  buzzerState = false;
  Serial.print("[UV OFF] ");
  Serial.println(reason);
}
void readPIR() {
  motionDetected = (digitalRead(PIR_PIN) == HIGH);
  if (motionDetected) {
    lastMotionTime = millis();
  }
}
bool noMotionLongEnough() {
  return !motionDetected &&
         (millis() - lastMotionTime >= NO_MOTION_REQUIRED);
}
void readDoor() {
  bool buttonPressed = (digitalRead(DOOR_PIN) == LOW);

  if (BUTTON_PRESSED_MEANS_OPEN) {
    doorOpen = buttonPressed;
  } else {
    doorOpen = !buttonPressed;
  }
  if (doorOpen) {
    doorStableClosed = false;
    doorClosedSince = 0;
  } else {
    if (doorClosedSince == 0) {
      doorClosedSince = millis();
    }
    doorStableClosed =
      (millis() - doorClosedSince >= DOOR_STABLE_TIME);
  }
}
float readDistanceCM() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(3);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  unsigned long duration = pulseIn(ECHO_PIN, HIGH, 30000UL);
  if (duration == 0) {
    return -1.0;
  }
  return duration * 0.0343f / 2.0f;
}
void updateDistance() {
  if (millis() - lastSensorRead < SENSOR_INTERVAL) {
    return;
  }
  lastSensorRead = millis();
  distanceCM = readDistanceCM();
  Serial.print("[STOK] Jarak: ");
  if (distanceCM < 0) {
    Serial.println("Tidak ada pembacaan");
  } else {
    Serial.print(distanceCM, 1);
    Serial.print(" cm | ");
    if (distanceCM <= STOCK_DISTANCE_LIMIT_CM) {
      Serial.println("Kardus dekat sensor / stok tinggi");
    } else {
      Serial.println("Kardus jauh dari sensor / stok rendah");
    }
  }
}
bool safetyConditionsOK() {
  return doorStableClosed && noMotionLongEnough();
}
void updateStatusLED() {
  if (doorOpen || motionDetected) {
    ledDanger();
  } else if (uvState == UV_RUNNING) {
    ledUVActive();
  } else {
    ledSafe();
  }
}
void updateSafetyAlarm() {
  if ((doorOpen || motionDetected) &&
      uvState != UV_RUNNING &&
      uvState != UV_WARNING) {
    tone(BUZZER_PIN, 2000);
  } else if (uvState == UV_IDLE) {
    noTone(BUZZER_PIN);
  }
}
void startWarning() {
  uvState = UV_WARNING;
  stateStartedAt = millis();
  lastBuzzerToggle = 0;
  lastBlinkToggle = 0;
  buzzerState = false;
  blinkState = false;
  setUV(false);
  Serial.println("[PERINGATAN] UV akan aktif dalam 5 detik.");
}
void runWarning() {
  if (!safetyConditionsOK()) {
    uvState = UV_IDLE;
    noTone(BUZZER_PIN);
    buzzerState = false;
    Serial.println(
      "[BATAL] Pintu terbuka atau gerakan terdeteksi. "
      "Menunggu kondisi aman kembali."
    );
    return;
  }
  unsigned long now = millis();
  if (now - lastBlinkToggle >= BLINK_INTERVAL) {
    lastBlinkToggle = now;
    blinkState = !blinkState;
    if (blinkState) {
      setRGB(true, false, false);
    } else {
      setRGB(false, false, false);
    }
  }
  if (now - lastBuzzerToggle >= BUZZER_INTERVAL) {
    lastBuzzerToggle = now;
    buzzerState = !buzzerState;
    if (buzzerState) {
      tone(BUZZER_PIN, 2000);
    } else {
      noTone(BUZZER_PIN);
    }
  }
  if (now - stateStartedAt >= WARNING_DURATION) {
    noTone(BUZZER_PIN);
    buzzerState = false;
    if (safetyConditionsOK()) {
      uvState = UV_RUNNING;
      stateStartedAt = millis();
      setUV(true);
      ledUVActive();
      Serial.println("[UV ON] Sterilisasi dimulai.");
      Serial.println("[INFO] Batas waktu UV: 5 menit.");
    } else {
      uvState = UV_IDLE;
      Serial.println("[BATAL] Kondisi tidak aman.");
    }
  }
}
void runUV() {
  if (doorOpen) {
    stopUV("Pintu terbuka!");
    return;
  }
  if (motionDetected) {
    stopUV("Gerakan manusia terdeteksi!");
    return;
  }
  if (millis() - stateStartedAt >= MAX_UV_DURATION) {
    stopUV("Batas 5 menit tercapai.");
    return;
  }
  setUV(true);
  ledUVActive();
}
void readSerialCommand() {
  if (!Serial.available()) {
    return;
  }
  String command = Serial.readStringUntil('\n');
  command.trim();
  command.toUpperCase();
  if (command == "UV ON") {
    if (uvState == UV_RUNNING) {
      Serial.println("[INFO] UV sudah aktif.");
      return;
    }
    uvRequested = true;
    Serial.println("[PERMINTAAN] Mode sterilisasi diterima.");
    Serial.println(
      "[INFO] Menunggu pintu tertutup dan tidak ada "
      "gerakan selama 60 detik."
    );
  }
  else if (command == "UV OFF") {
    stopUV("Perintah manual dari Serial Monitor.");
  }
  else if (command == "STATUS") {
    Serial.print("Pintu: ");
    Serial.println(doorOpen ? "TERBUKA" : "TERTUTUP");
    Serial.print("PIR: ");
    Serial.println(motionDetected ? "GERAKAN" : "TIDAK ADA GERAKAN");
    Serial.print("Kondisi aman: ");
    Serial.println(safetyConditionsOK() ? "YA" : "BELUM");
    Serial.print("Status UV: ");
    if (uvState == UV_RUNNING) {
      Serial.println("AKTIF");
    } else if (uvState == UV_WARNING) {
      Serial.println("PERINGATAN");
    } else {
      Serial.println("MATI");
    }

    Serial.print("Jarak stok: ");
    Serial.print(distanceCM);
    Serial.println(" cm");
  }
  else {
    Serial.println("Perintah tidak dikenal.");
    Serial.println("Gunakan: UV ON, UV OFF, atau STATUS");
  }
}
void setup() {
  Serial.begin(115200);
  pinMode(PIR_PIN, INPUT);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(DOOR_PIN, INPUT_PULLUP);
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(LED_RED_PIN, OUTPUT);
  pinMode(LED_GREEN_PIN, OUTPUT);
  pinMode(LED_BLUE_PIN, OUTPUT);
  pinMode(UV_LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  setUV(false);
  setRGB(false, false, false);
  noTone(BUZZER_PIN);
  unsigned long now = millis();
  lastMotionTime = now;
  doorClosedSince = 0;
  Serial.println();
  Serial.println("====================================");
  Serial.println(" DEVICE 2 - STERILISASI UV");
  Serial.println(" ESP32-S3");
  Serial.println("====================================");
  Serial.println("Perintah Serial:");
  Serial.println("  UV ON  = minta sterilisasi");
  Serial.println("  UV OFF = matikan / batalkan");
  Serial.println("  STATUS = tampilkan status");
  Serial.println();
  Serial.println(
    "UV hanya aktif setelah pintu tertutup stabil "
    "dan tidak ada gerakan selama 60 detik."
  );
  Serial.println("Baik pintu maupun PIR dapat membatalkan UV.");
}
void loop() {
  readSerialCommand();
  readPIR();
  readDoor();
  updateDistance();
  if (uvState == UV_RUNNING) {
    runUV();
  }
  else if (uvState == UV_WARNING) {
    runWarning();
  }
  else {
    setUV(false);
    updateStatusLED();
    updateSafetyAlarm();
    if (uvRequested && safetyConditionsOK()) {
      startWarning();
    }
  }
}