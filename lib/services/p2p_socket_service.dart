import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/file_metadata.dart';
import '../models/transfer_task.dart';
import '../transfer/transfer_engine.dart';
import 'storage_service.dart';

typedef OnIncomingFileOffer = Future<bool> Function(FileMetadata metadata, String peerName, String peerIp);

class P2PSocketService extends ChangeNotifier {
  static const int tcpPort = 8990;

  static const int msgTypeJson = 0x01;
  static const int msgTypeChunk = 0x02;

  ServerSocket? _serverSocket;
  bool _isServerRunning = false;
  bool get isServerRunning => _isServerRunning;

  String _myDeviceId = '';
  String _myDeviceName = '';

  // Connected peers: IP -> Socket
  final Map<String, Socket> _connectedSockets = {};

  // Active transfers
  final Map<String, TransferTask> _activeTransfers = {};
  List<TransferTask> get activeTransfers => _activeTransfers.values.toList();

  // Chat messages per peer: peerId -> list of messages
  final Map<String, List<ChatMessage>> _chatMessages = {};

  OnIncomingFileOffer? onIncomingFileOffer;

  // Active receiver file streams: fileId -> RandomAccessFile
  final Map<String, RandomAccessFile> _openReceivingFiles = {};

  // Speed measurement state
  final Map<String, int> _lastSampledBytes = {};
  final Map<String, int> _lastSampledTime = {};

  Future<void> init({required String deviceId, required String deviceName}) async {
    _myDeviceId = deviceId;
    _myDeviceName = deviceName;

    // Load persisted transfers from storage
    final loadedTransfers = StorageService.loadTransferTasks();
    for (final task in loadedTransfers) {
      _activeTransfers[task.id] = task;
    }

    await startServer();
  }

  Future<bool> startServer() async {
    if (_isServerRunning) return true;

    try {
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        tcpPort,
        shared: true,
      );

      _serverSocket?.listen(_handleIncomingClient, onError: (e) {
        debugPrint('TCP ServerSocket error: $e');
      });

      _isServerRunning = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to bind TCP ServerSocket: $e');
      _isServerRunning = false;
      notifyListeners();
      return false;
    }
  }

  void _handleIncomingClient(Socket clientSocket) {
    final clientIp = clientSocket.remoteAddress.address;
    _connectedSockets[clientIp] = clientSocket;

    _listenToSocket(clientSocket, clientIp);
  }

  Future<Socket?> _getOrConnectSocket(String remoteIp, {int port = tcpPort}) async {
    if (_connectedSockets.containsKey(remoteIp)) {
      return _connectedSockets[remoteIp];
    }

    try {
      final socket = await Socket.connect(
        remoteIp,
        port,
        timeout: const Duration(seconds: 4),
      );
      _connectedSockets[remoteIp] = socket;
      _listenToSocket(socket, remoteIp);
      return socket;
    } catch (e) {
      debugPrint('Failed to connect to $remoteIp:$port: $e');
      return null;
    }
  }

  void _listenToSocket(Socket socket, String peerIp) {
    final buffer = BytesBuilder(copy: false);

    socket.listen(
      (data) {
        buffer.add(data);
        _processBuffer(buffer, socket, peerIp);
      },
      onDone: () {
        _connectedSockets.remove(peerIp);
        socket.destroy();
      },
      onError: (e) {
        _connectedSockets.remove(peerIp);
        socket.destroy();
      },
    );
  }

  void _processBuffer(BytesBuilder buffer, Socket socket, String peerIp) async {
    Uint8List currentBytes = buffer.takeBytes();
    int readIndex = 0;

    while (readIndex < currentBytes.length) {
      final remaining = currentBytes.length - readIndex;
      if (remaining < 5) {
        // Need at least 1 byte type + 4 bytes length
        break;
      }

      final msgType = currentBytes[readIndex];

      if (msgType == msgTypeJson) {
        // Read 4-byte uint32 big endian length
        final lengthBytes = currentBytes.sublist(readIndex + 1, readIndex + 5);
        final payloadLength = ByteData.sublistView(lengthBytes).getUint32(0, Endian.big);

        if (remaining < 5 + payloadLength) {
          // Incomplete JSON packet, wait for more bytes
          break;
        }

        final jsonBytes = currentBytes.sublist(readIndex + 5, readIndex + 5 + payloadLength);
        readIndex += 5 + payloadLength;

        final jsonStr = utf8.decode(jsonBytes);
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          _handleJsonMessage(map, socket, peerIp);
        } catch (e) {
          debugPrint('JSON decode error: $e');
        }
      } else if (msgType == msgTypeChunk) {
        // Binary Chunk packet:
        // [1 byte msgType] [36 bytes fileId] [8 bytes offset uint64] [4 bytes length uint32] [data]
        const headerSize = 1 + 36 + 8 + 4;
        if (remaining < headerSize) {
          break;
        }

        final fileIdBytes = currentBytes.sublist(readIndex + 1, readIndex + 37);
        final fileId = utf8.decode(fileIdBytes).trim();

        final offsetBytes = currentBytes.sublist(readIndex + 37, readIndex + 45);
        final offset = ByteData.sublistView(offsetBytes).getUint64(0, Endian.big);

        final lengthBytes = currentBytes.sublist(readIndex + 45, readIndex + 49);
        final chunkLength = ByteData.sublistView(lengthBytes).getUint32(0, Endian.big);

        if (remaining < headerSize + chunkLength) {
          // Waiting for full chunk
          break;
        }

        final chunkData = currentBytes.sublist(readIndex + headerSize, readIndex + headerSize + chunkLength);
        readIndex += headerSize + chunkLength;

        _handleIncomingChunk(fileId, offset, chunkData, socket, peerIp);
      } else {
        // Unknown byte or framing desync, skip 1 byte
        readIndex++;
      }
    }

    // Put unread bytes back into buffer
    if (readIndex < currentBytes.length) {
      buffer.add(currentBytes.sublist(readIndex));
    }
  }

  void _handleJsonMessage(Map<String, dynamic> json, Socket socket, String peerIp) async {
    final type = json['type'] as String?;

    switch (type) {
      case 'chat':
        final msg = ChatMessage.fromJson(json, isMe: false);
        final senderId = msg.senderId.isNotEmpty ? msg.senderId : peerIp;
        _chatMessages.putIfAbsent(senderId, () => []).add(msg);
        await StorageService.saveChatMessages(senderId, _chatMessages[senderId]!);
        notifyListeners();
        break;

      case 'file_offer':
        final metadata = FileMetadata.fromJson(json['metadata'] as Map<String, dynamic>);
        final peerName = json['senderName'] as String? ?? 'Peer $peerIp';

        final downloadsDir = await StorageService.getDownloadsDirectoryPath();
        final destinationPath = '${downloadsDir.path}/${metadata.fileName}';

        // Check if partially downloaded file exists for RESUME logic!
        int existingBytes = 0;
        final partialFile = File(destinationPath);
        if (await partialFile.exists()) {
          existingBytes = await partialFile.length();
          if (existingBytes > metadata.fileSize) {
            existingBytes = 0; // Invalid partial file, restart
          }
        }

        final task = TransferTask(
          id: metadata.id,
          fileName: metadata.fileName,
          fileSize: metadata.fileSize,
          filePath: destinationPath,
          direction: TransferDirection.receiving,
          peerName: peerName,
          peerIp: peerIp,
          transferredBytes: existingBytes,
          status: TransferStatus.offered,
          sha256: metadata.sha256,
        );

        _activeTransfers[task.id] = task;
        notifyListeners();

        // Prompt or auto-accept if handler registered
        bool accepted = true;
        if (onIncomingFileOffer != null) {
          accepted = await onIncomingFileOffer!(metadata, peerName, peerIp);
        }

        if (accepted) {
          task.status = TransferStatus.transferring;
          notifyListeners();

          // Open file in append or read-write mode
          final raf = await partialFile.open(mode: FileMode.writeOnlyAppend);
          _openReceivingFiles[metadata.id] = raf;

          // Send file_accept with startByte (Resume logic)
          _sendJson(socket, {
            'type': 'file_accept',
            'fileId': metadata.id,
            'startByte': existingBytes,
          });
        } else {
          task.status = TransferStatus.cancelled;
          notifyListeners();
          _sendJson(socket, {
            'type': 'file_reject',
            'fileId': metadata.id,
            'reason': 'Rejected by user',
          });
        }
        break;

      case 'file_accept':
        final fileId = json['fileId'] as String;
        final startByte = (json['startByte'] as num?)?.toInt() ?? 0;
        final task = _activeTransfers[fileId];
        if (task != null) {
          task.status = TransferStatus.transferring;
          task.transferredBytes = startByte;
          notifyListeners();
          _startSendingChunks(task, socket, startByte);
        }
        break;

      case 'file_reject':
        final fileId = json['fileId'] as String;
        final task = _activeTransfers[fileId];
        if (task != null) {
          task.status = TransferStatus.cancelled;
          task.errorMessage = json['reason'] as String? ?? 'Rejected by receiver';
          notifyListeners();
        }
        break;

      case 'file_complete':
        final fileId = json['fileId'] as String;
        final task = _activeTransfers[fileId];
        if (task != null && task.direction == TransferDirection.receiving) {
          final raf = _openReceivingFiles.remove(fileId);
          if (raf != null) {
            await raf.close();
          }

          // Compute SHA-256 and verify
          try {
            final computedSha = await TransferEngine.calculateSha256(task.filePath);
            final matches = task.sha256 == null ||
                task.sha256!.isEmpty ||
                task.sha256!.toLowerCase() == computedSha.toLowerCase();

            task.isChecksumVerified = matches;
            task.status = matches ? TransferStatus.completed : TransferStatus.failed;
            task.completedAt = DateTime.now();
            if (!matches) {
              task.errorMessage = 'SHA-256 Checksum mismatch! File might be corrupted.';
            }
          } catch (e) {
            task.status = TransferStatus.completed;
          }

          notifyListeners();
          _persistTransfers();

          _sendJson(socket, {
            'type': 'file_complete_ack',
            'fileId': fileId,
            'verified': task.isChecksumVerified,
          });
        }
        break;

      case 'file_complete_ack':
        final fileId = json['fileId'] as String;
        final task = _activeTransfers[fileId];
        if (task != null && task.direction == TransferDirection.sending) {
          task.status = TransferStatus.completed;
          task.completedAt = DateTime.now();
          task.isChecksumVerified = json['verified'] as bool? ?? true;
          notifyListeners();
          _persistTransfers();
        }
        break;
    }
  }

  void _handleIncomingChunk(
    String fileId,
    int offset,
    Uint8List data,
    Socket socket,
    String peerIp,
  ) async {
    final task = _activeTransfers[fileId];
    if (task == null || task.status != TransferStatus.transferring) return;

    var raf = _openReceivingFiles[fileId];
    if (raf == null) {
      final file = File(task.filePath);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      raf = await file.open(mode: FileMode.writeOnlyAppend);
      _openReceivingFiles[fileId] = raf;
    }

    try {
      await raf.setPosition(offset);
      await raf.writeFrom(data);
      task.transferredBytes = offset + data.length;

      // Update speed
      _updateSpeedMetrics(task);

      notifyListeners();

      if (task.transferredBytes >= task.fileSize) {
        // All bytes received!
        _handleJsonMessage({'type': 'file_complete', 'fileId': fileId}, socket, peerIp);
      }
    } catch (e) {
      debugPrint('Error writing chunk to disk: $e');
    }
  }

  void _updateSpeedMetrics(TransferTask task) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _lastSampledTime[task.id] ?? now;
    final lastBytes = _lastSampledBytes[task.id] ?? task.transferredBytes;

    final elapsedMs = now - lastTime;
    if (elapsedMs >= 400) {
      final bytesDiff = task.transferredBytes - lastBytes;
      if (bytesDiff >= 0) {
        task.speedBytesPerSec = (bytesDiff / (elapsedMs / 1000.0));
      }
      _lastSampledTime[task.id] = now;
      _lastSampledBytes[task.id] = task.transferredBytes;
    }
  }

  Future<void> _startSendingChunks(TransferTask task, Socket socket, int startByte) async {
    try {
      final file = File(task.filePath);
      final totalSize = await file.length();
      final raf = await file.open(mode: FileMode.read);

      if (startByte > 0) {
        await raf.setPosition(startByte);
      }

      int currentOffset = startByte;
      const chunkSize = TransferEngine.defaultChunkSize;

      while (currentOffset < totalSize && task.status == TransferStatus.transferring) {
        final toRead = (currentOffset + chunkSize <= totalSize) ? chunkSize : (totalSize - currentOffset);
        final bytes = await raf.read(toRead);
        if (bytes.isEmpty) break;

        // Send binary chunk packet
        _sendChunk(socket, task.id, currentOffset, bytes);

        currentOffset += bytes.length;
        task.transferredBytes = currentOffset;
        _updateSpeedMetrics(task);
        notifyListeners();

        // Socket backpressure & prevent CPU hogging
        if (currentOffset % (chunkSize * 2) == 0) {
          await socket.flush();
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      await raf.close();

      if (task.transferredBytes >= totalSize) {
        // Send file_complete packet
        _sendJson(socket, {
          'type': 'file_complete',
          'fileId': task.id,
        });
      }
    } catch (e) {
      debugPrint('Error while streaming file: $e');
      task.status = TransferStatus.failed;
      task.errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Sends a file offer to a peer
  Future<TransferTask?> offerFile({
    required String peerIp,
    required String peerName,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final fileSize = await file.length();
    final fileName = filePath.split(Platform.pathSeparator).last;
    final fileId = 'f_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 999)}';

    // Calculate SHA-256 for integrity verification
    final sha256Checksum = await TransferEngine.calculateSha256(filePath);

    final metadata = FileMetadata(
      id: fileId,
      fileName: fileName,
      fileSize: fileSize,
      fileType: 'application/octet-stream',
      sha256: sha256Checksum,
    );

    final task = TransferTask(
      id: fileId,
      fileName: fileName,
      fileSize: fileSize,
      filePath: filePath,
      direction: TransferDirection.sending,
      peerName: peerName,
      peerIp: peerIp,
      status: TransferStatus.offered,
      sha256: sha256Checksum,
    );

    _activeTransfers[fileId] = task;
    notifyListeners();

    final socket = await _getOrConnectSocket(peerIp);
    if (socket == null) {
      task.status = TransferStatus.failed;
      task.errorMessage = 'Could not connect to $peerIp';
      notifyListeners();
      return task;
    }

    _sendJson(socket, {
      'type': 'file_offer',
      'senderId': _myDeviceId,
      'senderName': _myDeviceName,
      'metadata': metadata.toJson(),
    });

    return task;
  }

  /// Resume a paused/interrupted transfer
  Future<bool> resumeTransfer(String taskId) async {
    final task = _activeTransfers[taskId];
    if (task == null) return false;

    task.status = TransferStatus.transferring;
    notifyListeners();

    final socket = await _getOrConnectSocket(task.peerIp);
    if (socket == null) {
      task.status = TransferStatus.failed;
      notifyListeners();
      return false;
    }

    if (task.direction == TransferDirection.sending) {
      // Re-offer or ask receiver where they are at
      _sendJson(socket, {
        'type': 'file_offer',
        'senderId': _myDeviceId,
        'senderName': _myDeviceName,
        'metadata': {
          'id': task.id,
          'fileName': task.fileName,
          'fileSize': task.fileSize,
          'sha256': task.sha256 ?? '',
        },
      });
    } else {
      // If we are receiving, send file_accept with current byte position
      int currentLength = 0;
      final f = File(task.filePath);
      if (await f.exists()) {
        currentLength = await f.length();
      }
      task.transferredBytes = currentLength;

      _sendJson(socket, {
        'type': 'file_accept',
        'fileId': task.id,
        'startByte': currentLength,
      });
    }
    return true;
  }

  /// Pause an active transfer
  void pauseTransfer(String taskId) {
    final task = _activeTransfers[taskId];
    if (task != null) {
      task.status = TransferStatus.paused;
      task.speedBytesPerSec = 0;
      notifyListeners();
      _persistTransfers();
    }
  }

  /// Cancel a transfer
  void cancelTransfer(String taskId) {
    final task = _activeTransfers[taskId];
    if (task != null) {
      task.status = TransferStatus.cancelled;
      task.speedBytesPerSec = 0;
      final raf = _openReceivingFiles.remove(taskId);
      raf?.close();
      notifyListeners();
      _persistTransfers();
    }
  }

  /// Send chat message
  Future<bool> sendChatMessage({
    required String peerIp,
    required String peerId,
    required String text,
    String? attachedFileId,
    String? attachedFileName,
  }) async {
    final socket = await _getOrConnectSocket(peerIp);
    if (socket == null) return false;

    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final chatMsg = ChatMessage(
      id: msgId,
      senderId: _myDeviceId,
      senderName: _myDeviceName,
      text: text,
      isMe: true,
      attachedFileId: attachedFileId,
      attachedFileName: attachedFileName,
    );

    _chatMessages.putIfAbsent(peerId, () => []).add(chatMsg);
    await StorageService.saveChatMessages(peerId, _chatMessages[peerId]!);
    notifyListeners();

    _sendJson(socket, {
      'type': 'chat',
      'id': msgId,
      'senderId': _myDeviceId,
      'senderName': _myDeviceName,
      'text': text,
      'timestamp': chatMsg.timestamp.toIso8601String(),
      'attachedFileId': attachedFileId,
      'attachedFileName': attachedFileName,
    });

    return true;
  }

  List<ChatMessage> getChatHistory(String peerId) {
    return _chatMessages[peerId] ?? StorageService.loadChatMessages(peerId);
  }

  void _sendJson(Socket socket, Map<String, dynamic> data) {
    final jsonStr = jsonEncode(data);
    final utf8Bytes = utf8.encode(jsonStr);

    final byteData = ByteData(5);
    byteData.setUint8(0, msgTypeJson);
    byteData.setUint32(1, utf8Bytes.length, Endian.big);

    socket.add(byteData.buffer.asUint8List());
    socket.add(utf8Bytes);
  }

  void _sendChunk(Socket socket, String fileId, int offset, Uint8List chunkData) {
    // 36 bytes padded fileId
    final idBytes = utf8.encode(fileId.padRight(36).substring(0, 36));

    final header = ByteData(1 + 36 + 8 + 4);
    header.setUint8(0, msgTypeChunk);

    for (int i = 0; i < 36; i++) {
      header.setUint8(1 + i, idBytes[i]);
    }
    header.setUint64(37, offset, Endian.big);
    header.setUint32(45, chunkData.length, Endian.big);

    socket.add(header.buffer.asUint8List());
    socket.add(chunkData);
  }

  void _persistTransfers() {
    StorageService.saveTransferTasks(_activeTransfers.values.toList());
  }

  @override
  void dispose() {
    for (final raf in _openReceivingFiles.values) {
      raf.close();
    }
    _openReceivingFiles.clear();

    for (final s in _connectedSockets.values) {
      s.destroy();
    }
    _connectedSockets.clear();

    _serverSocket?.close();
    super.dispose();
  }
}
