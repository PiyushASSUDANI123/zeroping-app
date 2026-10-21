import 'dart:io';
import 'package:flutter/material.dart';
import '../services/discovery_service.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  final DiscoveryService discoveryService;

  const SettingsScreen({super.key, required this.discoveryService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  PermissionStatusReport? _report;
  String _downloadDir = '';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Node Settings & Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Device Identity Card
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_rounded, color: AppTheme.primaryCyan, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Device Identity',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'This name will flash on nearby phones and PCs when discovering your node:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.glassBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryCyan),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saveDeviceName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Network Diagnostics Card
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
                      'Socket Diagnostics',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _diagnosticRow('Local IP', widget.discoveryService.myIp),
                _diagnosticRow('TCP Transfer Port', '8990 (Active Server)'),
                _diagnosticRow('UDP Discovery Port', '8888 (Broadcast Listener)'),
                _diagnosticRow('Host Platform', Platform.operatingSystem.toUpperCase()),
                _diagnosticRow('Storage Vault', _downloadDir, isMono: false),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Android Permissions Card (Android 12+ check)
          if (Platform.isAndroid)
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
                            'OS Permissions (Android 12+)',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          await PermissionService.requestAllPermissions();
                          _checkPermissions();
                        },
                        child: const Text('Grant All', style: TextStyle(color: AppTheme.primaryCyan)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _permissionTile('Nearby Wi-Fi Devices', _report?.nearbyWifi ?? false),
                  _permissionTile('Bluetooth Scan & Connect', _report?.bluetooth ?? false),
                  _permissionTile('Media & File Storage', _report?.storage ?? false),
                  _permissionTile('Location (Wi-Fi Scanning)', _report?.location ?? false),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _diagnosticRow(String label, String value, {bool isMono = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
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
                fontSize: 13,
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
