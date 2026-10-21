import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../services/discovery_service.dart';
import '../services/p2p_socket_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class FilesScreen extends StatefulWidget {
  final DiscoveryService discoveryService;
  final P2PSocketService socketService;
  final VoidCallback onNavigateToTransfers;

  const FilesScreen({
    super.key,
    required this.discoveryService,
    required this.socketService,
    required this.onNavigateToTransfers,
  });

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadVaultFiles();
  }

  Future<void> _loadVaultFiles() async {
    setState(() => _isLoading = true);
    try {
      final dir = await StorageService.getDownloadsDirectoryPath();
      if (await dir.exists()) {
        final list = dir.listSync();
        list.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        setState(() {
          _files = list.whereType<File>().toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _files = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<FileSystemEntity> get _filteredFiles {
    if (_selectedCategory == 'All') return _files;
    return _files.where((f) {
      final ext = f.path.split('.').last.toLowerCase();
      if (_selectedCategory == 'Videos') return ['mp4', 'mkv', 'avi', 'mov', 'webm'].contains(ext);
      if (_selectedCategory == 'Images') return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
      if (_selectedCategory == 'Documents') return ['pdf', 'doc', 'docx', 'txt', 'csv', 'xlsx'].contains(ext);
      if (_selectedCategory == 'APKs') return ['apk', 'aab', 'xapk'].contains(ext);
      if (_selectedCategory == 'Audio') return ['mp3', 'wav', 'aac', 'flac', 'm4a'].contains(ext);
      return true;
    }).toList();
  }

  void _sendFileToPeer(File file) {
    final peers = widget.discoveryService.peers;
    if (peers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.surfaceCard,
          content: Text('No nearby peers detected on Radar. Start scan first!'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        color: AppTheme.surfaceCard.withOpacity(0.95),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Recipient Peer',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...peers.map((peer) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryCyan,
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  title: Text(peer.name, style: const TextStyle(color: AppTheme.textPrimary)),
                  subtitle: Text('${peer.ip} • ${peer.deviceType.name}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  trailing: const Icon(Icons.send_rounded, color: AppTheme.primaryCyan),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final task = await widget.socketService.offerFile(
                      peerIp: peer.ip,
                      peerName: peer.name,
                      filePath: file.path,
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  IconData _getFileIcon(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['mp4', 'mkv', 'avi', 'mov'].contains(ext)) return Icons.video_file_rounded;
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) return Icons.image_rounded;
    if (['mp3', 'wav', 'aac'].contains(ext)) return Icons.audio_file_rounded;
    if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) return Icons.description_rounded;
    if (['zip', 'rar', 'tar', 'apk'].contains(ext)) return Icons.archive_rounded;
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZeroPing Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryCyan),
            onPressed: _loadVaultFiles,
            tooltip: 'Refresh Vault',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Selector Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Videos', 'Images', 'Documents', 'APKs', 'Audio'].map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryCyan.withValues(alpha: 0.25),
                    backgroundColor: AppTheme.surfaceCard,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryCyan : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryCyan : AppTheme.glassBorder,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = category);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // File List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryCyan))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open_rounded, size: 56, color: AppTheme.textMuted.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'No $_selectedCategory files found in ZeroPing Vault',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final file = filtered[index] as File;
                          final stat = file.statSync();
                          final fileName = file.path.split(Platform.pathSeparator).last;

                          return GlassContainer(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            borderRadius: 16,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryCyan.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_getFileIcon(file.path), color: AppTheme.primaryCyan, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_formatBytes(stat.size)} • ${stat.modified.day}/${stat.modified.month}/${stat.modified.year}',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.file_open_rounded, color: AppTheme.accentGreen, size: 20),
                                  tooltip: 'Open with OS',
                                  onPressed: () => OpenFilex.open(file.path),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_rounded, color: AppTheme.primaryCyan, size: 20),
                                  tooltip: 'Send to Peer',
                                  onPressed: () => _sendFileToPeer(file),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
