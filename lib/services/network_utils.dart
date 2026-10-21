import 'dart:io';

class NetworkUtils {
  /// Returns all available local IPv4 addresses (excluding loopback)
  static Future<List<InternetAddress>> getLocalIPv4Addresses() async {
    final List<InternetAddress> addresses = [];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            addresses.add(addr);
          }
        }
      }
    } catch (e) {
      // In case of network errors
    }
    return addresses;
  }

  /// Get primary local IP (prefers 192.168.*, 10.*, 172.16-31.*)
  static Future<String> getPrimaryLocalIP() async {
    final addrs = await getLocalIPv4Addresses();
    if (addrs.isEmpty) return '127.0.0.1';

    // Prioritize standard local subnet IPs (Wi-Fi / Hotspot)
    for (final addr in addrs) {
      final ip = addr.address;
      if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
        return ip;
      }
    }
    return addrs.first.address;
  }

  /// Computes the broadcast addresses for discovery ping
  static Future<List<InternetAddress>> getBroadcastAddresses() async {
    final List<InternetAddress> broadcastList = [];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              // Standard /24 subnet broadcast address: x.x.x.255
              final subnetBroadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
              try {
                broadcastList.add(InternetAddress(subnetBroadcast));
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}

    // Universal broadcast address
    try {
      broadcastList.add(InternetAddress('255.255.255.255'));
    } catch (_) {}

    return broadcastList;
  }
}
