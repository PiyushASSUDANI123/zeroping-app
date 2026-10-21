import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/bluetooth_p2p_service.dart';
import 'services/browser_drop_service.dart';
import 'services/broadcast_engine.dart';
import 'services/clipboard_service.dart';
import 'services/discovery_service.dart';
import 'services/iot_node_service.dart';
import 'services/p2p_socket_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark immersive status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize persistence
  await StorageService.init();

  final deviceId = StorageService.getDeviceId();
  final deviceName = StorageService.getDeviceName();

  // Initialize Services
  final discoveryService = DiscoveryService();
  await discoveryService.init(deviceId: deviceId, deviceName: deviceName);

  final socketService = P2PSocketService();
  await socketService.init(deviceId: deviceId, deviceName: deviceName);

  final browserDropService = BrowserDropService();

  final clipboardService = ClipboardService();
  clipboardService.init();

  // Hook Universal Clipboard to TCP Socket
  clipboardService.onBroadcastClipboard = (text) {
    socketService.broadcastClipboard(text);
  };
  socketService.onClipboardReceived = (text, sender) {
    clipboardService.receiveRemoteClipboard(text: text, senderName: sender);
  };

  final broadcastEngine = BroadcastEngine();
  final iotNodeService = IoTNodeService();

  final bluetoothService = BluetoothP2PService();
  await bluetoothService.init();

  runApp(
    ZeroPingApp(
      discoveryService: discoveryService,
      socketService: socketService,
      browserDropService: browserDropService,
      clipboardService: clipboardService,
      broadcastEngine: broadcastEngine,
      iotNodeService: iotNodeService,
      bluetoothService: bluetoothService,
    ),
  );
}

class ZeroPingApp extends StatelessWidget {
  final DiscoveryService discoveryService;
  final P2PSocketService socketService;
  final BrowserDropService browserDropService;
  final ClipboardService clipboardService;
  final BroadcastEngine broadcastEngine;
  final IoTNodeService iotNodeService;
  final BluetoothP2PService bluetoothService;

  const ZeroPingApp({
    super.key,
    required this.discoveryService,
    required this.socketService,
    required this.browserDropService,
    required this.clipboardService,
    required this.broadcastEngine,
    required this.iotNodeService,
    required this.bluetoothService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZeroPing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeScreen(
        discoveryService: discoveryService,
        socketService: socketService,
        browserDropService: browserDropService,
        clipboardService: clipboardService,
        broadcastEngine: broadcastEngine,
        iotNodeService: iotNodeService,
        bluetoothService: bluetoothService,
      ),
    );
  }
}
