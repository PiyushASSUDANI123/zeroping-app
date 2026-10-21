import 'package:flutter/material.dart';
import '../models/file_metadata.dart';
import '../services/browser_drop_service.dart';
import '../services/broadcast_engine.dart';
import '../services/clipboard_service.dart';
import '../services/discovery_service.dart';
import '../services/iot_node_service.dart';
import '../services/p2p_socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import 'files_screen.dart';
import 'radar_screen.dart';
import 'settings_screen.dart';
import 'transfers_screen.dart';

class HomeScreen extends StatefulWidget {
  final DiscoveryService discoveryService;
  final P2PSocketService socketService;
  final BrowserDropService browserDropService;
  final ClipboardService clipboardService;
  final BroadcastEngine broadcastEngine;
  final IoTNodeService iotNodeService;

  const HomeScreen({
    super.key,
    required this.discoveryService,
    required this.socketService,
    required this.browserDropService,
    required this.clipboardService,
    required this.broadcastEngine,
    required this.iotNodeService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Register global incoming file offer handler
    widget.socketService.onIncomingFileOffer = _handleIncomingFileOffer;
  }

  Future<bool> _handleIncomingFileOffer(
    FileMetadata metadata,
    String peerName,
    String peerIp,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppTheme.primaryCyan, width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: AppTheme.primaryCyan),
            SizedBox(width: 10),
            Text(
              'Incoming File Transfer',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$peerName ($peerIp) wants to stream a file directly via TCP:',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            GlassContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metadata.fileName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${_formatBytes(metadata.fileSize)}',
                    style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  if (metadata.sha256.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'SHA-256: ${metadata.sha256.substring(0, 16)}...',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Decline', style: TextStyle(color: AppTheme.accentRose)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              setState(() => _currentIndex = 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Accept & Stream Chunks'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      RadarScreen(
        discoveryService: widget.discoveryService,
        socketService: widget.socketService,
        browserDropService: widget.browserDropService,
        clipboardService: widget.clipboardService,
        broadcastEngine: widget.broadcastEngine,
        iotNodeService: widget.iotNodeService,
        onNavigateToTransfers: () => setState(() => _currentIndex = 1),
      ),
      TransfersScreen(
        socketService: widget.socketService,
        broadcastEngine: widget.broadcastEngine,
      ),
      FilesScreen(
        discoveryService: widget.discoveryService,
        socketService: widget.socketService,
        onNavigateToTransfers: () => setState(() => _currentIndex = 1),
      ),
      SettingsScreen(
        discoveryService: widget.discoveryService,
        socketService: widget.socketService,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.radar_rounded),
              label: 'Radar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horizontal_circle_rounded),
              label: 'Transfers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_special_rounded),
              label: 'Vault',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_rounded),
              label: 'Node Stats',
            ),
          ],
        ),
      ),
    );
  }
}
