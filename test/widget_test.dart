import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ping/models/file_metadata.dart';
import 'package:zero_ping/models/peer_device.dart';
import 'package:zero_ping/models/transfer_task.dart';
import 'package:zero_ping/services/discovery_service.dart';
import 'package:zero_ping/services/storage_service.dart';
import 'package:zero_ping/widgets/app_avatar.dart';

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

  test('UserProfile serialization and 3D avatar test', () {
    final profile = UserProfile(
      name: 'Piyush',
      username: '@piyush',
      avatar: 'assets/avatars/avatar_1.png',
      tagline: 'Zero Latency • Ready to Share',
    );

    final map = profile.toJson();
    final restored = UserProfile.fromJson(map);

    expect(restored.name, 'Piyush');
    expect(restored.username, '@piyush');
    expect(restored.avatar, 'assets/avatars/avatar_1.png');
    expect(restored.tagline, 'Zero Latency • Ready to Share');
  });

  test('AppAvatar default avatars catalog test', () {
    expect(AppAvatar.defaultAvatars.length, 6);
    expect(AppAvatar.defaultAvatars[0].id, 'assets/avatars/avatar_1.png');
    expect(AppAvatar.defaultAvatars[0].label, 'Developer');
    expect(AppAvatar.defaultAvatars[1].label, 'Creator');
    expect(AppAvatar.defaultAvatars[2].label, 'Cosmonaut');
  });

  test('DiscoveryService addDirectPeer test (Zero Fake Data)', () {
    final discovery = DiscoveryService();
    expect(discovery.peers.isEmpty, isTrue);

    discovery.addDirectPeer('192.168.1.55', name: 'MacBook Pro');
    expect(discovery.peers.length, 1);
    expect(discovery.peers.first.ip, '192.168.1.55');
    expect(discovery.peers.first.name, 'MacBook Pro');
  });
}
