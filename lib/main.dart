import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/discovery_service.dart';
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

  // Initialize Discovery and Socket Services
  final discoveryService = DiscoveryService();
  await discoveryService.init(deviceId: deviceId, deviceName: deviceName);

  final socketService = P2PSocketService();
  await socketService.init(deviceId: deviceId, deviceName: deviceName);

  runApp(
    ZeroPingApp(
      discoveryService: discoveryService,
      socketService: socketService,
    ),
  );
}

class ZeroPingApp extends StatelessWidget {
  final DiscoveryService discoveryService;
  final P2PSocketService socketService;

  const ZeroPingApp({
    super.key,
    required this.discoveryService,
    required this.socketService,
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
      ),
    );
  }
}
