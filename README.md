# Pharma Medic

> **Smart Pharmaceutical & Vaccine Cold Storage IoT Monitoring**  
> Sistem pemantauan telemetri rantai dingin (*cold chain*) dan sterilisasi gudang farmasi berbasis Internet of Things (IoT).

[![Release](https://img.shields.io/github/v/release/Rextt1122/Pharma?style=flat-square&color=0E555A)](https://github.com/Rextt1122/Pharma/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

---

## Ringkasan Proyek

**Pharma Medic** dirancang untuk memastikan keamanan penyimpanan obat dan vaksin yang memerlukan kontrol ketat (*cold chain storage* 2°C – 8°C dan ruang steril 15°C – 25°C). Aplikasi mobile ini terhubung langsung ke sensor mikrokontroler melalui protokol MQTT dan REST API FastAPI untuk memantau lingkungan, memberikan peringatan jika suhu/gas melebihi ambang batas, serta mengontrol aktuator secara *real-time*.

---

## Fitur Utama

- **Real-time Telemetry Dashboard**: Pemantauan suhu (*radial gauge*), kelembapan, status pintu gudang, serta konsentrasi gas/asap (PPM).
- **Multi-Device / Rak Storage Switcher**: Pemantauan terpisah antara Rak A (Vaksin 2–8°C) dan Rak B (Steril 15–25°C).
- **Digital Twin 3D & Denah 2D**: Simulasi visual 3D layout gudang farmasi dan posisi sensor (`gudang_3d.glb`).
- **Kontrol Aktuator Cepat**: Saklar lampu sterilisasi UV-C dan alarm buzzer secara bidireksional via MQTT.
- **Riwayat Log & Ekspor CSV**: Penyimpanan riwayat telemetri otomatis dengan grafik sensor dan fitur ekspor ke file `.csv`.
- **Konfigurasi Ambang Batas (*Thresholds*)**: Kustomisasi batas aman suhu, kelembapan, dan gas serta alamat IP server langsung dari aplikasi.
- **Autentikasi & SSO**: Login/Register dengan verifikasi form serta integrasi profil akun Google, Facebook, dan Apple.

---

## Tech Stack & Arsitektur

| Komponen | Teknologi |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.13) |
| **State Management** | `provider` |
| **IoT Protocol** | MQTT Mosquitto (`mqtt_client`) via WebSocket & TCP |
| **Backend REST API** | FastAPI (Python) |
| **Visualisasi & Gauges** | `syncfusion_flutter_gauges`, `fl_chart` |
| **3D Rendering** | `model_viewer_plus` (glTF / GLB WebGL) |
| **Penyimpanan Lokal** | `shared_preferences` |
| **Ekspor Berkas** | `csv`, `path_provider` |

---

## Struktur Proyek

Peta berkas utama. Setiap berkas diawali blok komentar yang menjelaskan tujuan,
alur data, dan keterkaitannya dengan berkas lain.

| Jalur | Isi |
|---|---|
| `lib/main.dart` | Titik masuk, provider global, tabel rute |
| `lib/models/sensor_model.dart` | Model telemetri dua node + normalisasi payload |
| `lib/providers/sensor_provider.dart` | State dashboard: MQTT, REST, ambang, notifikasi, kontrol |
| `lib/providers/history_provider.dart` | Daftar log (maksimal 50) dan ekspor CSV |
| `lib/services/api_service.dart` | REST FastAPI, penemuan host, autentikasi |
| `lib/services/mqtt_service.dart` | Koneksi broker, subscribe telemetri, publish kontrol |
| `lib/services/storage_service.dart` | Preferences (non-rahasia) + secure storage (token) |
| `lib/services/update_service.dart` | Pembaruan APK lewat GitHub Releases |
| `lib/views/` | Layar: splash, login, dashboard, realtime, riwayat, 3D, pengaturan |
| `lib/widgets/` | Grafik tren, toast, shimmer, dekorasi vektor |
| `lib/theme/app_theme.dart` | Token warna, jarak, radius, tipografi |
| `backend/main.py` | FastAPI: auth, telemetri, kontrol, jembatan MQTT |
| `backend/dashboard.html` | Konsol web + simulator (satu berkas, tanpa build) |
| `scripts/simulator.py` | Simulator dua node lewat MQTT |
| `hardware/wokwi/` | Firmware ESP32-S3: `device1_sketch.ino`, `device2_sketch.ino` |

Alur data singkat:

```
ESP32 / simulator --MQTT--> backend/main.py --MySQL--> GET /sensor
        |                        |                          |
        +----MQTT telemetri----> app Flutter <---REST--------+
                                 |
                    perintah aktuator --> pharma/control/...
```

---

## Panduan Instalasi

### 1. Prasyarat
- Flutter SDK installed (`flutter doctor`)
- Android Studio / VS Code + Flutter Extension
- Perangkat Android (USB Debugging aktif) atau Emulator

### 2. Kloning Repositori
```bash
git clone https://github.com/Rextt1122/Pharma.git
cd Pharma
```

### 3. Pasang Dependensi
```bash
flutter pub get
```

### 4. Setup Koneksi Backend (Testing via USB)
Jika backend server (FastAPI & Mosquitto) berjalan di mesin lokal / VirtualBox VM, forward port ke perangkat Android:
```bash
adb reverse tcp:8001 tcp:8001
adb reverse tcp:1883 tcp:1883
```

### 5. Menjalankan Aplikasi
```bash
# Mode Debug (Hot Reload 'r', Hot Restart 'R')
flutter run

# Mode Release (Performa maksimal, ringan)
flutter run --release
```
---

## Pengembang

- **Pengembang**: Fabian Hendriyansah
- **Repositori**: [https://github.com/Rextt1122/Pharma](https://github.com/Rextt1122/Pharma)

