// api_service.dart — Klien REST FastAPI
// GET/POST endpoint, penemuan host, Bearer token; 401 -> login.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_model.dart';
import 'navigation_service.dart';
import 'storage_service.dart';
import 'subnet_ips_io.dart'
    if (dart.library.js_interop) 'subnet_ips_web.dart'
    if (dart.library.html) 'subnet_ips_web.dart';

// Klien REST untuk backend FastAPI (backend/main.py).
class ApiService {
  final StorageService _storageService = StorageService();
  // Penemuan host berjalan sekali untuk semua pemanggil. Tanpa ini, dashboard
  // dan halaman riwayat bisa memindai jaringan bersamaan dan menggandakan beban.
  static Future<String?>? _ongoingDiscovery;
  // Host aktif di-cache selama sesi agar request berikutnya tidak menunggu
  // probe. Diinvalidasi saat request gagal (lihat catch di fetchSensorHistory).
  static String? _cachedActiveHost;

  // Memaksa probe ulang pada request berikutnya. Dipakai setelah kegagalan
  // jaringan atau saat pengguna mengganti alamat server di Pengaturan.
  static void invalidateHostCache() {
    _cachedActiveHost = null;
  }

  // Menyusun URL dari berbagai bentuk alamat yang mungkin diketik pengguna:
  // https://host , http://host:port , domain pharma.web.id, atau IP LAN murni.
  // IP LAN murni diarahkan ke port 8001 (port FastAPI di VM/dev).
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

  // Mengembalikan host yang paling mungkin hidup.
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

  // GET / dengan timeout pendek. Status 200 berarti server FastAPI hidup.
  // Exception apa pun dianggap "tidak hidup" agar pemindaian bisa lanjut.
  Future<String?> _probeIp(String ip, Duration timeout) async {
    try {
      final response = await http.get(buildUrl(ip, '/')).timeout(timeout);
      if (response.statusCode == 200) {
        return ip;
      }
    } catch (_) {}
    return null;
  }

  // Menembak semua kandidat paralel dan memakai yang pertama menjawab.
  // Host yang mati tidak memperlambat keseluruhan karena tidak ditunggu berurutan.
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

  // Dua tahap: kandidat yang sudah dikenal, lalu pemindaian subnet Wi-Fi.
  // Pemindaian dibagi batch 64 alamat dengan timeout 650 ms per batch agar
  // ponsel tidak membuka terlalu banyak koneksi sekaligus.
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

  // GET /sensor — butuh token.
  // Ambil log terbaru (limit default 50); 401 -> hapus sesi + ke login.
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

  // POST /login — publik.
  // Kirim {username, password}; simpan token + peran dari respons.
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

  // POST /register — publik.
  // Kirim {username, password, full_name, email}; token langsung dipakai.
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

  // POST /update-profile — butuh token.
  // Kirim {full_name, email}; respons {success, message}.
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

  // POST /change-password — butuh token.
  // Kirim {old_password, new_password}; sandi baru minimal 6 karakter.
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

  // GET /users — butuh token operator/admin.
  // Respons: daftar {id, username, full_name, email, role}.
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

  // POST /users/role — butuh token operator/admin.
  // Kirim {user_id, role}; role: admin | operator | user.
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

  // DELETE /users/{id} — butuh token operator/admin.
  // Aksi destruktif: UI wajib konfirmasi dulu.
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

  // GET /me — butuh token.
  // Sinkronkan profil lokal dari server; 401 -> sesi dihapus.
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
