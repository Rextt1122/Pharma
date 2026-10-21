class SensorModel {
  final String deviceId;
  final double suhu;
  final double kelembapan;
  final double kadarGas;
  final int statusPintu;
  final int statusUv;
  final String status;
  final String? waktu;

  SensorModel({
    this.deviceId = 'device_1',
    this.suhu = 0.0,
    this.kelembapan = 0.0,
    this.kadarGas = 0.0,
    this.statusPintu = 0,
    this.statusUv = 0,
    this.status = 'Aman',
    this.waktu,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json, {String defaultDeviceId = 'device_1'}) {
    return SensorModel(
      deviceId: json['device_id'] as String? ?? json['deviceId'] as String? ?? defaultDeviceId,
      suhu: (json['suhu'] as num?)?.toDouble() ?? 0.0,
      kelembapan: (json['kelembapan'] as num?)?.toDouble() ?? 0.0,
      kadarGas: (json['kadar_gas'] as num?)?.toDouble() ?? (json['gas'] as num?)?.toDouble() ?? 0.0,
      statusPintu: (json['status_pintu'] as num?)?.toInt() ?? 0,
      statusUv: (json['status_uv'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'Aman',
      waktu: json['waktu'] as String? ?? json['created_at'] as String? ?? json['timestamp'] as String?,
    );
  }

  SensorModel copyWith({
    String? deviceId,
    double? suhu,
    double? kelembapan,
    double? kadarGas,
    int? statusPintu,
    int? statusUv,
    String? status,
    String? waktu,
  }) {
    return SensorModel(
      deviceId: deviceId ?? this.deviceId,
      suhu: suhu ?? this.suhu,
      kelembapan: kelembapan ?? this.kelembapan,
      kadarGas: kadarGas ?? this.kadarGas,
      statusPintu: statusPintu ?? this.statusPintu,
      statusUv: statusUv ?? this.statusUv,
      status: status ?? this.status,
      waktu: waktu ?? this.waktu,
    );
  }

  bool get isGasBahaya => kadarGas > 50;
  bool get isPintuTerbuka => statusPintu == 1;
  bool get isUvMenyala => statusUv == 1;
  String get teksPintu => isPintuTerbuka ? 'Peringatan (Terbuka)' : 'Aman (Tertutup)';
  String get teksUv => isUvMenyala ? 'Menyala (Sterilisasi)' : 'Mati';
}
