import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_model.dart';
import 'storage_service.dart';
import 'subnet_ips_io.dart'
    if (dart.library.js_interop) 'subnet_ips_web.dart'
    if (dart.library.html) 'subnet_ips_web.dart';

class ApiService {
  final StorageService _storageService = StorageService();
  static Future<String?>? _ongoingDiscovery;

  Future<String> resolveReachableIp() async {
    final savedIp = await _storageService.getServerIp();
    if (_ongoingDiscovery != null) {
      final found = await _ongoingDiscovery;
      if (found != null) return found;
    }
    final completer = Completer<String?>();
    _ongoingDiscovery = completer.future;
    try {
      final found = await _discoverIp(savedIp);
      completer.complete(found);
      if (found != null && found != savedIp) {
        await _storageService.saveServerIp(found);
      }
      return found ?? savedIp;
    } catch (_) {
      completer.complete(null);
      return savedIp;
    } finally {
      _ongoingDiscovery = null;
    }
  }

  Future<String?> _probeIp(String ip, Duration timeout) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip:8001/'))
          .timeout(timeout);
      if (response.statusCode == 200) {
        return ip;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _raceIps(List<String> ips, Duration timeout) async {
    if (ips.isEmpty) return null;
    final completer = Completer<String?>();
    int remaining = ips.length;

    for (final ip in ips) {
      _probeIp(ip, timeout).then((res) {
        if (res != null && !completer.isCompleted) {
          completer.complete(res);
        } else {
          remaining--;
          if (remaining == 0 && !completer.isCompleted) {
            completer.complete(null);
          }
        }
      });
    }
    return completer.future;
  }

  Future<String?> _discoverIp(String savedIp) async {
    final fastCandidates = <String>{
      if (savedIp.isNotEmpty && savedIp != '192.168.1.100') savedIp,
      '127.0.0.1',
      '192.168.33.10',
      '192.168.1.21',
      '192.168.137.1',
    }.toList();

    final fastHit = await _raceIps(
      fastCandidates,
      const Duration(milliseconds: 1200),
    );
    if (fastHit != null) return fastHit;

    // Auto-scan phone's Wi-Fi /24 subnet if fast candidates didn't match
    final prefixes = await getLocalSubnetPrefixes();
    for (final prefix in prefixes) {
      for (int start = 1; start <= 254; start += 64) {
        final end = (start + 63 > 254) ? 254 : start + 63;
        final batch = <String>[
          for (int i = start; i <= end; i++) '$prefix.$i',
        ];
        final hit = await _raceIps(batch, const Duration(milliseconds: 650));
        if (hit != null) return hit;
      }
    }
    return null;
  }

  Future<List<SensorModel>> fetchSensorHistory() async {
    final ip = await resolveReachableIp();
    final url = Uri.parse('http://$ip:8001/sensor');

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(milliseconds: 3000));

      if (response.statusCode == 200) {
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
        throw Exception(
          'Gagal mengambil data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is FormatException) rethrow;
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final ip = await resolveReachableIp();
    final url = Uri.parse('http://$ip:8001/login');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return data;
      } else {
        final errorMsg = data['detail'] ?? 'Autentikasi gagal';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('ClientException')) {
        rethrow;
      }
      throw Exception('Gagal menghubungi server database: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
    String role = 'operator',
  }) async {
    final ip = await resolveReachableIp();
    final url = Uri.parse('http://$ip:8001/register');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
              'full_name': fullName.trim(),
              'email': email.trim(),
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return data;
      } else {
        final errorMsg = data['detail'] ?? 'Registrasi gagal';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('ClientException')) {
        rethrow;
      }
      throw Exception('Gagal menghubungi server database: $e');
    }
  }
}
