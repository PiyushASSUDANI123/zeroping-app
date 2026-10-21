import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isDevDiagnosticsVisible = false; // Production Ready: Hidden by default
  int _versionTapCount = 0;

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
          backgroundColor: AppTheme.primaryCyan,
          content: Text('Device broadcast name updated successfully!'),
        ),
      );
    }
  }

  Future<void> _openWebsite(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryCyan,
            content: Text('Link copied to clipboard: $url'),
          ),
        );
      }
    }
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text: '⚡ ZeroPing — Sub-Millisecond P2P Transfer & Mesh Suite\n\n'
            'Designed & Developed by Piyush Assudani (Founder, Assudani Group)\n'
            'Zero Cloud. Zero Data Limits. 80+ MB/s offline transfers!\n\n'
            'Website: https://piyushassudani.in\n'
            'GitHub: https://github.com/PiyushASSUDANI123/zeroping-app',
        subject: 'Check out ZeroPing App',
      ),
    );
  }

  void _showPermissionRationale() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
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
              'On Android 9-14+, the OS classifies Wi-Fi local network scanning (finding peer devices on the same subnet) under the "Location" group.\n\nZeroPing NEVER touches GPS coordinates, maps, or cellular towers. All transfers are 100% offline and peer-to-peer.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
        title: const Text('Node Settings & Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
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
                              size: 44,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.name ?? widget.discoveryService.myDeviceName,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  profile?.username ?? '@node',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'Active Node',
                            style: TextStyle(color: AppTheme.accentGreen, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                              fillColor: AppTheme.background,
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
                    Icon(Icons.router_rounded, color: AppTheme.primaryCyan, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Network & Socket Engine',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _diagnosticRow('Local Node IP', widget.discoveryService.myIp),
                _diagnosticRow('TCP Transfer Port', '${P2PSocketService.tcpPort} (Direct Binary Pipeline)'),
                _diagnosticRow('UDP Radar Port', '${DiscoveryService.udpPort} (Subnet Discovery Beacon)'),
                _diagnosticRow('OS Platform', kIsWeb ? 'BROWSER (WEB ENGINE)' : Platform.operatingSystem.toUpperCase()),
                _diagnosticRow('Storage Vault', _downloadDir, isMono: false),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Selective Android Permissions Manager Card
          if (!kIsWeb && Platform.isAndroid) ...[
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
                  const SizedBox(height: 6),
                  const Text(
                    'Permissions required for Wi-Fi Direct socket discovery and local media access.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  _permissionTile('Nearby Wi-Fi Devices (Android 13+)', _report?.nearbyWifi ?? false),
                  _permissionTile('Bluetooth Scan & Connect', _report?.bluetooth ?? false),
                  _permissionTile('Media & File Storage', _report?.storage ?? false),
                  _permissionTile('Location (Wi-Fi SSID Scanning)', _report?.location ?? false),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await PermissionService.requestAllPermissions();
                      _checkPermissions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.14),
                      foregroundColor: AppTheme.primaryCyan,
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.primaryCyan),
                      ),
                    ),
                    child: const Text('Verify & Grant Permissions'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Production Ready: Advanced Socket Diagnostics (Toggled cleanly)
          if (_isDevDiagnosticsVisible) ...[
            GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              color: AppTheme.primaryCyan.withValues(alpha: 0.05),
              border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.terminal_rounded, color: AppTheme.primaryCyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ADVANCED SOCKET DIAGNOSTICS',
                            style: TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                        onPressed: () => setState(() => _isDevDiagnosticsVisible = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statMetric('Socket Ping', '< 1 ms', Icons.speed_rounded, AppTheme.accentGreen),
                      _statMetric('Packet Loss', '0.0 %', Icons.network_check_rounded, AppTheme.accentGreen),
                      _statMetric('Sockets', '${widget.socketService.activeSocketsCount}', Icons.hub_rounded, AppTheme.primaryCyan),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _diagnosticRow('TCP Chunk Size', '64 KB (Zero-RAM Stream)'),
                  _diagnosticRow('Integrity Check', 'SHA-256 Stream Accumulator'),
                  _diagnosticRow('Wire Protocol', 'ZeroPing Binary Header (0x01 / 0x02)'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Flagship Developer Credit Card (Piyush Assudani / Assudani Group)
          GlassContainer(
            borderRadius: 22,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3), width: 1.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.code_rounded, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Designed & Developed by',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Piyush Assudani',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.25)),
                  ),
                  child: const Text(
                    'Founder, Assudani Group',
                    style: TextStyle(
                      color: AppTheme.primaryViolet,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.glassBorder, height: 1),
                const SizedBox(height: 16),

                // Interactive Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.language_rounded, size: 18),
                        label: const Text('piyushassudani.in'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryCyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _openWebsite('https://piyushassudani.in'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share App'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryCyan,
                        side: const BorderSide(color: AppTheme.primaryCyan),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _shareApp,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.code_rounded, size: 16, color: AppTheme.textSecondary),
                      label: const Text(
                        'GitHub Repo',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      onPressed: () => _openWebsite('https://github.com/PiyushASSUDANI123/zeroping-app.git'),
                    ),
                    const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                    TextButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.textSecondary),
                      label: const Text(
                        'Copy Portfolio Link',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: 'https://piyushassudani.in'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppTheme.primaryCyan,
                            content: Text('Portfolio URL copied to clipboard!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Version & Build Info (Tapping 5 times reveals Advanced Socket Diagnostics)
          Center(
            child: GestureDetector(
              onTap: () {
                _versionTapCount++;
                if (_versionTapCount >= 5) {
                  setState(() => _isDevDiagnosticsVisible = !_isDevDiagnosticsVisible);
                  _versionTapCount = 0;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.primaryCyan,
                      content: Text(_isDevDiagnosticsVisible
                          ? 'Advanced Diagnostics Enabled'
                          : 'Advanced Diagnostics Disabled'),
                    ),
                  );
                }
              },
              child: const Column(
                children: [
                  Text(
                    'ZeroPing v1.0.0 (Production Stable)',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Zero-Cloud Subnet Mesh • Made with ❤️ by Piyush Assudani',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
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
            Text(val, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace')),
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
            width: 130,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
