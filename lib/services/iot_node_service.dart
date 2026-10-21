import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class IoTNodeFile {
  final String name;
  final int size;
  final String date;

  IoTNodeFile({
    required this.name,
    required this.size,
    required this.date,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class IoTNodeInfo {
  final String ip;
  final String name;
  final int freeSpaceMB;
  final int totalSpaceMB;
  final bool isOnline;

  IoTNodeInfo({
    required this.ip,
    required this.name,
    required this.freeSpaceMB,
    required this.totalSpaceMB,
    required this.isOnline,
  });
}

class IoTNodeService extends ChangeNotifier {
  IoTNodeInfo? _activeNode;
  IoTNodeInfo? get activeNode => _activeNode;

  List<IoTNodeFile> _nodeFiles = [];
  List<IoTNodeFile> get nodeFiles => _nodeFiles;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  // Simulator mode stores mock hardware files in a subfolder of downloads
  bool isSimulator = false;

  Future<void> connectToNode(String nodeIp, {bool simulate = false}) async {
    _isConnecting = true;
    notifyListeners();

    if (simulate) {
      isSimulator = true;
      _activeNode = IoTNodeInfo(
        ip: '192.168.1.150',
        name: 'ESP32 ZeroBox (SD 64GB)',
        freeSpaceMB: 58240,
        totalSpaceMB: 65536,
        isOnline: true,
      );

      _nodeFiles = [
        IoTNodeFile(name: 'Office_Annual_Budget_2026.pdf', size: 4200000, date: 'Today, 10:15 AM'),
        IoTNodeFile(name: 'Project_Architecture_Overview.mp4', size: 48900000, date: 'Yesterday'),
        IoTNodeFile(name: 'ZeroPing_ESP32_Firmware.bin', size: 1250000, date: '20 Oct'),
      ];

      _isConnecting = false;
      notifyListeners();
      return;
    }

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final req = await client.getUrl(Uri.parse('http://$nodeIp/api/status'));
      final resp = await req.close();

      if (resp.statusCode == 200) {
        final body = await utf8.decodeStream(resp);
        final json = jsonDecode(body) as Map<String, dynamic>;

        _activeNode = IoTNodeInfo(
          ip: nodeIp,
          name: json['name'] as String? ?? 'ESP32 Hardware Node',
          freeSpaceMB: (json['freeMB'] as num?)?.toInt() ?? 1024,
          totalSpaceMB: (json['totalMB'] as num?)?.toInt() ?? 32768,
          isOnline: true,
        );

        await refreshFiles();
      }
    } catch (e) {
      _activeNode = null;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> refreshFiles() async {
    if (_activeNode == null) return;
    if (isSimulator) return;

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(Uri.parse('http://${_activeNode!.ip}/api/files'));
      final resp = await req.close();

      if (resp.statusCode == 200) {
        final body = await utf8.decodeStream(resp);
        final list = jsonDecode(body) as List<dynamic>;

        _nodeFiles = list.map((item) {
          final m = item as Map<String, dynamic>;
          return IoTNodeFile(
            name: m['name'] as String,
            size: (m['size'] as num).toInt(),
            date: m['date'] as String? ?? 'Recent',
          );
        }).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Drop file to the hardware box
  Future<bool> dropFileToNode(String localFilePath) async {
    final file = File(localFilePath);
    if (!await file.exists()) return false;

    final fileName = localFilePath.split(Platform.pathSeparator).last;
    final fileSize = await file.length();

    if (isSimulator) {
      _nodeFiles.insert(
        0,
        IoTNodeFile(
          name: fileName,
          size: fileSize,
          date: 'Just now',
        ),
      );
      notifyListeners();
      return true;
    }

    if (_activeNode == null) return false;

    try {
      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse('http://${_activeNode!.ip}/api/upload'),
      );
      req.headers.add('x-filename', Uri.encodeComponent(fileName));
      req.contentLength = fileSize;

      await file.openRead().pipe(req);
      await refreshFiles();
      return true;
    } catch (e) {
      debugPrint('Error dropping to IoT node: $e');
      return false;
    }
  }

  /// Pick file from the hardware box and save to phone storage
  Future<String?> pickFileFromNode(IoTNodeFile nodeFile) async {
    final downloadsDir = await StorageService.getDownloadsDirectoryPath();
    final targetPath = '${downloadsDir.path}/${nodeFile.name}';

    if (isSimulator) {
      // Create sample file in vault
      final f = File(targetPath);
      await f.writeAsString('Downloaded from Offline ZeroPing ESP32 Cloud Node Box.');
      return targetPath;
    }

    if (_activeNode == null) return null;

    try {
      final client = HttpClient();
      final req = await client.getUrl(
        Uri.parse('http://${_activeNode!.ip}/download?file=${Uri.encodeComponent(nodeFile.name)}'),
      );
      final resp = await req.close();

      if (resp.statusCode == 200) {
        final target = File(targetPath);
        await resp.pipe(target.openWrite());
        return targetPath;
      }
    } catch (_) {}
    return null;
  }
}
