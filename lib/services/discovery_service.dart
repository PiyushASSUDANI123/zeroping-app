import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/peer_device.dart';
import 'network_utils.dart';

class DiscoveryService extends ChangeNotifier {
  static const int udpPort = 8888;
  static const int tcpPort = 8990;

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _pruneTimer;

  bool _isDiscovering = false;
  bool get isDiscovering => _isDiscovering;

  String _myDeviceId = '';
  String _myDeviceName = '';
  String _myIp = '';

  String get myDeviceId => _myDeviceId;
  String get myDeviceName => _myDeviceName;
  String get myIp => _myIp;

  final Map<String, PeerDevice> _peers = {};
  List<PeerDevice> get peers => _peers.values.toList();

  Future<void> init({required String deviceId, required String deviceName}) async {
    _myDeviceId = deviceId;
    _myDeviceName = deviceName;
    _myIp = await NetworkUtils.getPrimaryLocalIP();
    notifyListeners();
  }

  void updateDeviceName(String newName) {
    _myDeviceName = newName;
    notifyListeners();
    if (_isDiscovering) {
      _sendBroadcast();
    }
  }

  Future<bool> startDiscovery() async {
    if (_isDiscovering) return true;

    try {
      _myIp = await NetworkUtils.getPrimaryLocalIP();

      // Bind UDP Socket
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        udpPort,
        reuseAddress: true,
        reusePort: true,
      );

      _socket?.broadcastEnabled = true;
      _socket?.listen(_onDatagramReceived, onError: (e) {
        debugPrint('UDP Socket error: $e');
      });

      _isDiscovering = true;
      notifyListeners();

      // Immediately send first broadcast
      _sendBroadcast();

      // Schedule periodic broadcast every 2 seconds
      _broadcastTimer?.cancel();
      _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _sendBroadcast();
      });

      // Schedule peer timeout cleanup every 3 seconds
      _pruneTimer?.cancel();
      _pruneTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _pruneStalePeers();
      });

      return true;
    } catch (e) {
      debugPrint('Failed to start UDP discovery: $e');
      _isDiscovering = false;
      notifyListeners();
      return false;
    }
  }

  void _onDatagramReceived(RawSocketEvent event) {
    if (event != RawSocketEvent.read || _socket == null) return;

    final datagram = _socket!.receive();
    if (datagram == null) return;

    try {
      final message = utf8.decode(datagram.data);
      final json = jsonDecode(message) as Map<String, dynamic>;

      final type = json['type'] as String?;
      final peerId = json['id'] as String?;
      final senderIp = datagram.address.address;

      // Ignore our own broadcast
      if (peerId == _myDeviceId) return;

      if (type == 'zeroping_announce' || type == 'zeroping_ack') {
        final deviceTypeStr = (json['os'] as String?)?.toLowerCase() ?? '';
        DeviceType devType = DeviceType.unknown;
        if (deviceTypeStr.contains('android')) {
          devType = DeviceType.android;
        } else if (deviceTypeStr.contains('windows')) devType = DeviceType.windows;
        else if (deviceTypeStr.contains('macos') || deviceTypeStr.contains('darwin')) devType = DeviceType.macos;
        else if (deviceTypeStr.contains('linux')) devType = DeviceType.linux;
        else if (deviceTypeStr.contains('ios')) devType = DeviceType.ios;

        final peer = PeerDevice(
          id: peerId ?? senderIp,
          name: json['name'] as String? ?? 'Peer $senderIp',
          ip: senderIp,
          port: (json['port'] as num?)?.toInt() ?? tcpPort,
          deviceType: devType,
          lastSeen: DateTime.now(),
        );

        _peers[peer.id] = peer;
        notifyListeners();

        // If it was an announce, send an ACK directly back so discovery is instantaneous
        if (type == 'zeroping_announce') {
          _sendDirectAck(datagram.address, (json['port'] as num?)?.toInt() ?? udpPort);
        }
      }
    } catch (e) {
      // Packet format error or non-JSON
    }
  }

  void _sendBroadcast() async {
    if (_socket == null || !_isDiscovering) return;

    _myIp = await NetworkUtils.getPrimaryLocalIP();

    String osType = 'android';
    if (Platform.isWindows) osType = 'windows';
    if (Platform.isMacOS) osType = 'macos';
    if (Platform.isLinux) osType = 'linux';
    if (Platform.isIOS) osType = 'ios';

    final payload = jsonEncode({
      'type': 'zeroping_announce',
      'id': _myDeviceId,
      'name': _myDeviceName,
      'ip': _myIp,
      'port': tcpPort,
      'os': osType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final bytes = utf8.encode(payload);

    try {
      final broadcastAddresses = await NetworkUtils.getBroadcastAddresses();
      for (final addr in broadcastAddresses) {
        try {
          _socket?.send(bytes, addr, udpPort);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error sending UDP broadcast: $e');
    }
  }

  void _sendDirectAck(InternetAddress targetAddress, int targetPort) {
    if (_socket == null) return;

    String osType = 'android';
    if (Platform.isWindows) osType = 'windows';
    if (Platform.isMacOS) osType = 'macos';
    if (Platform.isLinux) osType = 'linux';

    final payload = jsonEncode({
      'type': 'zeroping_ack',
      'id': _myDeviceId,
      'name': _myDeviceName,
      'ip': _myIp,
      'port': tcpPort,
      'os': osType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final bytes = utf8.encode(payload);
    try {
      _socket?.send(bytes, targetAddress, udpPort);
    } catch (_) {}
  }

  void _pruneStalePeers() {
    final now = DateTime.now();
    bool changed = false;

    _peers.removeWhere((id, peer) {
      final isStale = now.difference(peer.lastSeen).inSeconds > 7;
      if (isStale) changed = true;
      return isStale;
    });

    if (changed) {
      notifyListeners();
    }
  }

  void stopDiscovery() {
    _broadcastTimer?.cancel();
    _pruneTimer?.cancel();
    _broadcastTimer = null;
    _pruneTimer = null;

    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;

    _isDiscovering = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopDiscovery();
    super.dispose();
  }
}
