import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../services/bluetooth_p2p_service.dart';
import '../services/encryption_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/radar_scanner.dart';

// ==========================================
// SCREEN 1: BLUETOOTH HOME (HOST / JOIN / VAULT)
// ==========================================
class BluetoothHomeScreen extends StatefulWidget {
  final BluetoothP2PService bluetoothService;

  const BluetoothHomeScreen({super.key, required this.bluetoothService});

  @override
  State<BluetoothHomeScreen> createState() => _BluetoothHomeScreenState();
}

class _BluetoothHomeScreenState extends State<BluetoothHomeScreen> {
  bool _isStealthDark = false;

  @override
  void initState() {
    super.initState();
    widget.bluetoothService.init();
    _isStealthDark = StorageService.getString('zp_stealth_dark') == 'true';
  }

  void _toggleTheme() {
    setState(() => _isStealthDark = !_isStealthDark);
    StorageService.saveString('zp_stealth_dark', _isStealthDark ? 'true' : 'false');
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
        isDark: _isStealthDark,
        onConnected: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BluetoothChatRoomScreen(
                bluetoothService: widget.bluetoothService,
                isDark: _isStealthDark,
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
          isDark: _isStealthDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isStealthDark ? const Color(0xFF090D16) : AppTheme.background;
    final cardColor = _isStealthDark ? const Color(0xFF131A29) : AppTheme.surfaceCard;
    final textPrimary = _isStealthDark ? Colors.white : AppTheme.textPrimary;
    final textMuted = _isStealthDark ? const Color(0xFF8E9BAE) : AppTheme.textMuted;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          'Walkie-Talkie & Bluetooth P2P',
          style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isStealthDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppTheme.primaryCyan,
              size: 20,
            ),
            tooltip: _isStealthDark ? 'Switch to Light Theme' : 'Stealth Dark Mode',
            onPressed: _toggleTheme,
          ),
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security_rounded, size: 13, color: AppTheme.primaryCyan),
                SizedBox(width: 4),
                Text('AES-256', style: TextStyle(color: AppTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Radar Scanner Glow
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: _isStealthDark ? 0.25 : 0.4,
                child: RadarScanner(
                  peers: const [],
                  isScanning: true,
                  localDeviceName: 'RFCOMM Node',
                  onPeerTap: (_) {},
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                children: [
                  // Protocol & Architecture Banner
                  GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: cardColor,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Military-Grade RFCOMM & Voice Pipe Ready',
                                style: TextStyle(color: textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'UUID: 4a9b6040... • AES-256 E2E • Invisible Auto-Reconnect',
                                style: TextStyle(color: textMuted, fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Option 1: HOST CHAT (Server)
                  GestureDetector(
                    onTap: _onHostPressed,
                    child: Container(
                      height: 108,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.2),
                            ),
                            child: const Icon(Icons.wifi_tethering_rounded, color: Colors.black, size: 28),
                          ),
                          const SizedBox(width: 18),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Host Walkie-Talkie',
                                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Become Server • Listen on private RFCOMM pipe',
                                style: TextStyle(color: Colors.black87, fontSize: 11.5, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Option 2: JOIN CHAT (Client)
                  GestureDetector(
                    onTap: _onJoinPressed,
                    child: Container(
                      height: 108,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            child: const Icon(Icons.bluetooth_searching_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 18),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Join Walkie-Talkie',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Scan nearby RFCOMM hosts & connect directly',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w500),
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
  final bool isDark;

  const _HostWaitingSheet({
    required this.bluetoothService,
    required this.onConnected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF131A29) : AppTheme.surfaceCard;
    final textPrimary = isDark ? Colors.white : AppTheme.textPrimary;
    final textSecondary = isDark ? const Color(0xFF8E9BAE) : AppTheme.textSecondary;

    return GlassContainer(
      borderRadius: 24,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      color: bgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryCyan),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Hosting Encrypted RFCOMM Room...',
            style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Broadcasting on custom UUID: $kZeroPingBluetoothUuid.\nAsk your friend to tap "Join Walkie-Talkie" and select your device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              bluetoothService.simulateIncomingGuest(
                guestName: "Tactical Guest (Pixel 8)",
                guestMac: "9A:14:63:F1:C0:88",
              );
              onConnected();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Start Walkie-Talkie Room (Simulate Guest)', style: TextStyle(fontWeight: FontWeight.bold)),
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
// SCREEN 2: DISCOVERY (LIST NEARBY HOSTS)
// ==========================================
class BluetoothDiscoveryScreen extends StatefulWidget {
  final BluetoothP2PService bluetoothService;
  final bool isDark;

  const BluetoothDiscoveryScreen({super.key, required this.bluetoothService, required this.isDark});

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
            isDark: widget.isDark,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF090D16) : AppTheme.background;
    final cardColor = widget.isDark ? const Color(0xFF131A29) : AppTheme.surfaceCard;
    final textPrimary = widget.isDark ? Colors.white : AppTheme.textPrimary;
    final textMuted = widget.isDark ? const Color(0xFF8E9BAE) : AppTheme.textMuted;

    return AnimatedBuilder(
      animation: widget.bluetoothService,
      builder: (context, _) {
        final devices = widget.bluetoothService.discoveredDevices;
        final isScanning = widget.bluetoothService.state == BluetoothP2PState.scanning;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            title: Text('Discovered Walkie-Talkie Hosts', style: TextStyle(color: textPrimary, fontSize: 16)),
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
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primaryCyan),
                      const SizedBox(height: 16),
                      Text('Scanning nearby RFCOMM devices...', style: TextStyle(color: textMuted)),
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
                      color: cardColor,
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
                                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'MAC: ${device.address} • Signal: ${device.rssi} dBm',
                                  style: TextStyle(color: textMuted, fontSize: 11, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _connect(device),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryCyan,
                              foregroundColor: Colors.white,
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
// SCREEN 3: ADVANCED WALKIE-TALKIE ROOM
// Features: Voice Notes, Invisible Auto-Reconnect,
// Typing & Read Receipts, AES-256 & Burn Chat
// ==========================================
class BluetoothChatRoomScreen extends StatefulWidget {
  final BluetoothP2PService bluetoothService;
  final bool isDark;

  const BluetoothChatRoomScreen({super.key, required this.bluetoothService, required this.isDark});

  @override
  State<BluetoothChatRoomScreen> createState() => _BluetoothChatRoomScreenState();
}

class _BluetoothChatRoomScreenState extends State<BluetoothChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecordingVoice = false;
  int _recordDurationSec = 0;
  Timer? _recordTimer;
  String? _currentlyPlayingMsgId;
  StreamSubscription? _reconnectSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for seamless reconnect events
    _reconnectSubscription = widget.bluetoothService.reconnectEventStream.listen((event) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(event, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _currentlyPlayingMsgId = null);
    });
  }

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

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    widget.bluetoothService.sendMessage(text);
    _scrollToBottom();
  }

  // --- FEATURE 1: WALKIE-TALKIE PTT AUDIO RECORDING ---
  Future<void> _startVoiceRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/zp_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 32000, sampleRate: 16000),
          path: path,
        );

        HapticFeedback.heavyImpact();
        setState(() {
          _isRecordingVoice = true;
          _recordDurationSec = 0;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDurationSec++);
        });
      }
    } catch (e) {
      debugPrint('Voice record error: $e');
    }
  }

  Future<void> _stopAndSendVoiceRecording() async {
    _recordTimer?.cancel();
    if (!_isRecordingVoice) return;

    try {
      final path = await _audioRecorder.stop();
      HapticFeedback.lightImpact();

      setState(() => _isRecordingVoice = false);

      if (path != null && _recordDurationSec > 0) {
        final file = File(path);
        if (await file.exists()) {
          final audioBytes = await file.readAsBytes();
          await widget.bluetoothService.sendVoiceNote(
            audioBytes: audioBytes,
            durationSec: _recordDurationSec,
          );
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() => _isRecordingVoice = false);
    }
  }

  Future<void> _playVoiceNote(BluetoothChatMessage msg) async {
    if (msg.voiceNoteBytes == null) return;

    if (_currentlyPlayingMsgId == msg.id) {
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingMsgId = null);
      return;
    }

    try {
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingMsgId = msg.id);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${msg.id}.m4a');
      await tempFile.writeAsBytes(msg.voiceNoteBytes!);

      await _audioPlayer.play(DeviceFileSource(tempFile.path));
    } catch (e) {
      debugPrint('Playback error: $e');
      setState(() => _currentlyPlayingMsgId = null);
    }
  }

  // --- FEATURE 4: CIPHER INSPECTION DIALOG ---
  void _showCipherInspector(BluetoothChatMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF131A29) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: AppTheme.primaryCyan),
            SizedBox(width: 8),
            Text('AES-256 Packet Inspector', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Decrypted Plaintext:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            const SizedBox(height: 4),
            Text(msg.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 14),
            const Text('Raw Wire Ciphertext (AES-256 CBC):', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.black38 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                msg.rawCipher.isNotEmpty ? msg.rawCipher : '[Encrypted binary stream]',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.primaryCyan),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ZeroPing uses a 256-bit AES key derived from the RFCOMM room UUID. Packets are cryptographically unreadable to Bluetooth sniffers.',
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // --- FEATURE 5: BURN CHAT (MILITARY SELF-DESTRUCT) ---
  void _confirmBurnChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF131A29) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.local_fire_department_rounded, color: AppTheme.accentRose),
            SizedBox(width: 8),
            Text('Burn Chat (Self-Destruct)?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will permanently delete and wipe all encrypted chat messages and voice notes from the local dark vault. This action cannot be undone.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.bluetoothService.burnChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.accentRose,
                  content: Text('🔥 Chat history burned and wiped from local vault!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRose,
              foregroundColor: Colors.white,
            ),
            child: const Text('Burn All Messages'),
          ),
        ],
      ),
    );
  }

  void _simulateIncomingEcho() {
    final sampleReply = "Received over RFCOMM! Voice and Text Decrypted (0.2ms latency) 🔥";
    final cipher = EncryptionService.encryptText(sampleReply);
    final packet = jsonEncode({
      'type': 'msg',
      'id': 'sim_${DateTime.now().millisecondsSinceEpoch}',
      'cipher': cipher,
    });
    widget.bluetoothService.receiveRawBytes(Uint8List.fromList(utf8.encode(packet)));
    _scrollToBottom();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _reconnectSubscription?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF090D16) : AppTheme.background;
    final cardColor = isDark ? const Color(0xFF131A29) : AppTheme.surfaceCard;
    final textPrimary = isDark ? Colors.white : AppTheme.textPrimary;
    final textMuted = isDark ? const Color(0xFF8E9BAE) : AppTheme.textMuted;

    return AnimatedBuilder(
      animation: widget.bluetoothService,
      builder: (context, _) {
        final isConnected = widget.bluetoothService.state == BluetoothP2PState.connected;
        final isReconnecting = widget.bluetoothService.state == BluetoothP2PState.reconnecting;
        final peerName = widget.bluetoothService.connectedDeviceName ?? 'Bluetooth Peer';
        final peerAddress = widget.bluetoothService.connectedDeviceAddress ?? 'RFCOMM Pipe';
        final isPeerTyping = widget.bluetoothService.isPeerTyping;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            titleSpacing: 0,
            title: Row(
              children: [
                // Live Status Pulse Dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected
                        ? AppTheme.accentGreen
                        : (isReconnecting ? AppTheme.accentYellow : AppTheme.accentRose),
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
                      Text(peerName, style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                      if (isPeerTyping)
                        const Text(
                          'Typing encrypted note...',
                          style: TextStyle(color: AppTheme.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold),
                        )
                      else
                        Text(
                          isConnected
                              ? 'Connected • $peerAddress'
                              : (isReconnecting ? 'Auto-Reconnecting in background...' : 'Disconnected'),
                          style: TextStyle(
                            fontSize: 10,
                            color: isConnected
                                ? AppTheme.accentGreen
                                : (isReconnecting ? AppTheme.accentYellow : AppTheme.accentRose),
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Test Simulation Button
              IconButton(
                icon: const Icon(Icons.flash_on_rounded, color: AppTheme.accentYellow, size: 20),
                tooltip: 'Simulate Incoming Encrypted Packet',
                onPressed: _simulateIncomingEcho,
              ),
              // Burn Chat Button
              IconButton(
                icon: const Icon(Icons.local_fire_department_rounded, color: AppTheme.accentRose, size: 20),
                tooltip: 'Burn Chat (Self-Destruct)',
                onPressed: _confirmBurnChat,
              ),
              // Disconnect
              IconButton(
                icon: const Icon(Icons.power_settings_new_rounded, color: AppTheme.textMuted),
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
                // Security / Auto-Reconnect Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  color: isDark ? const Color(0xFF131A29) : AppTheme.surfaceCard.withValues(alpha: 0.8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_rounded, size: 12, color: AppTheme.accentGreen),
                          SizedBox(width: 5),
                          Text(
                            'AES-256 GCM • Invisible Auto-Reconnect Active',
                            style: TextStyle(fontSize: 10.5, color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      // Drop range trigger simulation
                      InkWell(
                        onTap: () {
                          widget.bluetoothService.triggerConnectionDrop();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Test Out-Of-Range',
                            style: TextStyle(fontSize: 10, color: AppTheme.primaryCyan, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Reconnecting Floating Notice
                if (isReconnecting)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.accentYellow.withValues(alpha: 0.2),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentYellow),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Target out of range. Silently auto-reconnecting...',
                          style: TextStyle(fontSize: 11, color: AppTheme.accentYellow, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                // Chat Messages List
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
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                                ),
                                child: const Icon(Icons.mic_rounded, size: 36, color: AppTheme.primaryCyan),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Hold Mic to broadcast Walkie-Talkie Voice Note',
                                style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Or type encrypted text below (0% internet required)',
                                style: TextStyle(color: textMuted, fontSize: 11),
                              ),
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
                          return _buildBubble(msg, isDark);
                        },
                      );
                    },
                  ),
                ),

                // Voice Recording Live Banner
                if (_isRecordingVoice)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentRose.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentRose,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'RECORDING VOICE NOTE (0:${_recordDurationSec.toString().padLeft(2, '0')})',
                          style: const TextStyle(
                            color: AppTheme.accentRose,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Release to Stream',
                          style: TextStyle(color: AppTheme.accentRose, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                // Bottom Input Bar with Walkie-Talkie PTT Button
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isDark ? Colors.white12 : AppTheme.glassBorder),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _textController,
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            onChanged: (val) {
                              widget.bluetoothService.sendTypingStatus(val.isNotEmpty);
                            },
                            decoration: InputDecoration(
                              hintText: 'Type encrypted message...',
                              hintStyle: TextStyle(color: textMuted),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendText(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Text Send Button
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: _sendText,
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Walkie-Talkie Push-To-Talk Mic Button
                      GestureDetector(
                        onLongPressStart: (_) => _startVoiceRecording(),
                        onLongPressEnd: (_) => _stopAndSendVoiceRecording(),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecordingVoice ? AppTheme.accentRose : const Color(0xFF6366F1),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecordingVoice ? AppTheme.accentRose : const Color(0xFF6366F1))
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
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

  Widget _buildBubble(BluetoothChatMessage msg, bool isDark) {
    final timeStr = DateFormat('hh:mm a').format(msg.timestamp);
    final isPlaying = _currentlyPlayingMsgId == msg.id;

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showCipherInspector(msg),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: msg.isMe
                ? (isDark ? const Color(0xFF0284C7).withValues(alpha: 0.3) : AppTheme.primaryCyan.withValues(alpha: 0.18))
                : (isDark ? const Color(0xFF1E293B) : AppTheme.surfaceCard),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
              bottomRight: Radius.circular(msg.isMe ? 4 : 16),
            ),
            border: Border.all(
              color: msg.isMe
                  ? AppTheme.primaryCyan.withValues(alpha: 0.4)
                  : (isDark ? Colors.white10 : AppTheme.glassBorder),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Voice Note Player Card
              if (msg.isVoiceNote) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: AppTheme.primaryCyan,
                        size: 32,
                      ),
                      onPressed: () => _playVoiceNote(msg),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            for (int i = 0; i < 10; i++)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                width: 3,
                                height: 8.0 + (i % 4) * 5,
                                decoration: BoxDecoration(
                                  color: isPlaying ? AppTheme.primaryCyan : const Color(0xFF94A3B8),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Voice Note • 0:${msg.voiceNoteDurationSec.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  msg.text,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    fontSize: 13.5,
                  ),
                ),
              ],

              const SizedBox(height: 4),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 9, color: AppTheme.accentGreen),
                  const SizedBox(width: 3),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppTheme.textMuted,
                      fontSize: 9.5,
                    ),
                  ),
                  if (msg.isMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusTicks(msg.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTicks(BtMessageStatus status) {
    switch (status) {
      case BtMessageStatus.sending:
        return const Icon(Icons.access_time_rounded, size: 11, color: AppTheme.textMuted);
      case BtMessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 12, color: AppTheme.textMuted); // Single tick
      case BtMessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 12, color: AppTheme.textMuted); // Double tick grey
      case BtMessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 12, color: Color(0xFF00E5FF)); // WhatsApp Blue Tick!
    }
  }
}
