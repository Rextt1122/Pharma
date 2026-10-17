import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sensor_model.dart';
import '../services/api_service.dart';

class HistoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<SensorModel> _historyList = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SensorModel> get historyList => _historyList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  HistoryProvider() {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Anti-stuck safety timer: force dismiss skeleton after 5s if network hangs
    Future.delayed(const Duration(seconds: 5), () {
      if (_isLoading) {
        _isLoading = false;
        if (_historyList.isEmpty && _errorMessage == null) {
          _errorMessage = 'Waktu permintaan habis. Periksa koneksi ke server.';
        }
        notifyListeners();
      }
    });

    try {
      _historyList = await _apiService.fetchSensorHistory();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportToCsv() async {
    if (_historyList.isEmpty) {
      return null;
    }

    try {
      List<List<dynamic>> csvData = [
        ['No', 'Suhu (°C)', 'Kelembapan (%)', 'Kadar Gas (PPM)', 'Status Pintu', 'Status UV', 'Status', 'Waktu'],
        ..._historyList.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return [
            index,
            item.suhu,
            item.kelembapan,
            item.kadarGas,
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
