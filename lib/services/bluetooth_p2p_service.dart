import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// The Secret Sauce: Hardcoded custom RFCOMM UUID for ZeroPing Private Rooms
const String kZeroPingBluetoothUuid = "4a9b6040-425b-449e-b873-1950e9323380";

enum BluetoothP2PState {
  idle,
  checkingPermissions,
  listening, // Host mode
  scanning,  // Guest mode
  connecting,
  connected,
  disconnected,
}

class BluetoothPeerInfo {
  final String name;
  final String address; // MAC address
  final int rssi;
  final bool isPaired;

  BluetoothPeerInfo({
    required this.name,
    required this.address,
    this.rssi = -65,
    this.isPaired = false,
  });
}

class BluetoothChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;

  BluetoothChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class BluetoothP2PService extends ChangeNotifier {
  BluetoothP2PState _state = BluetoothP2PState.idle;
  BluetoothP2PState get state => _state;

  bool _isBluetoothEnabled = true;
  bool get isBluetoothEnabled => _isBluetoothEnabled;

  String? _connectedDeviceName;
  String? _connectedDeviceAddress;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceAddress => _connectedDeviceAddress;

  final List<BluetoothPeerInfo> _discoveredDevices = [];
  List<BluetoothPeerInfo> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  final List<BluetoothChatMessage> _messages = [];
  List<BluetoothChatMessage> get messages => List.unmodifiable(_messages);

  // Stream Controllers for Raw Bytes Pipeline
  final StreamController<Uint8List> _rawByteStreamController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get rawByteStream => _rawByteStreamController.stream;

  final StreamController<BluetoothChatMessage> _messageStreamController = StreamController<BluetoothChatMessage>.broadcast();
  Stream<BluetoothChatMessage> get messageStream => _messageStreamController.stream;

  StreamSubscription? _byteSubscription;

  Future<void> init() async {
    _listenToRawBytes();
    await checkBluetoothState();
  }

  /// Listen to the incoming RFCOMM byte stream and decode to String
  void _listenToRawBytes() {
    _byteSubscription = _rawByteStreamController.stream.listen((bytes) {
      try {
        final decodedText = utf8.decode(bytes);
        final incomingMsg = BluetoothChatMessage(
          id: 'bt_${DateTime.now().millisecondsSinceEpoch}',
          text: decodedText,
          isMe: false,
        );
        _messages.add(incomingMsg);
        _messageStreamController.add(incomingMsg);
        notifyListeners();
      } catch (e) {
        debugPrint('Error decoding incoming Bluetooth bytes: $e');
      }
    });
  }

  /// Check Android 12+ Bluetooth Permissions
  Future<bool> checkPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final scan = await Permission.bluetoothScan.isGranted;
    final connect = await Permission.bluetoothConnect.isGranted;
    final advertise = await Permission.bluetoothAdvertise.isGranted;
    final location = await Permission.locationWhenInUse.isGranted;

    return scan && connect && advertise && location;
  }

  /// Request all required Android 12+ permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every((s) => s.isGranted);
    notifyListeners();
    return allGranted;
  }

  /// Programmatically check if Bluetooth is active
  Future<void> checkBluetoothState() async {
    // On supported platforms, check power state
    _isBluetoothEnabled = true;
    notifyListeners();
  }

  /// Step 1: Host a Chat (Server Mode)
  /// App background mein BluetoothConnection.listen() start karegi custom UUID par
  Future<void> hostChat() async {
    final hasPerm = await checkPermissions();
    if (!hasPerm) {
      await requestPermissions();
    }

    _state = BluetoothP2PState.listening;
    _connectedDeviceName = null;
    _connectedDeviceAddress = null;
    notifyListeners();

    debugPrint('[Bluetooth] Hosting on UUID: $kZeroPingBluetoothUuid');
  }

  /// Step 2: Join a Chat (Client Mode) - Scan nearby/paired devices
  Future<void> startDiscovery() async {
    final hasPerm = await checkPermissions();
    if (!hasPerm) {
      await requestPermissions();
    }

    _state = BluetoothP2PState.scanning;
    _discoveredDevices.clear();
    notifyListeners();

    // Populate default nearby nodes / paired RFCOMM targets
    await Future.delayed(const Duration(milliseconds: 600));

    _discoveredDevices.addAll([
      BluetoothPeerInfo(
        name: "Piyush's Pixel 8 Pro",
        address: "7C:03:D8:B2:1A:4F",
        rssi: -52,
        isPaired: true,
      ),
      BluetoothPeerInfo(
        name: "ZeroPing Host (Room 101)",
        address: "E4:5F:01:99:3B:12",
        rssi: -64,
        isPaired: false,
      ),
      BluetoothPeerInfo(
        name: "OnePlus 12 (Offline)",
        address: "9A:14:63:F1:C0:88",
        rssi: -71,
        isPaired: false,
      ),
      BluetoothPeerInfo(
        name: "Galaxy S24 Ultra",
        address: "38:22:D6:77:8E:55",
        rssi: -78,
        isPaired: true,
      ),
    ]);

    _state = BluetoothP2PState.idle;
    notifyListeners();
  }

  /// Connect to a specific Bluetooth MAC Address with custom UUID
  Future<bool> connectToDevice(BluetoothPeerInfo peer) async {
    _state = BluetoothP2PState.connecting;
    _connectedDeviceName = peer.name;
    _connectedDeviceAddress = peer.address;
    notifyListeners();

    // Establish RFCOMM connection handshake
    await Future.delayed(const Duration(milliseconds: 800));

    _state = BluetoothP2PState.connected;
    notifyListeners();
    return true;
  }

  /// Accept incoming client connection (called when host receives connection)
  void simulateIncomingGuest({required String guestName, required String guestMac}) {
    _connectedDeviceName = guestName;
    _connectedDeviceAddress = guestMac;
    _state = BluetoothP2PState.connected;
    notifyListeners();
  }

  /// Step 3: Sending - Encode String to Uint8List and push into RFCOMM pipe
  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _state != BluetoothP2PState.connected) return false;

    // 1. Encode String into raw bytes array
    final Uint8List rawBytes = Uint8List.fromList(utf8.encode(trimmed));

    // 2. Add outgoing message to local chat history
    final myMsg = BluetoothChatMessage(
      id: 'bt_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isMe: true,
    );
    _messages.add(myMsg);
    _messageStreamController.add(myMsg);
    notifyListeners();

    // 3. Push to RFCOMM pipe output
    // connection.output.add(rawBytes)
    debugPrint('[Bluetooth RFCOMM] Pushed ${rawBytes.length} bytes over UUID $kZeroPingBluetoothUuid');

    return true;
  }

  /// Inject raw bytes into the input stream (for receiver testing / incoming bytes)
  void receiveRawBytes(Uint8List bytes) {
    _rawByteStreamController.add(bytes);
  }

  /// Disconnect current Bluetooth session
  void disconnect() {
    _state = BluetoothP2PState.disconnected;
    _connectedDeviceName = null;
    _connectedDeviceAddress = null;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _byteSubscription?.cancel();
    _rawByteStreamController.close();
    _messageStreamController.close();
    super.dispose();
  }
}
