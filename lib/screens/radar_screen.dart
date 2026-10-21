import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/peer_device.dart';
import '../services/browser_drop_service.dart';
import '../services/broadcast_engine.dart';
import '../services/clipboard_service.dart';
import '../services/discovery_service.dart';
import '../services/iot_node_service.dart';
import '../services/p2p_socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/permission_banner.dart';
import '../widgets/radar_scanner.dart';
import 'chat_screen.dart';

class RadarScreen extends StatefulWidget {
  final DiscoveryService discoveryService;
  final P2PSocketService socketService;
  final BrowserDropService browserDropService;
  final ClipboardService clipboardService;
  final BroadcastEngine broadcastEngine;
  final IoTNodeService iotNodeService;
  final VoidCallback onNavigateToTransfers;

  const RadarScreen({
    super.key,
    required this.discoveryService,
    required this.socketService,
    required this.browserDropService,
    required this.clipboardService,
    required this.broadcastEngine,
    required this.iotNodeService,
    required this.onNavigateToTransfers,
  });

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  @override
  void initState() {
    super.initState();
    widget.discoveryService.startDiscovery();
  }

  void _onPeerTapped(PeerDevice peer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PeerActionSheet(
        peer: peer,
        onSendFile: () => _pickAndSendFile(peer),
        onOpenChat: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                peer: peer,
                socketService: widget.socketService,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleBigSend() async {
    try {
      final picked = await FilePicker.pickFile();
      if (picked != null && picked.path != null) {
        final path = picked.path!;
        final peers = widget.discoveryService.peers;

        if (!mounted) return;

        if (peers.isEmpty) {
          _showNoPeersDialog(path);
          return;
        }

        // Show Peer Picker Modal with 1-to-Many Classroom option!
        _showSendTargetPicker(path, peers);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('File error: $e')),
        );
      }
    }
  }

  void _handleBigReceive() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(22),
        color: AppTheme.surfaceCard.withValues(alpha: 0.95),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.primaryCyan]),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryViolet.withValues(alpha: 0.5), blurRadius: 18),
                ],
              ),
              child: const Icon(Icons.download_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'ZeroPing Receive Mode Active',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Listening on Port ${P2PSocketService.tcpPort} • Subnet ${widget.discoveryService.myIp}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your node is visible to all nearby phones and PCs on this Wi-Fi / Hotspot. Any incoming file will prompt an acceptance popup.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Ready & Listening', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendTargetPicker(String filePath, List<PeerDevice> peers) {
    final fileName = filePath.split('/').last;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        color: AppTheme.surfaceCard.withValues(alpha: 0.95),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Destination',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // 1-to-Many Classroom Mode Trigger
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startClassroomBroadcast(filePath, peers);
                  },
                  icon: const Icon(Icons.groups_rounded, size: 16),
                  label: const Text('Broadcast All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.glassBorder),
            ...peers.map((peer) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.2),
                    child: const Icon(Icons.devices_rounded, color: AppTheme.primaryCyan),
                  ),
                  title: Text(peer.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('${peer.ip} • ${peer.deviceType.name.toUpperCase()}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace')),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primaryCyan),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final task = await widget.socketService.offerFile(
                      peerIp: peer.ip,
                      peerName: peer.name,
                      filePath: filePath,
                    );
                    if (task != null && mounted) {
                      widget.onNavigateToTransfers();
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _startClassroomBroadcast(String filePath, List<PeerDevice> peers) {
    widget.broadcastEngine.startBroadcast(
      filePath: filePath,
      targets: peers,
      senderId: widget.discoveryService.myDeviceId,
      senderName: widget.discoveryService.myDeviceName,
      socketService: widget.socketService,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        content: Text('Broadcasting to ${peers.length} peers in Classroom Mode! ⚡'),
        action: SnackBarAction(
          label: 'View',
          textColor: AppTheme.primaryCyan,
          onPressed: widget.onNavigateToTransfers,
        ),
      ),
    );
    widget.onNavigateToTransfers();
  }

  void _showNoPeersDialog(String filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.glassBorder)),
        title: const Text('No Nearby Peers Detected', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Make sure the receiving device has opened ZeroPing on the same Wi-Fi or Hotspot.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppTheme.primaryCyan)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendFile(PeerDevice peer) async {
    Navigator.pop(context);
    try {
      final picked = await FilePicker.pickFile();
      if (picked != null && picked.path != null) {
        final path = picked.path!;
        final task = await widget.socketService.offerFile(
          peerIp: peer.ip,
          peerName: peer.name,
          filePath: path,
        );

        if (task != null && mounted) {
          widget.onNavigateToTransfers();
        }
      }
    } catch (_) {}
  }

  void _showBrowserDropDialog() {
    final isRunning = widget.browserDropService.isRunning;
    final myIp = widget.discoveryService.myIp;

    if (!isRunning) {
      widget.browserDropService.startServer(hostIp: myIp);
    }

    showDialog(
      context: context,
      builder: (ctx) => AnimatedBuilder(
        animation: widget.browserDropService,
        builder: (context, _) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: AppTheme.primaryCyan, width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.laptop_chromebook_rounded, color: AppTheme.primaryCyan),
              SizedBox(width: 8),
              Text('Browser Drop (PC Sync)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No app required on your PC/Mac! Just open your browser and type this URL on the same Wi-Fi:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryCyan),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SelectableText(
                      widget.browserDropService.webUrl,
                      style: const TextStyle(
                        color: AppTheme.primaryCyan,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Icon(Icons.open_in_browser_rounded, color: AppTheme.primaryCyan, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '• Drag & drop files from PC directly to Phone\n• Download Phone Vault files to PC\n• Sync clipboard text & OTPs instantly',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                widget.browserDropService.stopServer();
                Navigator.pop(ctx);
              },
              child: const Text('Stop Server', style: TextStyle(color: AppTheme.accentRose)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: Colors.black,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIoTNodeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AnimatedBuilder(
        animation: widget.iotNodeService,
        builder: (context, _) {
          final node = widget.iotNodeService.activeNode;

          return AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: AppTheme.accentGreen)),
            title: const Row(
              children: [
                Icon(Icons.memory_rounded, color: AppTheme.accentGreen),
                SizedBox(width: 8),
                Text('Hardware Local Cloud Box', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline physical ESP32 drive on your router. Drop files or pick files without internet:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                if (node != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 14),
                            const SizedBox(width: 6),
                            Text(node.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('IP: ${node.ip} • Free: ${(node.freeSpaceMB / 1024).toStringAsFixed(1)} GB / ${(node.totalSpaceMB / 1024).toStringAsFixed(1)} GB',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace')),
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => widget.iotNodeService.connectToNode('192.168.1.150', simulate: true),
                    icon: const Icon(Icons.flash_on_rounded, size: 16),
                    label: const Text('Connect to Virtual/ESP32 Node'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.2),
                      foregroundColor: AppTheme.accentGreen,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppTheme.textMuted))),
            ],
          );
        },
      ),
    );
  }

  void _showClipboardDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimatedBuilder(
        animation: widget.clipboardService,
        builder: (context, _) {
          final items = widget.clipboardService.history;

          return GlassContainer(
            borderRadius: 24,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            color: AppTheme.surfaceCard.withValues(alpha: 0.95),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.content_paste_rounded, color: AppTheme.primaryCyan, size: 20),
                        SizedBox(width: 8),
                        Text('Zero-Cloud Clipboard', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Switch(
                      value: widget.clipboardService.autoSync,
                      activeColor: AppTheme.primaryCyan,
                      onChanged: (val) => widget.clipboardService.toggleAutoSync(val),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Copy on phone, paste on PC (Ctrl+V) instantly over local Wi-Fi.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No copied text yet. Copy any OTP/link!', style: TextStyle(color: AppTheme.textMuted, fontSize: 12))),
                  )
                else
                  ...items.take(4).map((item) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryCyan, size: 16),
                              onPressed: () {
                                widget.clipboardService.copyToClipboard(item.text);
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.discoveryService, widget.socketService]),
      builder: (context, _) {
        final isScanning = widget.discoveryService.isDiscovering;
        final peers = widget.discoveryService.peers;
        final myIp = widget.discoveryService.myIp;
        final myName = widget.discoveryService.myDeviceName;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const PermissionBanner(),

                // Top Minimal Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isScanning ? AppTheme.primaryCyan : AppTheme.textMuted,
                                  boxShadow: isScanning
                                      ? [BoxShadow(color: AppTheme.primaryCyan.withValues(alpha: 0.8), blurRadius: 6)]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'ZEROPING RADAR',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'IP: $myIp',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      // Tool shortcuts: Browser Drop & Clipboard
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.content_paste_rounded, color: AppTheme.primaryCyan),
                            tooltip: 'Universal Clipboard',
                            onPressed: _showClipboardDrawer,
                          ),
                          IconButton(
                            icon: const Icon(Icons.laptop_chromebook_rounded, color: AppTheme.primaryCyan),
                            tooltip: 'Browser Drop (PC Sync)',
                            onPressed: _showBrowserDropDialog,
                          ),
                          IconButton(
                            icon: const Icon(Icons.memory_rounded, color: AppTheme.accentGreen),
                            tooltip: 'Hardware Cloud Node',
                            onPressed: _showIoTNodeDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Centerpiece: Radar Scanner
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: RadarScanner(
                        peers: peers,
                        isScanning: isScanning,
                        localDeviceName: myName,
                        onPeerTap: _onPeerTapped,
                      ),
                    ),
                  ),
                ),

                // THE CORE FOCUS: Giant Send & Receive Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Big SEND Button
                      Expanded(
                        child: GestureDetector(
                          onTap: _handleBigSend,
                          child: Container(
                            height: 62,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00F0FF), Color(0xFF00A8FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryCyan.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'SEND',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Big RECEIVE Button
                      Expanded(
                        child: GestureDetector(
                          onTap: _handleBigReceive,
                          child: Container(
                            height: 62,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9D4EDD), Color(0xFF7000FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryViolet.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'RECEIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PeerActionSheet extends StatelessWidget {
  final PeerDevice peer;
  final VoidCallback onSendFile;
  final VoidCallback onOpenChat;

  const _PeerActionSheet({
    required this.peer,
    required this.onSendFile,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 24,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      color: AppTheme.surfaceCard.withValues(alpha: 0.95),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                  border: Border.all(color: AppTheme.primaryCyan, width: 1.5),
                ),
                child: const Icon(Icons.devices_rounded, color: AppTheme.primaryCyan, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${peer.ip} • Port ${peer.port} • OS: ${peer.deviceType.name.toUpperCase()}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSendFile,
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Send File / Media'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenChat,
                  icon: const Icon(Icons.forum_rounded, size: 18),
                  label: const Text('Walkie-Talkie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
