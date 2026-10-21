import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class TransferEngine {
  static const int defaultChunkSize = 512 * 1024; // 512 KB chunks

  /// Calculate SHA-256 checksum of a file without loading entire file into RAM
  static Future<String> calculateSha256(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return '';

    try {
      final stream = file.openRead();
      final digest = await sha256.bind(stream).first;
      return digest.toString();
    } catch (_) {
      return '';
    }
  }

  /// Read file chunk by chunk starting from [startOffset]
  static Stream<FileChunkData> readFileChunks({
    required String filePath,
    required String fileId,
    int startOffset = 0,
    int chunkSize = defaultChunkSize,
  }) async* {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    final totalSize = await file.length();
    final randomAccess = await file.open(mode: FileMode.read);

    try {
      if (startOffset > 0) {
        await randomAccess.setPosition(startOffset);
      }

      int currentOffset = startOffset;
      while (currentOffset < totalSize) {
        final bytesToRead = (currentOffset + chunkSize <= totalSize)
            ? chunkSize
            : (totalSize - currentOffset);

        final bytes = await randomAccess.read(bytesToRead);
        if (bytes.isEmpty) break;

        yield FileChunkData(
          fileId: fileId,
          offset: currentOffset,
          data: bytes,
          totalFileSize: totalSize,
        );

        currentOffset += bytes.length;
      }
    } finally {
      await randomAccess.close();
    }
  }

  /// Write a received chunk to disk at [offset]
  static Future<void> writeChunk({
    required String destinationPath,
    required int offset,
    required Uint8List data,
  }) async {
    final file = File(destinationPath);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }

    final raf = await file.open(mode: FileMode.append);
    try {
      await raf.setPosition(offset);
      await raf.writeFrom(data);
      await raf.flush();
    } finally {
      await raf.close();
    }
  }
}

class FileChunkData {
  final String fileId;
  final int offset;
  final Uint8List data;
  final int totalFileSize;

  FileChunkData({
    required this.fileId,
    required this.offset,
    required this.data,
    required this.totalFileSize,
  });

  int get length => data.length;
}
