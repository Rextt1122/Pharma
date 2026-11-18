// ============================================================================
// DOKUMENTASI: subnet_ips_io.dart — Prefix subnet lokal (Android/desktop)
//
// Implementasi native untuk pemindaian host: membaca antarmuka IPv4 lewat dart:io.
// Versi web ada di subnet_ips_web.dart dengan fungsi yang sama (mengembalikan kosong).
//
// Dibaca sebagai referensi implementasi; komentar menjelaskan alasan, bukan mengulang nama simbol.
// ============================================================================
import 'dart:io';

// Mengembalikan prefix /24 dari semua antarmuka IPv4 lokal (mis. 192.168.1).
//
// Dipakai ApiService untuk memindai kandidat host di jaringan yang sama saat
// alamat server tersimpan tidak merespons.
//
// 192.168.33.x dan 192.168.56.x dilewati karena dipakai VirtualBox host-only,
// bukan jaringan gudang.
Future<List<String>> getLocalSubnetPrefixes() async {
  final prefixes = <String>{};
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        final parts = addr.address.split('.');
        if (parts.length == 4) {
          final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
          if (prefix != '192.168.33' && prefix != '192.168.56') {
            prefixes.add(prefix);
          }
        }
      }
    }
  } catch (_) {}
  return prefixes.toList();
}
