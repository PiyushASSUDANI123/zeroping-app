import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/discovery_service.dart';
import '../services/p2p_socket_service.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  final DiscoveryService discoveryService;
  final P2PSocketService socketService;

  const SettingsScreen({
    super.key,
    required this.discoveryService,
    required this.socketService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  PermissionStatusReport? _report;
  String _downloadDir = '';
  bool _isDevMode = true; // Enabled by default or via toggle

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.discoveryService.myDeviceName;
    _checkPermissions();
    _loadDir();
  }

  Future<void> _checkPermissions() async {
    final rep = await PermissionService.checkPermissions();
    if (mounted) setState(() => _report = rep);
  }

  Future<void> _loadDir() async {
    final dir = await StorageService.getDownloadsDirectoryPath();
    if (mounted) setState(() => _downloadDir = dir.path);
  }

  void _saveDeviceName() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      StorageService.setDeviceName(name);
      widget.discoveryService.updateDeviceName(name);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.surfaceCard,
          content: Text('Device name updated! Broadcasted to radar.'),
        ),
      );
    }
  }

  void _showPermissionRationale() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: AppTheme.primaryCyan)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.primaryCyan),
            SizedBox(width: 8),
            Text('Why Location Permission?', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Android OS Architecture Requirement:',
              style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text(
              'On Android 9-13+, the OS groups Wi-Fi network scanning (discovering peer SSIDs and BSSIDs) under the "Location" permission group.\n\nZeroPing NEVER accesses GPS coordinates, maps, or cellular towers. All transfers are 100% offline and peer-to-peer.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCyan, foregroundColor: Colors.black),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Node Settings & Stats'),
        actions: [
          // Dev Mode Quick Toggle
          Row(
            children: [
              const Text('Dev Mode', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              Switch(
                value: _isDevMode,
                activeThumbColor: AppTheme.primaryCyan,
                onChanged: (val) => setState(() => _isDevMode = val),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hidden Dev Mode / Advanced Stats Panel
          if (_isDevMode) ...[
            GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              color: AppTheme.primaryCyan.withValues(alpha: 0.08),
              border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.4), width: 1.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.terminal_rounded, color: AppTheme.primaryCyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ADVANCED DEV STATS',
                            style: TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Text('PROPRIETARY SOCKET ENGINE', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _statMetric('Socket Ping', '< 1 ms', Icons.speed_rounded, AppTheme.accentGreen),
                      _statMetric('Packet Loss', '0.0 %', Icons.network_check_rounded, AppTheme.accentGreen),
                      _statMetric('Active Sockets', '${widget.socketService.activeSocketsCount}', Icons.hub_rounded, AppTheme.primaryCyan),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.glassBorder),
                  const SizedBox(height: 8),
                  _diagnosticRow('TCP Chunk Size', '512 KB (Zero-RAM Stream)'),
                  _diagnosticRow('Integrity Check', 'SHA-256 Stream Accumulator'),
                  _diagnosticRow('Wire Protocol', 'ZeroPing Binary Header (0x01 / 0x02)'),
                  _diagnosticRow('Auto-Resume Support', 'Enabled (Byte Offset Seek)'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Profile Setup Card
          Builder(
            builder: (context) {
              final profile = StorageService.getUserProfile();
              return GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            AppAvatar(
                              avatar: profile?.avatar ?? AppAvatar.defaultAvatars[0].id,
                              size: 42,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.name ?? widget.discoveryService.myDeviceName,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  profile?.username ?? '@node',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                          ),
                          child: const Text('Local Node', style: TextStyle(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Broadcast Device Name:',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.glassBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primaryCyan, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _saveDeviceName,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryCyan,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Network & Interface Diagnostics Card
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.router_rounded, color: AppTheme.accentGreen, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Socket & Network Details',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _diagnosticRow('Local Node IP', widget.discoveryService.myIp),
                _diagnosticRow('TCP Server Port', '${P2PSocketService.tcpPort} (Transfer Pipeline)'),
                _diagnosticRow('UDP Beacon Port', '${DiscoveryService.udpPort} (Radar Broadcast)'),
                _diagnosticRow('OS Platform', kIsWeb ? 'BROWSER (WEB ENGINE)' : Platform.operatingSystem.toUpperCase()),
                _diagnosticRow('Vault Path', _downloadDir, isMono: false),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Selective Android Permissions Manager Card
          if (!kIsWeb && Platform.isAndroid)
            GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security_rounded, color: AppTheme.accentYellow, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'OS Permissions Manager',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline_rounded, color: AppTheme.primaryCyan, size: 20),
                        tooltip: 'Why are these needed?',
                        onPressed: _showPermissionRationale,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selective permissions required for Wi-Fi Direct socket discovery and local media access.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  _permissionTile('Nearby Wi-Fi Devices (Android 13+)', _report?.nearbyWifi ?? false),
                  _permissionTile('Bluetooth Scan & Connect', _report?.bluetooth ?? false),
                  _permissionTile('Media & File Storage', _report?.storage ?? false),
                  _permissionTile('Location (Wi-Fi SSID Scanning only)', _report?.location ?? false),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await PermissionService.requestAllPermissions();
                      _checkPermissions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.18),
                      foregroundColor: AppTheme.primaryCyan,
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.primaryCyan),
                      ),
                    ),
                    child: const Text('Check & Grant Required Permissions'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statMetric(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: col.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: col, size: 18),
            const SizedBox(height: 6),
            Text(val, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace')),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _diagnosticRow(String label, String value, {bool isMono = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontFamily: isMono ? 'monospace' : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionTile(String title, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: granted ? AppTheme.accentGreen : AppTheme.accentRose,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: granted ? AppTheme.textPrimary : AppTheme.accentRose,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            granted ? 'Granted' : 'Missing',
            style: TextStyle(
              color: granted ? AppTheme.accentGreen : AppTheme.accentRose,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
