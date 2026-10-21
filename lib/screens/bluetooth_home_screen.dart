import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../services/bluetooth_p2p_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/radar_scanner.dart';

// ==========================================
// SCREEN 1: BLUETOOTH HOME (HOST / JOIN)
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
          'Bluetooth Tactical Suite',
          style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isStealthDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppTheme.primaryCyan,
              size: 20,
            ),
            tooltip: _isStealthDark ? 'Light Theme' : 'Stealth Dark Mode',
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
                                'Stealth Walkie-Talkie & Mini-Games Ready',
                                style: TextStyle(color: textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Ghost Messages • 10KB Meme Chunks • Panic Disguise',
                                style: TextStyle(color: textMuted, fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Option 1: HOST CHAT
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
                                'Host Walkie-Talkie Room',
                                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Server Mode • Encrypted RFCOMM Pipe',
                                style: TextStyle(color: Colors.black87, fontSize: 11.5, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Option 2: JOIN CHAT
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
                                'Join Walkie-Talkie Room',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Scan nearby RFCOMM hosts & connect',
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

// Host Waiting Sheet
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

// Discovery Screen
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
// Features:
// 1. Voice Notes (PTT)
// 2. Invisible Auto-Reconnect
// 3. Mini Games (In-Chat Tic-Tac-Toe)
// 4. Ghost Messages (Self-Destructing Text)
// 5. Image/Meme Chunking (10KB sequential packets)
// 6. Stealth Panic Mode (Fake Calculator Disguise)
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

  // Feature 2: Stealth Panic Mode
  bool _isStealthDisguised = false;

  // Feature 4: Ghost Message Timer (0 = normal, 5, 10, 30 seconds)
  int _ghostTimerSec = 0;
  final Map<String, int> _activeGhostCountdowns = {};
  final Map<String, Timer> _activeGhostTimers = {};

  @override
  void initState() {
    super.initState();
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
    if (_ghostTimerSec > 0) {
      widget.bluetoothService.sendGhostMessage(text, _ghostTimerSec);
    } else {
      widget.bluetoothService.sendMessage(text);
    }
    _scrollToBottom();
  }

  // --- FEATURE 1: PTT VOICE RECORDING ---
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

  // --- FEATURE 3: IN-CHAT MINI-GAME (TIC-TAC-TOE) ---
  void _startOrResetGame() {
    final gameId = 'game_${DateTime.now().millisecondsSinceEpoch}';
    widget.bluetoothService.sendGameMove(
      gameId: gameId,
      board: List.filled(9, 0),
      turn: 'X',
      winner: null,
    );
    _scrollToBottom();
  }

  void _handleGameCellTap(BluetoothChatMessage gameMsg, int index) {
    if (gameMsg.gameWinner != null) return;
    if (gameMsg.gameState[index] != 0) return;

    // Clone board
    final board = List<int>.from(gameMsg.gameState);
    final isX = gameMsg.gameTurn == 'X';
    board[index] = isX ? 1 : 2;

    // Check winner
    String? winner = _checkTicTacToeWinner(board);
    final nextTurn = isX ? 'O' : 'X';

    HapticFeedback.lightImpact();
    widget.bluetoothService.sendGameMove(
      gameId: gameMsg.id,
      board: board,
      turn: nextTurn,
      winner: winner,
    );
  }

  String? _checkTicTacToeWinner(List<int> b) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6],             // Diagonals
    ];
    for (final line in lines) {
      if (b[line[0]] != 0 && b[line[0]] == b[line[1]] && b[line[1]] == b[line[2]]) {
        return b[line[0]] == 1 ? 'X' : 'O';
      }
    }
    if (!b.contains(0)) return 'Draw';
    return null;
  }

  // --- FEATURE 4: GHOST MESSAGES TAP & COUNTDOWN ---
  void _revealGhostMessage(BluetoothChatMessage msg) {
    if (msg.isGhostBurned) return;
    if (_activeGhostCountdowns.containsKey(msg.id)) return;

    HapticFeedback.mediumImpact();
    setState(() {
      msg.isGhostRevealed = true;
      _activeGhostCountdowns[msg.id] = msg.ghostDurationSec;
    });

    _activeGhostTimers[msg.id] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final current = _activeGhostCountdowns[msg.id] ?? 0;
      if (current <= 1) {
        timer.cancel();
        _activeGhostTimers.remove(msg.id);
        _activeGhostCountdowns.remove(msg.id);
        HapticFeedback.heavyImpact();
        widget.bluetoothService.burnGhostMessage(msg.id);
      } else {
        setState(() {
          _activeGhostCountdowns[msg.id] = current - 1;
        });
      }
    });
  }

  // --- FEATURE 5: IMAGE / MEME CHUNKING ---
  Future<void> _pickAndSendMeme() async {
    try {
      final picked = await FilePicker.pickFiles(type: FileType.image);
      if (picked.isNotEmpty && picked.first.path != null) {
        final file = File(picked.first.path!);
        final bytes = await file.readAsBytes();
        await widget.bluetoothService.sendImageInChunks(imageBytes: bytes);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _sendDemoMemeChunk() async {
    // Generate a lightweight 64x64 procedural gradient image buffer for demo chunk testing
    final demoBytes = _generateDemoMemeBytes();
    await widget.bluetoothService.sendImageInChunks(imageBytes: demoBytes);
    _scrollToBottom();
  }

  Uint8List _generateDemoMemeBytes() {
    // Small valid 1x1 PNG bytes or test chunk stream
    const base64Png =
        'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAABJmlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiLz4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PsmQ9wIAAABGSURBVHja7c4xAQAwEAOh+df+pTsHAqYhYCQCRiJgJAJGImAkAkYiYCQCRiJgJAJGImAkAkYiYCQCRiJgJAJGImAkAkb6B3bKAl92lU1RAAAAAElFTkSuQmCC';
    return base64Decode(base64Png);
  }

  // --- FEATURE 2: PANIC GESTURE DISGUISE ---
  void _triggerStealthDisguise() {
    HapticFeedback.heavyImpact();
    setState(() => _isStealthDisguised = true);
  }

  void _exitStealthDisguise() {
    HapticFeedback.lightImpact();
    setState(() => _isStealthDisguised = false);
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _reconnectSubscription?.cancel();
    for (final t in _activeGhostTimers.values) {
      t.cancel();
    }
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IF PANIC GESTURE TRIGGERED: Render realistic functional fake calculator!
    if (_isStealthDisguised) {
      return _FakeCalculatorDisguise(onUnlock: _exitStealthDisguise);
    }

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
        final peerName = widget.bluetoothService.connectedDeviceName ?? 'Tactical Peer';
        final peerAddress = widget.bluetoothService.connectedDeviceAddress ?? 'RFCOMM Pipe';
        final isPeerTyping = widget.bluetoothService.isPeerTyping;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            titleSpacing: 0,
            title: GestureDetector(
              onDoubleTap: _triggerStealthDisguise, // Double tap app bar for Panic Disguise
              child: Row(
                children: [
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
                                : (isReconnecting ? 'Auto-Reconnecting...' : 'Disconnected'),
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
            ),
            actions: [
              // Feature 2: Stealth Panic Mode Icon
              IconButton(
                icon: const Icon(Icons.visibility_off_rounded, color: AppTheme.accentYellow, size: 20),
                tooltip: 'Panic Disguise (Fake Calculator)',
                onPressed: _triggerStealthDisguise,
              ),
              // Feature 3: Start In-Chat Mini-Game
              IconButton(
                icon: const Icon(Icons.sports_esports_rounded, color: AppTheme.primaryCyan, size: 22),
                tooltip: 'Start Tic-Tac-Toe Game',
                onPressed: _startOrResetGame,
              ),
              // Burn Chat
              IconButton(
                icon: const Icon(Icons.local_fire_department_rounded, color: AppTheme.accentRose, size: 20),
                tooltip: 'Burn Chat (Self-Destruct)',
                onPressed: () {
                  widget.bluetoothService.burnChat();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppTheme.accentRose,
                      content: Text('🔥 Chat history burned and wiped from local vault!'),
                    ),
                  );
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
                  color: isDark ? const Color(0xFF131A29) : AppTheme.surfaceCard.withValues(alpha: 0.8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_rounded, size: 12, color: AppTheme.accentGreen),
                          SizedBox(width: 5),
                          Text(
                            'AES-256 E2E • Ghost Mode & Chunks Active',
                            style: TextStyle(fontSize: 10.5, color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      // Drop range simulation
                      InkWell(
                        onTap: () => widget.bluetoothService.triggerConnectionDrop(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            'Simulate Drop',
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
                          'Invisible Auto-Reconnect active... Pinging MAC',
                          style: TextStyle(fontSize: 11, color: AppTheme.accentYellow, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                // Messages List
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
                                child: const Icon(Icons.flash_on_rounded, size: 36, color: AppTheme.primaryCyan),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Zero-Latency Tactical Chat',
                                style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hold Mic to Talk • Send Ghost Messages • Play Mini-Games',
                                style: TextStyle(color: textMuted, fontSize: 11),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.sports_esports_rounded, size: 16),
                                label: const Text('Play Tic-Tac-Toe'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryCyan,
                                  side: const BorderSide(color: AppTheme.primaryCyan),
                                ),
                                onPressed: _startOrResetGame,
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

                // Input Bar with Ghost Toggle, Meme Chunking, and PTT
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Ghost Self-Destruct Timer Toggle
                      IconButton(
                        icon: Icon(
                          _ghostTimerSec > 0 ? Icons.local_fire_department_rounded : Icons.timer_outlined,
                          color: _ghostTimerSec > 0 ? AppTheme.accentRose : textMuted,
                          size: 22,
                        ),
                        tooltip: 'Ghost Mode (${_ghostTimerSec}s)',
                        onPressed: () {
                          setState(() {
                            if (_ghostTimerSec == 0) {
                              _ghostTimerSec = 5;
                            } else if (_ghostTimerSec == 5) {
                              _ghostTimerSec = 10;
                            } else if (_ghostTimerSec == 10) {
                              _ghostTimerSec = 30;
                            } else {
                              _ghostTimerSec = 0;
                            }
                          });
                          HapticFeedback.lightImpact();
                          if (_ghostTimerSec > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(milliseconds: 1200),
                                backgroundColor: AppTheme.accentRose,
                                content: Text('🔥 Ghost Mode: Messages self-destruct in ${_ghostTimerSec}s after reading!'),
                              ),
                            );
                          }
                        },
                      ),

                      // Meme / Image Chunk Picker (Tap: Pick file, Hold: Demo stream)
                      IconButton(
                        icon: Icon(Icons.image_rounded, color: textMuted, size: 22),
                        tooltip: 'Stream Meme (Hold for Demo)',
                        onPressed: _pickAndSendMeme,
                        onLongPress: _sendDemoMemeChunk,
                      ),

                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _ghostTimerSec > 0
                                  ? AppTheme.accentRose.withValues(alpha: 0.7)
                                  : (isDark ? Colors.white12 : AppTheme.glassBorder),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: _textController,
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            onChanged: (val) {
                              widget.bluetoothService.sendTypingStatus(val.isNotEmpty);
                            },
                            decoration: InputDecoration(
                              hintText: _ghostTimerSec > 0
                                  ? 'Type Ghost Secret (${_ghostTimerSec}s)...'
                                  : 'Type encrypted message...',
                              hintStyle: TextStyle(
                                color: _ghostTimerSec > 0 ? AppTheme.accentRose.withValues(alpha: 0.7) : textMuted,
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendText(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Text Send Button
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _ghostTimerSec > 0 ? AppTheme.accentRose : AppTheme.primaryCyan,
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

    // Feature 3: In-Chat Mini-Game (Tic-Tac-Toe Board)
    if (msg.isGame) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A29) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports_esports_rounded, color: AppTheme.primaryCyan, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 3x3 Tic Tac Toe Grid
              SizedBox(
                width: 180,
                height: 180,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: 9,
                  itemBuilder: (ctx, i) {
                    final val = msg.gameState[i];
                    return GestureDetector(
                      onTap: () => _handleGameCellTap(msg, i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: val == 1
                                ? AppTheme.primaryCyan
                                : (val == 2 ? const Color(0xFF8B5CF6) : Colors.transparent),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            val == 1 ? 'X' : (val == 2 ? 'O' : ''),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: val == 1 ? AppTheme.primaryCyan : const Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                msg.gameWinner != null
                    ? 'Game Over • Tap Board to Restart'
                    : 'Current Turn: ${msg.gameTurn}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // Feature 5: Image / Meme Chunk Bubble
    if (msg.isImage) {
      return Align(
        alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: msg.imageBytes != null
                    ? Image.memory(
                        msg.imageBytes!,
                        fit: BoxFit.cover,
                        height: 180,
                        width: double.infinity,
                      )
                    : Container(
                        height: 120,
                        color: Colors.black12,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: AppTheme.primaryCyan),
                              const SizedBox(height: 8),
                              Text(msg.text, style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '10KB Chunk Protocol',
                    style: TextStyle(fontSize: 10, color: AppTheme.primaryCyan, fontWeight: FontWeight.bold),
                  ),
                  Text(timeStr, style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Feature 4: Ghost Message Bubble
    if (msg.isGhost) {
      final remaining = _activeGhostCountdowns[msg.id];
      final isRevealed = msg.isGhostRevealed && remaining != null;

      return Align(
        alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            if (!msg.isMe && !isRevealed) {
              _revealGhostMessage(msg);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3B1D28) : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentRose.withValues(alpha: 0.6), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 16, color: AppTheme.accentRose),
                    const SizedBox(width: 6),
                    Text(
                      isRevealed
                          ? '🔥 Self-Destructing in ${remaining}s'
                          : (msg.isMe ? '👻 Ghost Message (${msg.ghostDurationSec}s)' : '👻 Ghost Secret (Tap to Read)'),
                      style: const TextStyle(
                        color: AppTheme.accentRose,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (!msg.isMe && !isRevealed)
                      ? '•••••••••••••••••••••••••'
                      : msg.text,
                  style: TextStyle(
                    color: (!msg.isMe && !isRevealed) ? AppTheme.textMuted : (isDark ? Colors.white : AppTheme.textPrimary),
                    fontSize: 14,
                    fontWeight: isRevealed ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: TextStyle(color: isDark ? Colors.white38 : AppTheme.textMuted, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default Regular Text & Voice Note Bubble
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
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
    );
  }

  Widget _buildStatusTicks(BtMessageStatus status) {
    switch (status) {
      case BtMessageStatus.sending:
        return const Icon(Icons.access_time_rounded, size: 11, color: AppTheme.textMuted);
      case BtMessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 12, color: AppTheme.textMuted);
      case BtMessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 12, color: AppTheme.textMuted);
      case BtMessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 12, color: Color(0xFF00E5FF));
    }
  }
}

// ==========================================
// FEATURE 2: FAKE FUNCTIONAL CALCULATOR DISGUISE
// (The Panic Gesture Screen)
// ==========================================
class _FakeCalculatorDisguise extends StatefulWidget {
  final VoidCallback onUnlock;

  const _FakeCalculatorDisguise({required this.onUnlock});

  @override
  State<_FakeCalculatorDisguise> createState() => _FakeCalculatorDisguiseState();
}

class _FakeCalculatorDisguiseState extends State<_FakeCalculatorDisguise> {
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  void _onDigit(String digit) {
    setState(() {
      if (_display == '0' || _shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        _display += digit;
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      _firstOperand = double.tryParse(_display);
      _operator = op;
      _shouldResetDisplay = true;
    });
  }

  void _onEqual() {
    if (_firstOperand == null || _operator == null) return;
    final secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        result = secondOperand != 0 ? _firstOperand! / secondOperand : 0;
        break;
    }

    setState(() {
      _display = result.toString().endsWith('.0')
          ? result.toInt().toString()
          : result.toStringAsFixed(2);
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = true;
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Secret Unmask Banner: Double tap to return to chat!
            GestureDetector(
              onDoubleTap: widget.onUnlock,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.transparent,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Calculator', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    Text('Double-tap top to return', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Real calculator display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),

            // Calculator Keyboard Grid
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _calcRow(['C', '+/-', '%', '÷'], [Colors.grey[700]!, Colors.grey[700]!, Colors.grey[700]!, Colors.orange]),
                  _calcRow(['7', '8', '9', '×'], [Colors.grey[900]!, Colors.grey[900]!, Colors.grey[900]!, Colors.orange]),
                  _calcRow(['4', '5', '6', '-'], [Colors.grey[900]!, Colors.grey[900]!, Colors.grey[900]!, Colors.orange]),
                  _calcRow(['1', '2', '3', '+'], [Colors.grey[900]!, Colors.grey[900]!, Colors.grey[900]!, Colors.orange]),
                  _calcRow(['0', '.', '='], [Colors.grey[900]!, Colors.grey[900]!, Colors.orange], isZeroRow: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(List<String> labels, List<Color> colors, {bool isZeroRow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: labels.map((lbl) {
          final color = colors[labels.indexOf(lbl)];
          final isZero = isZeroRow && lbl == '0';

          return GestureDetector(
            onLongPress: lbl == '=' ? widget.onUnlock : null, // Long-press = button unlocks
            onTap: () {
              HapticFeedback.lightImpact();
              if (lbl == 'C') {
                _onClear();
              } else if (lbl == '=') {
                _onEqual();
              } else if (['+', '-', '×', '÷'].contains(lbl)) {
                _onOperator(lbl);
              } else if (lbl != '+/-' && lbl != '%') {
                _onDigit(lbl);
              }
            },
            child: Container(
              width: isZero ? 160 : 72,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Center(
                child: Text(
                  lbl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
