class SensorModel {
  final double suhu;
  final double kelembapan;
  final double kadarGas;
  final int statusPintu;
  final int statusUv;
  final String status;
  final String? waktu;

  SensorModel({
    this.suhu = 0.0,
    this.kelembapan = 0.0,
    this.kadarGas = 0.0,
    this.statusPintu = 0,
    this.statusUv = 0,
    this.status = 'Aman',
    this.waktu,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      suhu: (json['suhu'] as num?)?.toDouble() ?? 0.0,
      kelembapan: (json['kelembapan'] as num?)?.toDouble() ?? 0.0,
      kadarGas: (json['kadar_gas'] as num?)?.toDouble() ?? 0.0,
      statusPintu: (json['status_pintu'] as num?)?.toInt() ?? 0,
      statusUv: (json['status_uv'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'Aman',
      waktu: json['waktu'] as String? ?? json['created_at'] as String? ?? json['timestamp'] as String?,
    );
  }

  bool get isGasBahaya => kadarGas > 50;
  bool get isPintuTerbuka => statusPintu == 1;
  bool get isUvMenyala => statusUv == 1;
  String get teksPintu => isPintuTerbuka ? 'Peringatan (Terbuka)' : 'Aman (Tertutup)';
  String get teksUv => isUvMenyala ? 'Menyala (Sterilisasi)' : 'Mati';
}
