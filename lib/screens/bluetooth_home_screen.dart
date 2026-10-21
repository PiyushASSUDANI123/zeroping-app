import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/bluetooth_p2p_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/radar_scanner.dart';

// ==========================================
// SCREEN 1: BLUETOOTH HOME (HOST OR JOIN)
// ==========================================
class BluetoothHomeScreen extends StatefulWidget {
  final BluetoothP2PService bluetoothService;

  const BluetoothHomeScreen({super.key, required this.bluetoothService});

  @override
  State<BluetoothHomeScreen> createState() => _BluetoothHomeScreenState();
}

class _BluetoothHomeScreenState extends State<BluetoothHomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.bluetoothService.init();
  }

  void _onHostPressed() async {
    await widget.bluetoothService.hostChat();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HostWaitingSheet(
        bluetoothService: widget.bluetoothService,
        onConnected: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BluetoothChatRoomScreen(
                bluetoothService: widget.bluetoothService,
              ),
            ),
          );
        },
      ),
    );
  }

  void _onJoinPressed() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothDiscoveryScreen(
          bluetoothService: widget.bluetoothService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Walkie-Talkie'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bluetooth_rounded, size: 14, color: AppTheme.primaryCyan),
                SizedBox(width: 4),
                Text('RFCOMM Direct', style: TextStyle(color: AppTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Glassmorphism Radar Effect
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.35,
                child: RadarScanner(
                  peers: const [],
                  isScanning: true,
                  localDeviceName: 'Bluetooth RFCOMM',
                  onPeerTap: (_) {},
                ),
              ),
            ),
          ),

          // Main Action Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Status Info Banner
                  GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentGreen,
                            boxShadow: [
                              BoxShadow(color: AppTheme.accentGreen, blurRadius: 8, spreadRadius: 1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offline RFCOMM Pipe Ready',
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Private UUID: 4a9b6040... • ₹0 Internet or Backend',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Big Focus Option 1: HOST A CHAT (Server)
                  GestureDetector(
                    onTap: _onHostPressed,
                    child: Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F0FF), Color(0xFF0072FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.2),
                            ),
                            child: const Icon(Icons.wifi_tethering_rounded, color: Colors.black, size: 30),
                          ),
                          const SizedBox(width: 20),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Host a Chat',
                                style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Become Server • Listen on private UUID',
                                style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Big Focus Option 2: JOIN A CHAT (Client)
                  GestureDetector(
                    onTap: _onJoinPressed,
                    child: Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9D4EDD), Color(0xFF5A189A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryViolet.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: const Icon(Icons.bluetooth_searching_rounded, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 20),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Join a Chat',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Scan nearby devices & connect to Host',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Host Listening Bottom Sheet Modal
class _HostWaitingSheet extends StatelessWidget {
  final BluetoothP2PService bluetoothService;
  final VoidCallback onConnected;

  const _HostWaitingSheet({
    required this.bluetoothService,
    required this.onConnected,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 24,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      color: AppTheme.surfaceCard.withValues(alpha: 0.96),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryCyan),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Hosting Bluetooth Room...',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Listening for incoming guest on custom UUID.\nAsk your friend to tap "Join a Chat" and select your phone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 20),
          // Instant Test Connect Button
          ElevatedButton(
            onPressed: () {
              bluetoothService.simulateIncomingGuest(
                guestName: "Guest Phone (OnePlus 12)",
                guestMac: "9A:14:63:F1:C0:88",
              );
              onConnected();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Start Chat Room (Connected)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              bluetoothService.disconnect();
              Navigator.pop(context);
            },
            child: const Text('Cancel Hosting', style: TextStyle(color: AppTheme.accentRose)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 2: DISCOVERY (LIST NEARBY DEVICES)
// ==========================================
class BluetoothDiscoveryScreen extends StatefulWidget {
  final BluetoothP2PService bluetoothService;

  const BluetoothDiscoveryScreen({super.key, required this.bluetoothService});

  @override
  State<BluetoothDiscoveryScreen> createState() => _BluetoothDiscoveryScreenState();
}

class _BluetoothDiscoveryScreenState extends State<BluetoothDiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    widget.bluetoothService.startDiscovery();
  }

  void _connect(BluetoothPeerInfo peer) async {
    final ok = await widget.bluetoothService.connectToDevice(peer);
    if (ok && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BluetoothChatRoomScreen(
            bluetoothService: widget.bluetoothService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.bluetoothService,
      builder: (context, _) {
        final devices = widget.bluetoothService.discoveredDevices;
        final isScanning = widget.bluetoothService.state == BluetoothP2PState.scanning;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Discovered Hosts'),
            actions: [
              IconButton(
                icon: Icon(
                  isScanning ? Icons.stop_circle_rounded : Icons.refresh_rounded,
                  color: AppTheme.primaryCyan,
                ),
                onPressed: () => widget.bluetoothService.startDiscovery(),
              ),
            ],
          ),
          body: devices.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryCyan),
                      SizedBox(height: 16),
                      Text('Scanning nearby Bluetooth devices...', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return GlassContainer(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      borderRadius: 18,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                            ),
                            child: const Icon(Icons.bluetooth_rounded, color: AppTheme.primaryCyan, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.name,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'MAC: ${device.address} • Signal: ${device.rssi} dBm',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _connect(device),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryCyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

// ==========================================
// SCREEN 3: CHAT ROOM (WHATSAPP DARK STYLE)
// ==========================================
class BluetoothChatRoomScreen extends StatefulWidget {
  final BluetoothP2PService bluetoothService;

  const BluetoothChatRoomScreen({super.key, required this.bluetoothService});

  @override
  State<BluetoothChatRoomScreen> createState() => _BluetoothChatRoomScreenState();
}

class _BluetoothChatRoomScreenState extends State<BluetoothChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    widget.bluetoothService.sendMessage(text);
    _scrollToBottom();
  }

  void _simulateIncomingEcho() {
    // Helper to simulate receiving raw bytes for demo/testing
    final sampleReply = "Received over Bluetooth! Ping < 1ms ✅";
    final rawBytes = Uint8List.fromList(utf8.encode(sampleReply));
    widget.bluetoothService.receiveRawBytes(rawBytes);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.bluetoothService,
      builder: (context, _) {
        final isConnected = widget.bluetoothService.state == BluetoothP2PState.connected;
        final peerName = widget.bluetoothService.connectedDeviceName ?? 'Bluetooth Peer';
        final peerAddress = widget.bluetoothService.connectedDeviceAddress ?? 'RFCOMM Socket';

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                // Live Status Indicator Dot (Green / Red)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? AppTheme.accentGreen : AppTheme.accentRose,
                    boxShadow: [
                      BoxShadow(
                        color: (isConnected ? AppTheme.accentGreen : AppTheme.accentRose).withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(peerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        isConnected ? 'Connected • $peerAddress' : 'Disconnected',
                        style: TextStyle(
                          fontSize: 10,
                          color: isConnected ? AppTheme.accentGreen : AppTheme.accentRose,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.flash_on_rounded, color: AppTheme.accentYellow, size: 20),
                tooltip: 'Simulate Incoming Byte Stream',
                onPressed: _simulateIncomingEcho,
              ),
              IconButton(
                icon: const Icon(Icons.power_settings_new_rounded, color: AppTheme.accentRose),
                tooltip: 'Disconnect',
                onPressed: () {
                  widget.bluetoothService.disconnect();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top Protocol Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  color: AppTheme.surfaceCard.withValues(alpha: 0.7),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, size: 12, color: AppTheme.accentGreen),
                      SizedBox(width: 6),
                      Text(
                        'Full Duplex RFCOMM Pipe • Raw Bytes Uint8List • 0% Internet',
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                // Real-time Chat Messages Stream
                Expanded(
                  child: StreamBuilder<BluetoothChatMessage>(
                    stream: widget.bluetoothService.messageStream,
                    builder: (context, _) {
                      final msgs = widget.bluetoothService.messages;

                      if (msgs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                              const SizedBox(height: 10),
                              const Text('Type a message to push bytes into the RFCOMM pipe!',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        itemCount: msgs.length,
                        itemBuilder: (context, index) {
                          final msg = msgs[index];
                          return _buildBubble(msg);
                        },
                      );
                    },
                  ),
                ),

                // WhatsApp-Style Bottom Input Bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Type Bluetooth message...',
                              hintStyle: TextStyle(color: AppTheme.textMuted),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                          onPressed: _send,
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

  Widget _buildBubble(BluetoothChatMessage msg) {
    final timeStr = DateFormat('hh:mm a').format(msg.timestamp);

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe ? AppTheme.primaryCyan.withValues(alpha: 0.18) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isMe ? AppTheme.primaryCyan.withValues(alpha: 0.4) : AppTheme.glassBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeStr, style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.8), fontSize: 9.5)),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all_rounded, size: 12, color: AppTheme.primaryCyan),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
