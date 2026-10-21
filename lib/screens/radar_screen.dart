import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/peer_device.dart';
import '../services/discovery_service.dart';
import '../services/p2p_socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/permission_banner.dart';
import '../widgets/radar_scanner.dart';
import 'chat_screen.dart';

class RadarScreen extends StatefulWidget {
  final DiscoveryService discoveryService;
  final P2PSocketService socketService;
  final VoidCallback onNavigateToTransfers;

  const RadarScreen({
    super.key,
    required this.discoveryService,
    required this.socketService,
    required this.onNavigateToTransfers,
  });

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  @override
  void initState() {
    super.initState();
    // Auto start discovery when landing on radar
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

  Future<void> _pickAndSendFile(PeerDevice peer) async {
    Navigator.pop(context); // Close bottom sheet
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.surfaceCard,
                content: Text(
                  'Offered "${task.fileName}" to ${peer.name}',
                  style: const TextStyle(color: AppTheme.primaryCyan),
                ),
                action: SnackBarAction(
                  label: 'View',
                  textColor: AppTheme.accentGreen,
                  onPressed: widget.onNavigateToTransfers,
                ),
              ),
            );
            widget.onNavigateToTransfers();
          }
        }
      } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentRose,
            content: Text('Failed to select or send file: $e'),
          ),
        );
      }
    }
  }

  void _showManualConnectDialog() {
    final ipController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.wifi_find_rounded, color: AppTheme.primaryCyan),
            SizedBox(width: 8),
            Text('Manual IP Connect', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If UDP broadcast is blocked by your Wi-Fi router, enter peer IP directly:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ipController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'e.g. 192.168.43.15',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryCyan),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final ip = ipController.text.trim();
              if (ip.isNotEmpty) {
                Navigator.pop(ctx);
                final manualPeer = PeerDevice(
                  id: 'manual_$ip',
                  name: 'Peer ($ip)',
                  ip: ip,
                  port: P2PSocketService.tcpPort,
                  deviceType: DeviceType.unknown,
                );
                _onPeerTapped(manualPeer);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.black,
            ),
            child: const Text('Connect'),
          ),
        ],
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
                // Permission Warning Banner if on Android
                const PermissionBanner(),

                // Status Bar / Network Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryCyan.withOpacity(0.8),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isScanning ? 'RADAR ACTIVE • SCANNING' : 'RADAR IDLE',
                                style: TextStyle(
                                  color: isScanning ? AppTheme.primaryCyan : AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Local IP: $myIp : ${P2PSocketService.tcpPort}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Manual IP connect button
                          IconButton(
                            icon: const Icon(Icons.add_link_rounded, color: AppTheme.primaryCyan),
                            tooltip: 'Direct IP Connect',
                            onPressed: _showManualConnectDialog,
                          ),
                          // Scan Toggle
                          IconButton(
                            icon: Icon(
                              isScanning ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                              color: isScanning ? AppTheme.accentRose : AppTheme.accentGreen,
                            ),
                            tooltip: isScanning ? 'Stop Discovery' : 'Start Discovery',
                            onPressed: () {
                              if (isScanning) {
                                widget.discoveryService.stopDiscovery();
                              } else {
                                widget.discoveryService.startDiscovery();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Radar Canvas Centerpiece
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: RadarScanner(
                        peers: peers,
                        isScanning: isScanning,
                        localDeviceName: myName,
                        onPeerTap: _onPeerTapped,
                      ),
                    ),
                  ),
                ),

                // Bottom Peer Summary & Quick Send
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.devices_rounded, color: AppTheme.primaryCyan, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              '${peers.length} Nearby Device${peers.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (peers.isNotEmpty)
                          Text(
                            'Tap a node to connect',
                            style: TextStyle(
                              color: AppTheme.textMuted.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          )
                        else
                          const Text(
                            'Waiting for ping on subnet...',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
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
      color: AppTheme.surfaceCard.withOpacity(0.95),
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
                  color: AppTheme.primaryCyan.withOpacity(0.15),
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
