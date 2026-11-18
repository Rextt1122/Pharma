// ============================================================================
// DOKUMENTASI KODE: history_provider.dart — State riwayat telemetri dari API backend
// Dibaca sebagai referensi implementasi; komentar hanya menjelaskan alur penting.
// ============================================================================
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sensor_model.dart';
import '../services/api_service.dart';

// Menyimpan daftar log terbaru dan status muat untuk halaman Riwayat.
// Widget tidak boleh memanggil ApiService sendiri; semua akses data lewat sini.
class HistoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<SensorModel> _historyList = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SensorModel> get historyList => _historyList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Memuat log pertama kali provider dibuat (saat aplikasi start).
  HistoryProvider() {
    fetchHistory();
  }

// Mengambil log dari backend dan mengubah state loading/error.
// Mengambil ulang log dari backend.
//
// Efek samping: mengubah isLoading, errorMessage, dan historyList, lalu
// notifyListeners(). Daftar dipotong maksimal 50 entri terbaru agar RAM dan
// waktu render tetap wajar di perangkat kelas menengah.
//
// Loading ditahan minimal 400 ms supaya indikator tidak berkedip pada respons
// cepat (<100 ms).
Future<void> fetchHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    try {
      final result = await _apiService.fetchSensorHistory();
      // Batasi maksimal 50 log terbaru agar aplikasi mobile tetap ringan & tidak kebanyakan
      if (result.length > 50) {
        _historyList = result.take(50).toList();
      } else {
        _historyList = result;
      }
      _errorMessage = null;
    } catch (e) {
      // Pesan error diterjemahkan ke bahasa manusia; pengguna tidak perlu melihat
      // detail exception.
      if (e is FormatException) {
        _errorMessage = 'Data riwayat tidak dapat dibaca. Coba muat ulang.';
      } else if (e.toString().contains('Sesi berakhir') || e.toString().contains('401')) {
        _errorMessage = 'Sesi login telah berakhir. Silakan login kembali.';
      } else if (e.toString().contains('Timeout') || e.toString().contains('waktu') || e.toString().contains('Waktu')) {
        _errorMessage = 'Waktu permintaan habis. Server merespons lambat.';
      } else {
        _errorMessage = 'Gagal terhubung ke server. Periksa koneksi ke host.';
      }
    } finally {
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 400) {
        await Future.delayed(Duration(milliseconds: 400 - elapsed));
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menulis seluruh log yang sedang tampil ke berkas CSV di folder dokumen
  // aplikasi.
  //
  // Return: path absolut berkas, atau null bila daftar kosong.
  // Kolom mengikuti urutan: No, Suhu, Kelembapan, Gas, Cahaya, Pintu, UV,
  // Status, Waktu. Pemisah koma standar RFC 4180.
  Future<String?> exportToCsv() async {
    if (_historyList.isEmpty) {
      return null;
    }

    try {
      List<List<dynamic>> csvData = [
        ['No', 'Suhu (°C)', 'Kelembapan (%)', 'Kadar Gas (PPM)', 'Cahaya (Lux)', 'Status Pintu', 'Status UV', 'Status', 'Waktu'],
        ..._historyList.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return [
            index,
            item.suhu,
            item.kelembapan,
            item.kadarGas,
            item.cahaya.round(),
            item.teksPintu,
            item.teksUv,
            item.status,
            item.waktu ?? '-',
          ];
        }),
      ];

      String csvString = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/riwayat_pharma_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      return path;
    } catch (e) {
      throw Exception('Gagal melakukan export CSV: $e');
    }
  }
}
