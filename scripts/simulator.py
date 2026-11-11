"""
SIMULATOR PERANGKAT IOT ESP32-S3 (PHARMA MEDIC)
================================================
Mensimulasikan data telemetri dari 2 Node ESP32-S3 ke Broker Mosquitto MQTT:
- Node 1 (ESP32-S3): DHT22 (Suhu & Kelembapan), MQ-2 (Gas/Asap), Kipas, Buzzer.
- Node 2 (ESP32-S3): Reed Switch (Pintu), PIR (Gerak), HC-SR04 (Stok), Relay UV-C.

Juga merespons perintah kontrol dari tombol aplikasi Flutter (Aktuator UV & Buzzer).

Cara Menjalankan:
  uv run --with paho-mqtt python scripts/simulator.py
  atau:
  python scripts/simulator.py (jika paho-mqtt sudah terinstall)
"""

import sys
import json
import time
import random
import datetime
import threading

try:
    import paho.mqtt.client as mqtt
except ImportError:
    print("[ERROR] Library 'paho-mqtt' belum terinstall.")
    print("Jalankan dengan perintah: uv run --with paho-mqtt python scripts/simulator.py")
    sys.exit(1)

# ---------- KONFIGURASI BROKER ----------
BROKER_CANDIDATES = [
    "127.0.0.1",       # Local host / VPS localhost
    "mqtt.pharma.web.id",
    "api.pharma.web.id",
    "192.168.1.25",    # IP Wi-Fi Laptop
    "192.168.33.10",   # IP VM Debian
    "192.168.33.12",
]
PORT = 1883

TOPIC_SENSOR = "pharma/sensor"
TOPIC_CONTROL_ALL = "pharma/control/#"

# ---------- STATE SIMULASI HARDWARE ----------
# Node 1: Rak Penyimpanan (Cold Chain Vaksin 2-8°C)
state_node1 = {
    "device_id": "device_1",
    "suhu": 4.5,            # Rentang aman vaksin: 2.0 - 8.0 °C
    "kelembapan": 50.0,     # Standar: 45 - 60 %
    "kadar_gas": 12.0,      # MQ-2 bersih: < 20 PPM
    "cahaya": 120.0,
    "status_kipas": 0,
    "status_buzzer": 0,
}

# Node 2: Keamanan & Sterilisasi Sinar UV-C
state_node2 = {
    "device_id": "device_2",
    "status_pintu": 0,      # 0 = Terkunci (Aman), 1 = Terbuka
    "deteksi_gerak": 0,     # 0 = Ruangan Kosong, 1 = Ada Manusia (PIR)
    "jarak_stok": 22.0,     # HC-SR04 kapasitas stok dalam cm (fluktuasi)
    "status_uv": 0,         # 0 = Siaga (Off), 1 = Sterilisasi Aktif (On)
    "status_led": 0,
}

mqtt_client = None

def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print("[MQTT] Berhasil terhubung ke Broker Mosquitto!")
        client.subscribe(TOPIC_CONTROL_ALL)
        print(f"[MQTT] Mendengarkan perintah aktuator pada '{TOPIC_CONTROL_ALL}'\n")
    else:
        print(f"[MQTT] Gagal terhubung (rc={rc})")

def on_message(client, userdata, msg):
    """Menerima perintah dari tombol di aplikasi Flutter"""
    try:
        payload_str = msg.payload.decode("utf-8")
        data = json.loads(payload_str)
        actuator = data.get("actuator")
        state = int(data.get("state", 0))

        # 1. Perintah Sterilisasi UV-C (Node 2)
        if actuator == "uv" or "uv" in msg.topic:
            # Human safety interlock
            if state == 1 and state_node2["deteksi_gerak"] == 1:
                print("\n>> [SAFETY INTERLOCK] Ada orang terdeteksi PIR! UV-C dicegah menyala demi keselamatan!")
                state_node2["status_uv"] = 0
            else:
                state_node2["status_uv"] = state
                status_text = "MENYALA (Sterilisasi)" if state == 1 else "MATI (Mode Siaga)"
                print(f"\n>> [HP KONTROL -> UV-C] Relay Lampu UV-C: {status_text}")

            # Publikasikan status terbaru ke app
            client.publish(TOPIC_SENSOR, json.dumps({
                "device_id": "device_2",
                "status_uv": state_node2["status_uv"],
                "status_pintu": state_node2["status_pintu"],
                "deteksi_gerak": state_node2["deteksi_gerak"],
                "jarak_stok": state_node2["jarak_stok"]
            }))

        # 2. Perintah Buzzer Alarm (Node 1)
        elif actuator == "buzzer" or "buzzer" in msg.topic:
            state_node1["status_buzzer"] = state
            status_text = "BERBUNYI (Alarm Kritis)" if state == 1 else "MATI (Normal)"
            print(f"\n>> [HP KONTROL -> ALARM] Sirine Buzzer: {status_text}")

        # 3. Perintah Kipas Fan (Node 1)
        elif actuator == "fan" or "fan" in msg.topic:
            state_node1["status_kipas"] = state
            status_text = "MENYALA (Pendinginan)" if state == 1 else "MATI"
            print(f"\n>> [HP KONTROL -> KIPAS] Relay Kipas: {status_text}")

    except Exception as e:
        print(f"[PARSE ERROR KONTROL] {e}")

def input_listener():
    """Thread interaktif agar user bisa trigger event hardware dari keyboard"""
    while True:
        try:
            cmd = input().strip().lower()
            if cmd == 'p':
                state_node2["status_pintu"] = 1 if state_node2["status_pintu"] == 0 else 0
                st = "TERBUKA (Bocor Suhu!)" if state_node2["status_pintu"] == 1 else "TERKUNCI RAPAT (Aman)"
                print(f"\n>> [KEYBOARD TRIGGER] Sensor Pintu Reed Switch: {st}")
            elif cmd == 'g':
                state_node2["deteksi_gerak"] = 1 if state_node2["deteksi_gerak"] == 0 else 0
                if state_node2["deteksi_gerak"] == 1 and state_node2["status_uv"] == 1:
                    state_node2["status_uv"] = 0
                    print("\n>> [KEYBOARD TRIGGER] PIR: ADA ORANG MASUK! Auto-Cutoff Lampu UV-C!")
                else:
                    st = "ADA ORANG DI RUANGAN" if state_node2["deteksi_gerak"] == 1 else "RUANGAN KOSONG (Aman Steril)"
                    print(f"\n>> [KEYBOARD TRIGGER] Sensor Gerak PIR: {st}")
            elif cmd == 'u':
                if state_node2["status_uv"] == 0 and state_node2["deteksi_gerak"] == 1:
                    print("\n>> [KEYBOARD TRIGGER] DITOLAK: Ada orang di ruangan, UV-C berbahaya!")
                else:
                    state_node2["status_uv"] = 1 if state_node2["status_uv"] == 0 else 0
                    st = "MENYALA (Sterilisasi)" if state_node2["status_uv"] == 1 else "SIAGA"
                    print(f"\n>> [KEYBOARD TRIGGER] Sinar UV-C: {st}")
            elif cmd == 'b':
                state_node1["status_buzzer"] = 1 if state_node1["status_buzzer"] == 0 else 0
                st = "BERBUNYI" if state_node1["status_buzzer"] == 1 else "MATI"
                print(f"\n>> [KEYBOARD TRIGGER] Alarm Sirine: {st}")
        except (EOFError, KeyboardInterrupt):
            break

def main():
    global mqtt_client
    print("=" * 70)
    print("   SIMULATOR HARDWARE ESP32-S3 — GUDANG FARMASI PHARMA MEDIC")
    print("=" * 70)
    print("Target Payload disesuaikan 100% dengan firmware ESP32-S3:")
    print("  - Node 1: Suhu Vaksin (2-8°C), Kelembapan, Gas MQ-2")
    print("  - Node 2: Pintu Reed Switch, PIR Gerak, HC-SR04 Stok, Relay UV-C")
    print("-" * 70)
    print("KONTROL CEPAT KEYBOARD:")
    print("  Ketik 'p' + Enter : Buka / Tutup Pintu (Reed Switch)")
    print("  Ketik 'g' + Enter : Ada Orang / Ruangan Kosong (PIR)")
    print("  Ketik 'u' + Enter : Nyalakan / Matikan Sinar UV-C")
    print("  Ketik 'b' + Enter : Nyalakan / Matikan Buzzer Alarm")
    print("  (Atau tekan tombol langsung di aplikasi Flutter HP kamu!)")
    print("-" * 70)

    try:
        client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    except AttributeError:
        client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    mqtt_client = client

    connected = False
    for broker_ip in BROKER_CANDIDATES:
        try:
            print(f"[KONEKSI] Mencoba broker di {broker_ip}:{PORT}...", end=" ")
            client.connect(broker_ip, PORT, keepalive=60)
            connected = True
            print("SUKSES!")
            break
        except Exception:
            print("Gagal.")

    if not connected:
        print("\n[ERROR] Tidak dapat terhubung ke Broker Mosquitto.")
        print("Pastikan Docker/VM sedang berjalan (port 1883 aktif).")
        sys.exit(1)

    client.loop_start()

    # Jalankan listener keyboard di thread terpisah
    kb_thread = threading.Thread(target=input_listener, daemon=True)
    kb_thread.start()

    print("\n[SIMULASI AKTIF] Mengirim data berkala tiap 3 detik. Tekan Ctrl+C untuk keluar.\n")

    tick = 0
    try:
        while True:
            tick += 1
            now_str = datetime.datetime.now().strftime("%H:%M:%S")

            # 1. Fluktuasi Halus Node 1 (Rak Vaksin)
            delta_suhu = round(random.uniform(-0.15, 0.15), 2)
            state_node1["suhu"] = round(max(3.2, min(6.8, state_node1["suhu"] + delta_suhu)), 2)

            delta_hum = round(random.uniform(-0.3, 0.3), 1)
            state_node1["kelembapan"] = round(max(46.0, min(56.0, state_node1["kelembapan"] + delta_hum)), 1)

            delta_gas = round(random.uniform(-0.4, 0.4), 1)
            state_node1["kadar_gas"] = round(max(8.0, min(18.0, state_node1["kadar_gas"] + delta_gas)), 1)

            # 2. Fluktuasi Halus Node 2 (Jarak Stok Ultrasonik HC-SR04)
            delta_stok = round(random.uniform(-0.4, 0.4), 1)
            state_node2["jarak_stok"] = round(max(15.0, min(30.0, state_node2["jarak_stok"] + delta_stok)), 1)

            # Jika pintu terbuka, perlahan suhu naik sedikit
            if state_node2["status_pintu"] == 1:
                state_node1["suhu"] = round(min(8.5, state_node1["suhu"] + 0.1), 2)

            # Otomatis matikan UV jika ada gerakan
            if state_node2["deteksi_gerak"] == 1 and state_node2["status_uv"] == 1:
                state_node2["status_uv"] = 0

            # 3. Kirim Payload Node 1 (ESP32-S3)
            payload_n1 = {
                "device_id": "device_1",
                "suhu": state_node1["suhu"],
                "kelembapan": state_node1["kelembapan"],
                "kadar_gas": state_node1["kadar_gas"],
                "cahaya": state_node1["cahaya"],
                "status_kipas": state_node1["status_kipas"],
                "status_buzzer": state_node1["status_buzzer"],
                "status_pintu": state_node2["status_pintu"],
                "status_uv": state_node2["status_uv"],
                "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
            client.publish(TOPIC_SENSOR, json.dumps(payload_n1))

            # 4. Kirim Payload Node 2 (ESP32-S3)
            payload_n2 = {
                "device_id": "device_2",
                "status_pintu": state_node2["status_pintu"],
                "deteksi_gerak": state_node2["deteksi_gerak"],
                "jarak_stok": state_node2["jarak_stok"],
                "status_uv": state_node2["status_uv"],
                "status_led": state_node2["status_led"],
                "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
            client.publish(TOPIC_SENSOR, json.dumps(payload_n2))

            # Log Terminal Lengkap & Rapi
            pintu_txt = "TERBUKA (Bocor!)" if state_node2["status_pintu"] == 1 else "Terkunci"
            uv_txt = "MENYALA (Steril)" if state_node2["status_uv"] == 1 else "Siaga"
            pir_txt = "ADA ORANG" if state_node2["deteksi_gerak"] == 1 else "Kosong"

            print(f"[{now_str}] Node 1: Suhu {state_node1['suhu']}°C | Lembap {state_node1['kelembapan']}% | Gas {state_node1['kadar_gas']} PPM"
                  f"  ||  Node 2: Pintu {pintu_txt} | PIR {pir_txt} | Stok {state_node2['jarak_stok']}cm | UV-C {uv_txt}")

            time.sleep(3)

    except KeyboardInterrupt:
        print("\n[STOP] Simulator dihentikan oleh pengguna.")
    finally:
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    main()
