import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../services/discovery_service.dart';
import '../services/p2p_socket_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'All',
    'Photos',
    'Videos',
    'Audio',
    'Documents',
    'APKs',
    'Archives',
  ];

  @override
  void initState() {
    super.initState();
    _loadVaultFiles();
  }

  Future<void> _loadVaultFiles() async {
    setState(() => _isLoading = true);
    if (kIsWeb) {
      setState(() {
        _files = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final dir = await StorageService.getDownloadsDirectoryPath();
      if (await dir.exists()) {
        final list = dir.listSync();
        list.sort((a, b) {
          try {
            return b.statSync().modified.compareTo(a.statSync().modified);
          } catch (_) {
            return 0;
          }
        });
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
      debugPrint('Error loading vault: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndImportFile() async {
    try {
      final result = await FilePicker.pickFiles();
      if (result.isNotEmpty) {
        if (!kIsWeb) {
          final vaultDir = await StorageService.getDownloadsDirectoryPath();
          for (final f in result) {
            if (f.path != null) {
              final srcFile = File(f.path!);
              final targetFile = File('${vaultDir.path}/${f.name}');
              if (!await targetFile.exists()) {
                await srcFile.copy(targetFile.path);
              }
            }
          }
          await _loadVaultFiles();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.primaryCyan,
                content: Text('Imported ${result.length} file(s) into ZeroPing Vault!'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentRose,
            content: Text('Import error: $e'),
          ),
        );
      }
    }
  }

  List<FileSystemEntity> get _filteredFiles {
    var list = _files;
    if (_searchQuery.isNotEmpty) {
      list = list.where((f) {
        final name = f.path.split(RegExp(r'[/\\]')).last.toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedCategory == 'All') return list;

    return list.where((f) {
      final ext = f.path.split('.').last.toLowerCase();
      switch (_selectedCategory) {
        case 'Photos':
          return ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'svg', 'heic'].contains(ext);
        case 'Videos':
          return ['mp4', 'mkv', 'avi', 'mov', 'webm', '3gp', 'flv', 'ts'].contains(ext);
        case 'Audio':
          return ['mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg', 'opus'].contains(ext);
        case 'Documents':
          return ['pdf', 'doc', 'docx', 'txt', 'csv', 'xlsx', 'pptx', 'epub'].contains(ext);
        case 'APKs':
          return ['apk', 'aab', 'xapk'].contains(ext);
        case 'Archives':
          return ['zip', 'rar', '7z', 'tar', 'gz'].contains(ext);
        default:
          return true;
      }
    }).toList();
  }

  void _sendFileToPeer(File file) {
    final peers = widget.discoveryService.peers;
    if (peers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.surfaceCard,
          content: Text('No nearby peers on Radar. Scan or connect via IP first!'),
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
        color: AppTheme.surfaceCard.withValues(alpha: 0.98),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Target Peer',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...peers.map((peer) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AppAvatar(avatar: peer.avatar, size: 36),
                  title: Text(peer.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('${peer.ip} • 0.3ms Direct Socket', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
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
    if (['mp4', 'mkv', 'avi', 'mov', 'webm'].contains(ext)) return Icons.video_file_rounded;
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) return Icons.image_rounded;
    if (['mp3', 'wav', 'aac', 'flac', 'm4a'].contains(ext)) return Icons.audio_file_rounded;
    if (['pdf', 'doc', 'docx', 'txt', 'csv', 'xlsx'].contains(ext)) return Icons.description_rounded;
    if (['apk', 'aab', 'xapk'].contains(ext)) return Icons.android_rounded;
    if (['zip', 'rar', 'tar', '7z', 'gz'].contains(ext)) return Icons.archive_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['mp4', 'mkv', 'avi', 'mov'].contains(ext)) return AppTheme.primaryViolet;
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) return AppTheme.primaryCyan;
    if (['mp3', 'wav', 'aac'].contains(ext)) return AppTheme.accentGreen;
    if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) return AppTheme.accentYellow;
    if (['apk', 'aab'].contains(ext)) return AppTheme.accentGreen;
    if (['zip', 'rar'].contains(ext)) return Colors.orange;
    return AppTheme.primaryCyan;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZeroPing Media Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primaryCyan, size: 26),
            tooltip: 'Import Files into Vault',
            onPressed: _pickAndImportFile,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _loadVaultFiles,
            tooltip: 'Refresh Vault',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search files in vault...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryCyan, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryCyan, width: 1.5),
                ),
              ),
            ),
          ),

          // Category Selector Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryCyan.withValues(alpha: 0.18),
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

          const SizedBox(height: 6),

          // File List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryCyan))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryCyan.withValues(alpha: 0.08),
                              ),
                              child: const Icon(Icons.folder_open_rounded, size: 48, color: AppTheme.primaryCyan),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No files matching "$_searchQuery"'
                                  : 'No $_selectedCategory files in Vault',
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap + at the top to import videos, photos, or files',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Import Files Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryCyan,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _pickAndImportFile,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final file = filtered[index] as File;
                          int fileSize = 0;
                          DateTime modified = DateTime.now();
                          try {
                            final stat = file.statSync();
                            fileSize = stat.size;
                            modified = stat.modified;
                          } catch (_) {}

                          final fileName = file.path.split(RegExp(r'[/\\]')).last;
                          final color = _getFileColor(file.path);

                          return GlassContainer(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(12),
                            borderRadius: 16,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: color.withValues(alpha: 0.2)),
                                  ),
                                  child: Icon(_getFileIcon(file.path), color: color, size: 22),
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
                                        '${_formatBytes(fileSize)} • ${modified.day}/${modified.month}/${modified.year}',
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
                                  icon: const Icon(Icons.send_rounded, color: AppTheme.primaryCyan, size: 20),
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
