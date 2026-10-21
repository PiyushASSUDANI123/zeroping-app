import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/peer_device.dart';
import '../services/browser_drop_service.dart';
import '../services/broadcast_engine.dart';
import '../services/clipboard_service.dart';
import '../services/discovery_service.dart';
import '../services/p2p_socket_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
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
  final VoidCallback onNavigateToTransfers;

  const RadarScreen({
    super.key,
    required this.discoveryService,
    required this.socketService,
    required this.browserDropService,
    required this.clipboardService,
    required this.broadcastEngine,
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

  String? _extractValidIp(String raw) {
    if (raw.isEmpty) return null;
    final match = RegExp(r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b').firstMatch(raw);
    if (match != null) {
      final candidate = match.group(0)!;
      final parts = candidate.split('.').map(int.tryParse).toList();
      if (parts.length == 4 && parts.every((p) => p != null && p >= 0 && p <= 255)) {
        return candidate;
      }
    }
    return null;
  }

  void _showGlobalInviteModal() {
    final myIp = widget.discoveryService.myIp;
    final profile = StorageService.getUserProfile();
    final name = profile?.name ?? widget.discoveryService.myDeviceName;
    final inviteLink = 'http://$myIp:8080/join?node=${Uri.encodeComponent(name)}';
    final shareMessage = '⚡ Join my ZeroPing Direct P2P Room!\n\nLink: $inviteLink\nDirect Socket IP: $myIp\n\n100% offline, 0% cloud uploads. Download app: https://github.com/PiyushASSUDANI123/zeroping-app';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(22),
        color: AppTheme.surfaceCard.withValues(alpha: 0.98),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share_rounded, color: AppTheme.primaryCyan, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite Peers to ZeroPing Room',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Share via link to connect phones or laptops instantly',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: AppTheme.primaryCyan, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      inviteLink,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryCyan, size: 18),
                    tooltip: 'Copy Link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteLink));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.primaryCyan,
                          content: Text('Room invite link copied to clipboard!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share Room Link to Friends / WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                SharePlus.instance.share(
                  ShareParams(
                    text: shareMessage,
                    subject: 'Connect to ZeroPing Room',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDirectConnectDialog() {
    final ipController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppTheme.glassBorder, width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.add_link_rounded, color: AppTheme.primaryCyan),
            SizedBox(width: 8),
            Text(
              'Connect via IP or Link',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter peer IP address or paste an invite link (e.g. 192.168.1.15 or http://192.168.1.15:8080). Zero fake data.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ipController,
              autofocus: true,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 192.168.1.15 or paste link',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryCyan, width: 1.5),
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
              final raw = ipController.text.trim();
              final ip = _extractValidIp(raw);
              if (ip != null) {
                widget.discoveryService.addDirectPeer(ip);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.primaryCyan,
                    content: Text('Connected to node $ip! Beacon announced.'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.accentRose,
                    content: Text('Invalid IP format. Enter a valid IPv4 address (e.g. 192.168.1.15).'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Connect Node'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBigSend() async {
    try {
      final result = await FilePicker.pickFiles();
      if (result.isNotEmpty) {
        final file = result.first;
        final path = file.path ?? file.name;
        final peers = widget.discoveryService.peers;

        if (!mounted) return;

        if (peers.isEmpty) {
          _showNoPeersDialog(path);
          return;
        }

        // Show Peer Picker Modal with 1-to-Many option
        _showSendTargetPicker(path, peers);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('File picker error: $e')),
        );
      }
    }
  }

  void _handleBigReceive() {
    final myIp = widget.discoveryService.myIp;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(22),
        color: AppTheme.surfaceCard.withValues(alpha: 0.98),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryCyan.withValues(alpha: 0.12),
                border: Border.all(color: AppTheme.primaryCyan, width: 1.5),
              ),
              child: const Icon(Icons.download_rounded, color: AppTheme.primaryCyan, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'ZeroPing Receiver Ready',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Listening for incoming TCP chunk streams from nearby ZeroPing nodes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Local IP Address', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text(
                    myIp,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TCP Transfer Port', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text(
                    '${P2PSocketService.tcpPort} (High-Speed)',
                    style: TextStyle(
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.textPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendTargetPicker(String filePath, List<PeerDevice> peers) {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        color: AppTheme.surfaceCard.withValues(alpha: 0.98),
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
                        'Select Recipient Node',
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
                if (peers.length > 1)
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
                    backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.12),
                    child: const Icon(Icons.devices_rounded, color: AppTheme.primaryCyan),
                  ),
                  title: Text(peer.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('${peer.ip} • ${peer.deviceType.name.toUpperCase()}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace')),
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

  void _startClassroomBroadcast(String filePath, List<PeerDevice> peers) async {
    final senderId = StorageService.getDeviceId();
    final senderName = StorageService.getDeviceName();
    await widget.broadcastEngine.startBroadcast(
      filePath: filePath,
      targets: peers,
      senderId: senderId,
      senderName: senderName,
      socketService: widget.socketService,
    );

    if (!mounted) return;
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: const Text('No Nearby Peers Detected', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        content: const Text(
          'Make sure the receiving device has opened ZeroPing on the same Wi-Fi, or connect directly using their local IP.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showDirectConnectDialog();
            },
            child: const Text('Connect via IP', style: TextStyle(color: AppTheme.primaryCyan)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendFile(PeerDevice peer) async {
    Navigator.pop(context);
    try {
      final result = await FilePicker.pickFiles();
      if (result.isNotEmpty) {
        final path = result.first.path ?? result.first.name;
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
    final myIp = widget.discoveryService.myIp;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isRunning = widget.browserDropService.isRunning;
          final url = widget.browserDropService.webUrl.isNotEmpty
              ? widget.browserDropService.webUrl
              : 'http://$myIp:${widget.browserDropService.port}';

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: AppTheme.glassBorder),
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
                  'No app needed on PC! Start the local HTTP server, open the URL in Chrome on your laptop, and drag-and-drop files.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                if (isRunning) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 14),
                            SizedBox(width: 6),
                            Text('HTTP Server Active', style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          url,
                          style: const TextStyle(
                            color: AppTheme.primaryCyan,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      await widget.browserDropService.startServer(hostIp: myIp);
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Web Sync Server'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryCyan,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (isRunning)
                TextButton(
                  onPressed: () {
                    widget.browserDropService.stopServer();
                    setDialogState(() {});
                  },
                  child: const Text('Stop Server', style: TextStyle(color: AppTheme.accentRose)),
                ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.textPrimary, foregroundColor: Colors.white),
                child: const Text('Done'),
              ),
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
            color: AppTheme.surfaceCard.withValues(alpha: 0.98),
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
                      activeThumbColor: AppTheme.primaryCyan,
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
                        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
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
        final profile = StorageService.getUserProfile();

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                const PermissionBanner(),

                // Minimalist Premium Top Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Node Profile Info
                      Row(
                        children: [
                          AppAvatar(
                            avatar: profile?.avatar ?? AppAvatar.defaultAvatars[0].id,
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    profile?.name ?? myName,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isScanning ? AppTheme.accentGreen : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'IP: $myIp • Port ${P2PSocketService.tcpPort}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Tool shortcuts: Direct Connect, Invite Link, Universal Clipboard, Browser Drop
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: AppTheme.primaryCyan, size: 20),
                            tooltip: 'Invite via Link',
                            onPressed: _showGlobalInviteModal,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_link_rounded, color: AppTheme.textSecondary, size: 21),
                            tooltip: 'Connect via IP or Link',
                            onPressed: _showDirectConnectDialog,
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_paste_rounded, color: AppTheme.textSecondary, size: 20),
                            tooltip: 'Universal Clipboard',
                            onPressed: _showClipboardDrawer,
                          ),
                          IconButton(
                            icon: const Icon(Icons.laptop_chromebook_rounded, color: AppTheme.textSecondary, size: 20),
                            tooltip: 'Browser Drop (PC Sync)',
                            onPressed: _showBrowserDropDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppTheme.glassBorder),

                // Centerpiece: Minimalist Radar Scanner
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: RadarScanner(
                        peers: peers,
                        isScanning: isScanning,
                        localDeviceName: profile?.name ?? myName,
                        onPeerTap: _onPeerTapped,
                      ),
                    ),
                  ),
                ),

                // Peers status / Empty network prompt
                if (peers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.glassBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.radar_rounded, color: AppTheme.primaryCyan, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scanning local Wi-Fi subnet...',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Open ZeroPing on any peer to pair, or connect directly via IP.',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _showDirectConnectDialog,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryCyan,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            child: const Text('+ Enter IP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Horizontal discovered peer list
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: peers.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final peer = peers[index];
                        return GestureDetector(
                          onTap: () => _onPeerTapped(peer),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x06000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.12),
                                  child: const Icon(Icons.devices_rounded, color: AppTheme.primaryCyan, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      peer.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${peer.ip} • < 1ms',
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textMuted),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Minimalist Premium Action Buttons: SEND & RECEIVE
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Row(
                    children: [
                      // Premium Dark Slate SEND Button
                      Expanded(
                        child: GestureDetector(
                          onTap: _handleBigSend,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.textPrimary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A0F172A),
                                  blurRadius: 14,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'SEND FILES',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Premium Porcelain RECEIVE Button
                      Expanded(
                        child: GestureDetector(
                          onTap: _handleBigReceive,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.glassBorder, width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_downward_rounded, color: AppTheme.primaryCyan, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'RECEIVE READY',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
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
      color: AppTheme.surfaceCard.withValues(alpha: 0.98),
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
                  color: AppTheme.primaryCyan.withValues(alpha: 0.12),
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
                    foregroundColor: Colors.white,
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
                    backgroundColor: AppTheme.surfaceCard,
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.glassBorder),
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
