import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ping/models/file_metadata.dart';
import 'package:zero_ping/models/peer_device.dart';
import 'package:zero_ping/models/transfer_task.dart';

void main() {
  test('PeerDevice serialization test', () {
    final peer = PeerDevice(
      id: 'test_node_1',
      name: "Piyush's Pixel",
      ip: '192.168.43.10',
      port: 8990,
      deviceType: DeviceType.android,
    );

    final json = peer.toJson();
    final restored = PeerDevice.fromJson(json);

    expect(restored.id, 'test_node_1');
    expect(restored.name, "Piyush's Pixel");
    expect(restored.ip, '192.168.43.10');
    expect(restored.deviceType, DeviceType.android);
  });

  test('TransferTask progress and resume metrics test', () {
    final task = TransferTask(
      id: 't_1',
      fileName: 'video.mp4',
      fileSize: 1000,
      filePath: '/tmp/video.mp4',
      direction: TransferDirection.receiving,
      peerName: 'Sender',
      peerIp: '192.168.43.10',
      transferredBytes: 500,
      status: TransferStatus.transferring,
    );

    expect(task.progress, 0.5);
    expect(task.transferredFormatted, '500 B');
  });

  test('FileMetadata chunk negotiation test', () {
    final meta = FileMetadata(
      id: 'f_1',
      fileName: 'archive.zip',
      fileSize: 2048576,
      fileType: 'application/zip',
      sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      chunkSize: 512 * 1024,
    );

    final json = meta.toJson();
    final restored = FileMetadata.fromJson(json);
    expect(restored.fileName, 'archive.zip');
    expect(restored.chunkSize, 512 * 1024);
  });
}
