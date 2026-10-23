import 'dart:io';

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
