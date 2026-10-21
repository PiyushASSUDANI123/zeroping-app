
enum DeviceType { android, windows, macos, linux, ios, unknown }

class PeerDevice {
  final String id;
  final String name;
  final String ip;
  final int port;
  final DeviceType deviceType;
  DateTime lastSeen;
  bool isConnected;
  double? pingMs;

  PeerDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    this.deviceType = DeviceType.unknown,
    DateTime? lastSeen,
    this.isConnected = false,
    this.pingMs,
  }) : lastSeen = lastSeen ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ip': ip,
        'port': port,
        'deviceType': deviceType.name,
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory PeerDevice.fromJson(Map<String, dynamic> json) {
    return PeerDevice(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Nearby Peer',
      ip: json['ip'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 8990,
      deviceType: DeviceType.values.firstWhere(
        (e) => e.name == (json['deviceType'] as String? ?? ''),
        orElse: () => DeviceType.unknown,
      ),
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PeerDevice copyWith({
    String? id,
    String? name,
    String? ip,
    int? port,
    DeviceType? deviceType,
    DateTime? lastSeen,
    bool? isConnected,
    double? pingMs,
  }) {
    return PeerDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      deviceType: deviceType ?? this.deviceType,
      lastSeen: lastSeen ?? this.lastSeen,
      isConnected: isConnected ?? this.isConnected,
      pingMs: pingMs ?? this.pingMs,
    );
  }
}
