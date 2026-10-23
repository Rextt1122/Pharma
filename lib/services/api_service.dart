import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_model.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService = StorageService();

  Future<List<SensorModel>> fetchSensorHistory() async {
    final savedIp = await _storageService.getServerIp();
    final candidates = <String>{
      savedIp,
      '192.168.33.10',
      '127.0.0.1',
      '192.168.137.1',
    }.where((ip) => ip.isNotEmpty && ip != '192.168.1.100').toList();

    Object? lastError;

    for (final ip in candidates) {
      final url = Uri.parse('http://$ip:8001/sensor');
      try {
        final response = await http.get(url).timeout(const Duration(milliseconds: 2500));

        if (response.statusCode == 200) {
          if (ip != savedIp) {
            await _storageService.saveServerIp(ip);
          }
          final dynamic decodedData = jsonDecode(response.body);

          if (decodedData is List) {
            return decodedData
                .map((item) => SensorModel.fromJson(item as Map<String, dynamic>))
                .toList();
          } else if (decodedData is Map<String, dynamic>) {
            return [SensorModel.fromJson(decodedData)];
          } else {
            throw const FormatException('Format data JSON tidak valid');
          }
        } else {
          lastError = Exception(
            'Gagal mengambil data. Status code: ${response.statusCode}',
          );
        }
      } catch (e) {
        if (e is FormatException) rethrow;
        lastError = e;
      }
    }

    throw Exception('Gagal terhubung ke server: $lastError');
  }
}
