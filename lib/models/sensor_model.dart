class SensorModel {
  final String deviceId;

  // DEVICE 1: Sistem Pemantauan Suhu & Udara Gudang
  final double suhu; // DHT22 (°C)
  final double kelembapan; // DHT22 (%)
  final double kadarGas; // MQ-2 Asap / Kebocoran Gas (PPM)
  final double cahaya; // LDR Sensor Cahaya (Lux / Raw)
  final int statusKipas; // Aktuator 1: Modul Relay Fan (0/1)
  final int statusBuzzer; // Aktuator 2: Sirine Buzzer (0/1)
  final int statusPompa; // Aktuator 3: Mini Water Pump (0/1)

  // DEVICE 2: Sistem Sterilisasi UV & Keamanan Pintu
  final int deteksiGerak; // Sensor 1: PIR Pendeteksi Gerak (0/1)
  final int statusPintu; // Sensor 2: Reed Switch Magnetik (0/1)
  final double jarakStok; // Sensor 3: HC-SR04 Kapasitas Tumpukan Kardus (cm)
  final int statusUv; // Aktuator 1: Modul Relay Lampu UV (0/1)
  final int statusLed; // Aktuator 2: LED Indikator Aman/Bahaya (0/1)

  final String status;
  final String? waktu;

  SensorModel({
    this.deviceId = 'device_1',
    this.suhu = 0.0,
    this.kelembapan = 0.0,
    this.kadarGas = 0.0,
    this.cahaya = 0.0,
    this.statusKipas = 0,
    this.statusBuzzer = 0,
    this.statusPompa = 0,
    this.deteksiGerak = 0,
    this.statusPintu = 0,
    this.jarakStok = 0.0,
    this.statusUv = 0,
    this.statusLed = 0,
    this.status = 'Aman',
    this.waktu,
  });

  factory SensorModel.fromJson(
    Map<String, dynamic> json, {
    String defaultDeviceId = 'device_1',
  }) {
    return SensorModel(
      deviceId:
          json['device_id'] as String? ??
          json['deviceId'] as String? ??
          defaultDeviceId,
      suhu: (json['suhu'] as num?)?.toDouble() ?? 0.0,
      kelembapan: (json['kelembapan'] as num?)?.toDouble() ?? 0.0,
      kadarGas:
          (json['kadar_gas'] as num?)?.toDouble() ??
          (json['gas'] as num?)?.toDouble() ??
          (json['mq2'] as num?)?.toDouble() ??
          0.0,
      cahaya:
          (json['cahaya'] as num?)?.toDouble() ??
          (json['ldr'] as num?)?.toDouble() ??
          (json['light'] as num?)?.toDouble() ??
          0.0,
      statusKipas:
          (json['status_kipas'] as num?)?.toInt() ??
          (json['kipas'] as num?)?.toInt() ??
          (json['fan'] as num?)?.toInt() ??
          0,
      statusBuzzer:
          (json['status_buzzer'] as num?)?.toInt() ??
          (json['buzzer'] as num?)?.toInt() ??
          0,
      statusPompa:
          (json['status_pompa'] as num?)?.toInt() ??
          (json['pompa'] as num?)?.toInt() ??
          (json['pump'] as num?)?.toInt() ??
          0,
      deteksiGerak:
          (json['deteksi_gerak'] as num?)?.toInt() ??
          (json['pir'] as num?)?.toInt() ??
          (json['gerak'] as num?)?.toInt() ??
          0,
      statusPintu:
          (json['status_pintu'] as num?)?.toInt() ??
          (json['pintu'] as num?)?.toInt() ??
          0,
      jarakStok:
          (json['jarak_stok'] as num?)?.toDouble() ??
          (json['jarak'] as num?)?.toDouble() ??
          (json['ultrasonik'] as num?)?.toDouble() ??
          (json['distance'] as num?)?.toDouble() ??
          0.0,
      statusUv:
          (json['status_uv'] as num?)?.toInt() ??
          (json['uv'] as num?)?.toInt() ??
          0,
      statusLed:
          (json['status_led'] as num?)?.toInt() ??
          (json['led'] as num?)?.toInt() ??
          0,
      status: json['status'] as String? ?? 'Aman',
      waktu:
          json['waktu'] as String? ??
          json['created_at'] as String? ??
          json['timestamp'] as String?,
    );
  }

  SensorModel copyWith({
    String? deviceId,
    double? suhu,
    double? kelembapan,
    double? kadarGas,
    double? cahaya,
    int? statusKipas,
    int? statusBuzzer,
    int? statusPompa,
    int? deteksiGerak,
    int? statusPintu,
    double? jarakStok,
    int? statusUv,
    int? statusLed,
    String? status,
    String? waktu,
  }) {
    return SensorModel(
      deviceId: deviceId ?? this.deviceId,
      suhu: suhu ?? this.suhu,
      kelembapan: kelembapan ?? this.kelembapan,
      kadarGas: kadarGas ?? this.kadarGas,
      cahaya: cahaya ?? this.cahaya,
      statusKipas: statusKipas ?? this.statusKipas,
      statusBuzzer: statusBuzzer ?? this.statusBuzzer,
      statusPompa: statusPompa ?? this.statusPompa,
      deteksiGerak: deteksiGerak ?? this.deteksiGerak,
      statusPintu: statusPintu ?? this.statusPintu,
      jarakStok: jarakStok ?? this.jarakStok,
      statusUv: statusUv ?? this.statusUv,
      statusLed: statusLed ?? this.statusLed,
      status: status ?? this.status,
      waktu: waktu ?? this.waktu,
    );
  }

  bool get isGasBahaya => kadarGas > 50;
  bool get isPintuTerbuka => statusPintu == 1;
  bool get isUvMenyala => statusUv == 1;
  bool get isKipasAktif => statusKipas == 1;
  bool get isBuzzerAktif => statusBuzzer == 1;
  bool get isPompaAktif => statusPompa == 1;
  bool get isGerakTerdeteksi => deteksiGerak == 1;
  bool get isLedBahaya => statusLed == 1;

  String get teksPintu =>
      isPintuTerbuka ? 'Peringatan (Terbuka)' : 'Aman (Tertutup)';
  String get teksUv =>
      isUvMenyala ? 'Menyala (Sterilisasi)' : 'Mati (Standby)';
  String get teksGerak =>
      isGerakTerdeteksi ? 'Ada Orang (UV Lock)' : 'Ruangan Kosong (Aman UV)';
  String get teksKapasitasStok {
    if (jarakStok <= 0) return 'Tinggi (85%)';
    if (jarakStok < 15) return 'Penuh (> 85%)';
    if (jarakStok < 35) return 'Optimal (~60%)';
    return 'Rendah (< 35%)';
  }
}
