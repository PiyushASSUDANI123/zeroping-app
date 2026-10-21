import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/file_metadata.dart';
import '../models/peer_device.dart';
import '../transfer/transfer_engine.dart';
import 'p2p_socket_service.dart';

class BroadcastPeerStatus {
  final PeerDevice peer;
  int transferredBytes;
  bool isCompleted;
  bool isFailed;
  String? error;

  BroadcastPeerStatus({
    required this.peer,
    this.transferredBytes = 0,
    this.isCompleted = false,
    this.isFailed = false,
    this.error,
  });

  double progress(int totalBytes) =>
      totalBytes > 0 ? (transferredBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
}

class BroadcastSession extends ChangeNotifier {
  final String broadcastId;
  final String fileName;
  final int fileSize;
  final String filePath;
  final List<BroadcastPeerStatus> peerStatuses;
  bool isBroadcasting = false;
  double overallSpeedMBps = 0.0;
  String? sha256;

  BroadcastSession({
    required this.broadcastId,
    required this.fileName,
    required this.fileSize,
    required this.filePath,
    required this.peerStatuses,
    this.sha256,
  });

  int get totalTransferredBytes =>
      peerStatuses.fold(0, (sum, p) => sum + p.transferredBytes);

  int get completedCount =>
      peerStatuses.where((p) => p.isCompleted).length;

  double get overallProgress {
    final maxTotal = fileSize * peerStatuses.length;
    return maxTotal > 0 ? (totalTransferredBytes / maxTotal).clamp(0.0, 1.0) : 0.0;
  }
}

class BroadcastEngine extends ChangeNotifier {
  BroadcastSession? _currentSession;
  BroadcastSession? get currentSession => _currentSession;

  /// Start 1-to-Many broadcast to multiple peers in parallel
  Future<void> startBroadcast({
    required String filePath,
    required List<PeerDevice> targets,
    required String senderId,
    required String senderName,
    required P2PSocketService socketService,
  }) async {
    final file = File(filePath);
    if (!await file.exists() || targets.isEmpty) return;

    final totalSize = await file.length();
    final fileName = filePath.split(Platform.pathSeparator).last;
    final broadcastId = 'bc_${DateTime.now().millisecondsSinceEpoch}';

    final sha256Checksum = await TransferEngine.calculateSha256(filePath);

    final statuses = targets.map((p) => BroadcastPeerStatus(peer: p)).toList();
    final session = BroadcastSession(
      broadcastId: broadcastId,
      fileName: fileName,
      fileSize: totalSize,
      filePath: filePath,
      peerStatuses: statuses,
      sha256: sha256Checksum,
    );

    _currentSession = session;
    session.isBroadcasting = true;
    notifyListeners();

    // Connect to all peers simultaneously
    final Map<String, Socket> targetSockets = {};
    for (final status in statuses) {
      try {
        final socket = await Socket.connect(
          status.peer.ip,
          P2PSocketService.tcpPort,
          timeout: const Duration(seconds: 4),
        );
        targetSockets[status.peer.id] = socket;

        // Send file offer to each target
        final metadata = FileMetadata(
          id: '${broadcastId}_${status.peer.id}',
          fileName: fileName,
          fileSize: totalSize,
          fileType: 'application/octet-stream',
          sha256: sha256Checksum,
        );

        final jsonOffer = jsonEncode({
          'type': 'file_offer',
          'senderId': senderId,
          'senderName': '$senderName (Classroom Broadcast)',
          'metadata': metadata.toJson(),
        });
        final utf8Bytes = utf8.encode(jsonOffer);
        final header = ByteData(5)
          ..setUint8(0, P2PSocketService.msgTypeJson)
          ..setUint32(1, utf8Bytes.length, Endian.big);
        socket.add(header.buffer.asUint8List());
        socket.add(utf8Bytes);
      } catch (e) {
        status.isFailed = true;
        status.error = 'Connection failed';
      }
    }

    notifyListeners();

    // Stream file chunk once and push across ALL connected target sockets simultaneously
    try {
      final raf = await file.open(mode: FileMode.read);
      int currentOffset = 0;
      const chunkSize = TransferEngine.defaultChunkSize;

      int lastSampledTime = DateTime.now().millisecondsSinceEpoch;
      int lastSampledBytes = 0;

      while (currentOffset < totalSize && session.isBroadcasting) {
        final toRead = (currentOffset + chunkSize <= totalSize)
            ? chunkSize
            : (totalSize - currentOffset);

        final bytes = await raf.read(toRead);
        if (bytes.isEmpty) break;

        // Broadcast to all active sockets
        for (final status in statuses) {
          if (status.isFailed) continue;
          final socket = targetSockets[status.peer.id];
          if (socket != null) {
            try {
              final targetFileId = '${broadcastId}_${status.peer.id}';
              final idBytes = utf8.encode(targetFileId.padRight(36).substring(0, 36));

              final chunkHeader = ByteData(1 + 36 + 8 + 4)
                ..setUint8(0, P2PSocketService.msgTypeChunk);

              for (int i = 0; i < 36; i++) {
                chunkHeader.setUint8(1 + i, idBytes[i]);
              }
              chunkHeader.setUint64(37, currentOffset, Endian.big);
              chunkHeader.setUint32(45, bytes.length, Endian.big);

              socket.add(chunkHeader.buffer.asUint8List());
              socket.add(bytes);

              status.transferredBytes = currentOffset + bytes.length;
            } catch (e) {
              status.isFailed = true;
              status.error = 'Pipe broken';
            }
          }
        }

        currentOffset += bytes.length;

        // Speed calculation
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = now - lastSampledTime;
        if (elapsed >= 400) {
          final bytesDiff = session.totalTransferredBytes - lastSampledBytes;
          session.overallSpeedMBps = (bytesDiff / (elapsed / 1000.0)) / (1024 * 1024);
          lastSampledTime = now;
          lastSampledBytes = session.totalTransferredBytes;
          notifyListeners();
        }

        await Future.delayed(const Duration(milliseconds: 1));
      }

      await raf.close();

      // Finalize completed status
      for (final status in statuses) {
        if (!status.isFailed) {
          status.isCompleted = true;
          final socket = targetSockets[status.peer.id];
          if (socket != null) {
            final jsonComplete = jsonEncode({
              'type': 'file_complete',
              'fileId': '${broadcastId}_${status.peer.id}',
            });
            final utf8Bytes = utf8.encode(jsonComplete);
            final header = ByteData(5)
              ..setUint8(0, P2PSocketService.msgTypeJson)
              ..setUint32(1, utf8Bytes.length, Endian.big);
            socket.add(header.buffer.asUint8List());
            socket.add(utf8Bytes);
          }
        }
      }
    } catch (e) {
      debugPrint('Broadcast error: $e');
    } finally {
      session.isBroadcasting = false;
      notifyListeners();
    }
  }

  void cancelBroadcast() {
    _currentSession?.isBroadcasting = false;
    notifyListeners();
  }
}
