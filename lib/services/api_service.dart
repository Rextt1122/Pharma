import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_model.dart';
import 'navigation_service.dart';
import 'storage_service.dart';
import 'subnet_ips_io.dart'
    if (dart.library.js_interop) 'subnet_ips_web.dart'
    if (dart.library.html) 'subnet_ips_web.dart';

class ApiService {
  final StorageService _storageService = StorageService();
  static Future<String?>? _ongoingDiscovery;
  static String? _cachedActiveHost;

  static void invalidateHostCache() {
    _cachedActiveHost = null;
  }

  Uri buildUrl(String ip, String path) {
    final cleanIp = ip.trim();
    if (cleanIp.startsWith('http://') || cleanIp.startsWith('https://')) {
      final uri = Uri.parse(cleanIp);
      return uri.replace(path: path);
    }
    if (cleanIp.contains('pharma.web.id')) {
      return Uri.parse('https://$cleanIp$path');
    }
    return Uri.parse('http://$cleanIp:8001$path');
  }

  Future<String> resolveReachableIp() async {
    if (_cachedActiveHost != null) return _cachedActiveHost!;

    final savedIp = await _storageService.getServerIp();

    // Fast check: if savedIp is valid and responds within 800ms, use immediately
    if (savedIp.isNotEmpty &&
        savedIp != '192.168.1.100' &&
        savedIp != '192.168.33.10') {
      final probeResult = await _probeIp(
        savedIp,
        const Duration(milliseconds: 800),
      );
      if (probeResult != null) {
        _cachedActiveHost = probeResult;
        return probeResult;
      }
    }

    if (_ongoingDiscovery != null) {
      final found = await _ongoingDiscovery;
      if (found != null) return found;
    }
    final completer = Completer<String?>();
    _ongoingDiscovery = completer.future;
    try {
      final found = await _discoverIp(savedIp);
      completer.complete(found);
      if (found != null) {
        _cachedActiveHost = found;
        if (found != savedIp) {
          await _storageService.saveServerIp(found);
        }
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
      final response = await http.get(buildUrl(ip, '/')).timeout(timeout);
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
      'api.pharma.web.id',
      if (savedIp.isNotEmpty && savedIp != '192.168.1.100') savedIp,
      '192.168.253.238',
      '192.168.1.25',
      '127.0.0.1',
      '192.168.33.10',
      '192.168.1.21',
      '192.168.137.1',
    }.toList();

    final fastHit = await _raceIps(
      fastCandidates,
      const Duration(milliseconds: 3000),
    );
    if (fastHit != null) return fastHit;

    // Auto-scan phone's Wi-Fi /24 subnet if fast candidates didn't match
    final prefixes = await getLocalSubnetPrefixes();
    for (final prefix in prefixes) {
      for (int start = 1; start <= 254; start += 64) {
        final end = (start + 63 > 254) ? 254 : start + 63;
        final batch = <String>[for (int i = start; i <= end; i++) '$prefix.$i'];
        final hit = await _raceIps(batch, const Duration(milliseconds: 650));
        if (hit != null) return hit;
      }
    }
    return null;
  }

  Future<List<SensorModel>> fetchSensorHistory() async {
    final ip = await resolveReachableIp();
    final url = buildUrl(ip, '/sensor');

    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        redirectToLogin();
        throw Exception('Sesi berakhir, silakan login ulang');
      }

      final response = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 401) {
        await _storageService.invalidateSession();
        redirectToLogin();
        throw Exception('Sesi berakhir, silakan login ulang');
      }

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
      invalidateHostCache();
      if (e is FormatException) rethrow;
      if (e.toString().contains('Sesi berakhir')) rethrow;
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // FUNGSI AUTENTIKASI: LOGIN USER / OPERATOR

  // Mengirim username & password ke endpoint POST /login di server FastAPI.

  Future<Map<String, dynamic>> login(String username, String password) async {
    final ip = await resolveReachableIp();
    final url = buildUrl(ip, '/login');

    try {
      // Eksekusi HTTP POST request
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 12));

      // Decode respons JSON dari server
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Cek status kode HTTP
      if (response.statusCode == 200) {
        // Ambil token sesi JWT
        final token = data['token'] as String?;
        if (token == null || token.isEmpty) {
          throw Exception('Server tidak mengirim token sesi');
        }
        // Simpan token otorisasi ke storage lokal
        await _storageService.saveAuthToken(token);

        // Ambil data user & simpan hak akses
        final user = (data['user'] as Map<String, dynamic>?) ?? {};
        final role = user['role']?.toString();
        if (role != null) {
          await _storageService.saveUserRole(role);
        }
        return data;
      } else {
        // Jika username/password salah atau akun terkunci
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
  }) async {
    final ip = await resolveReachableIp();
    final url = buildUrl(ip, '/register');

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
            }),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final token = data['token'] as String?;
        if (token == null || token.isEmpty) {
          throw Exception('Server tidak mengirim token sesi');
        }
        await _storageService.saveAuthToken(token);
        final user = (data['user'] as Map<String, dynamic>?) ?? {};
        final role = user['role']?.toString() ?? 'user';
        await _storageService.saveUserRole(role);
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

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String email,
  }) async {
    final ip = await resolveReachableIp();
    final url = buildUrl(ip, '/update-profile');
    final token = await _storageService.getAuthToken();

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'full_name': fullName.trim(),
              'email': email.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['detail'] ?? 'Gagal memperbarui profil di server');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('ClientException')) rethrow;
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final ip = await resolveReachableIp();
    final url = buildUrl(ip, '/change-password');
    final token = await _storageService.getAuthToken();

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'old_password': oldPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['detail'] ?? 'Gagal mengubah password');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('ClientException')) rethrow;
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final ip = await resolveReachableIp();
    final url = buildUrl(ip, '/users');
    final token = await _storageService.getAuthToken();

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (response.statusCode == 401) {
        await _storageService.invalidateSession();
        redirectToLogin();
        throw Exception('Sesi berakhir. Silakan login ulang.');
      } else if (response.statusCode == 403) {
        throw Exception('Hanya Operator yang berwenang mengelola pengguna.');
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['detail'] ?? 'Gagal mengambil daftar pengguna');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('ClientException')) rethrow;
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  Future<Map<String, dynamic>> updateUserRole({
    required int userId,
    required String role,
  }) async {
    final ip = await resolveReachableIp();
    final url = buildUrl(ip, '/users/role');
    final token = await _storageService.getAuthToken();

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'user_id': userId,
              'role': role.trim().toLowerCase(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return data;
      } else if (response.statusCode == 401) {
        await _storageService.invalidateSession();
        redirectToLogin();
        throw Exception('Sesi berakhir. Silakan login ulang.');
      } else if (response.statusCode == 403) {
        throw Exception('Akses ditolak: hanya operator yang memiliki izin');
      } else {
        throw Exception(data['detail'] ?? 'Gagal mengubah role pengguna');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('ClientException')) rethrow;
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  Future<Map<String, dynamic>> deleteUser(int userId) async {
    final ip = await resolveReachableIp();
    final url = buildUrl(ip, '/users/$userId');
    final token = await _storageService.getAuthToken();

    try {
      final response = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return data;
      } else if (response.statusCode == 401) {
        await _storageService.invalidateSession();
        redirectToLogin();
        throw Exception('Sesi berakhir. Silakan login ulang.');
      } else if (response.statusCode == 403) {
        throw Exception('Akses ditolak: hanya operator yang memiliki izin');
      } else {
        throw Exception(data['detail'] ?? 'Gagal menghapus pengguna');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('ClientException')) rethrow;
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  Future<Map<String, dynamic>> fetchMyProfile() async {
    final ip = await resolveReachableIp();
    final url = buildUrl(ip, '/me');
    final token = await _storageService.getAuthToken();

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final role = data['role']?.toString() ?? 'user';
        final name = data['name']?.toString() ?? '';
        final email = data['email']?.toString() ?? '';
        if (name.isNotEmpty && email.isNotEmpty) {
          await _storageService.saveUserProfile(
            name: name,
            email: email,
            provider: 'Database MySQL ($role)',
            role: role,
          );
        }
        return data;
      } else if (response.statusCode == 401) {
        await _storageService.invalidateSession();
        redirectToLogin();
        throw Exception('Sesi berakhir. Silakan login ulang.');
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['detail'] ?? 'Gagal mengambil data profil');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('ClientException')) rethrow;
      throw Exception('Gagal menghubungi server: $e');
    }
  }
}
