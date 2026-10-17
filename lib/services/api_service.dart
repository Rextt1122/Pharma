import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_model.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService = StorageService();

  Future<List<SensorModel>> fetchSensorHistory() async {
    final ip = await _storageService.getServerIp();
    final url = Uri.parse('http://$ip:8001/sensor');

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);

        if (decodedData is List) {
          return decodedData
              .map((item) => SensorModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (decodedData is Map<String, dynamic>) {
          return [SensorModel.fromJson(decodedData)];
        } else {
          throw Exception('Format data JSON tidak valid');
        }
      } else {
        throw Exception('Gagal mengambil data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }
}
