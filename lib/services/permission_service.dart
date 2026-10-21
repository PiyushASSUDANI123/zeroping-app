import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionStatusReport {
  final bool nearbyWifi;
  final bool bluetooth;
  final bool location;
  final bool storage;
  final bool isAllGranted;

  PermissionStatusReport({
    required this.nearbyWifi,
    required this.bluetooth,
    required this.location,
    required this.storage,
  }) : isAllGranted = nearbyWifi && bluetooth && location && storage;
}

class PermissionService {
  static Future<PermissionStatusReport> checkPermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      // On Web/Desktop/iOS these specific Android 12+ restrictions don't apply directly
      return PermissionStatusReport(
        nearbyWifi: true,
        bluetooth: true,
        location: true,
        storage: true,
      );
    }

    bool nearbyWifi = true;
    bool bluetooth = true;
    bool location = true;
    bool storage = true;

    try {
      // Android 12+ Nearby Wi-Fi devices
      nearbyWifi = await Permission.nearbyWifiDevices.isGranted;
    } catch (_) {}

    try {
      // Bluetooth permissions
      final btScan = await Permission.bluetoothScan.isGranted;
      final btConnect = await Permission.bluetoothConnect.isGranted;
      final bt = await Permission.bluetooth.isGranted;
      bluetooth = (btScan && btConnect) || bt;
    } catch (_) {}

    try {
      // Location (Required for Wi-Fi direct/discovery on many Android versions)
      location = await Permission.location.isGranted ||
          await Permission.locationWhenInUse.isGranted;
    } catch (_) {}

    try {
      // Storage permissions
      final storageStatus = await Permission.storage.isGranted;
      final photosStatus = await Permission.photos.isGranted;
      storage = storageStatus || photosStatus;
    } catch (_) {}

    return PermissionStatusReport(
      nearbyWifi: nearbyWifi,
      bluetooth: bluetooth,
      location: location,
      storage: storage,
    );
  }

  /// Request all critical permissions with robust sequential handling
  static Future<PermissionStatusReport> requestAllPermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      return PermissionStatusReport(
        nearbyWifi: true,
        bluetooth: true,
        location: true,
        storage: true,
      );
    }

    try {
      // 1. Nearby Wi-Fi Devices (Android 13+ / 12+)
      await Permission.nearbyWifiDevices.request();
    } catch (e) {
      debugPrint('Nearby Wifi permission request error: $e');
    }

    try {
      // 2. Bluetooth Scan & Connect
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();
    } catch (e) {
      debugPrint('Bluetooth permission request error: $e');
    }

    try {
      // 3. Location
      await Permission.locationWhenInUse.request();
    } catch (e) {
      debugPrint('Location permission request error: $e');
    }

    try {
      // 4. Storage / Media
      await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();
    } catch (e) {
      debugPrint('Storage permission request error: $e');
    }

    return await checkPermissions();
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
