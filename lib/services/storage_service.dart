import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/transfer_task.dart';

class UserProfile {
  final String name;
  final String username;
  final String avatar;
  final String tagline;

  UserProfile({
    required this.name,
    required this.username,
    required this.avatar,
    required this.tagline,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'username': username,
        'avatar': avatar,
        'tagline': tagline,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'Piyush',
      username: json['username'] as String? ?? '@piyush',
      avatar: json['avatar'] as String? ?? 'assets/avatars/avatar_1.png',
      tagline: json['tagline'] as String? ?? 'Zero Latency • Ready to Share',
    );
  }
}

class StorageService {
  static const String _keyDeviceId = 'zeroping_device_id';
  static const String _keyDeviceName = 'zeroping_device_name';
  static const String _keyUserProfile = 'zeroping_user_profile';
  static const String _keyTransfers = 'zeroping_transfers';
  static const String _keyChatPrefix = 'zeroping_chat_';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- USER PROFILE / LOGIN SYSTEM ---
  static bool isLoggedIn() {
    return _prefs?.containsKey(_keyUserProfile) ?? false;
  }

  static UserProfile? getUserProfile() {
    final str = _prefs?.getString(_keyUserProfile);
    if (str == null || str.isEmpty) return null;
    try {
      return UserProfile.fromJson(jsonDecode(str));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs?.setString(_keyUserProfile, jsonEncode(profile.toJson()));
    await setDeviceName(profile.name);
  }

  static Future<void> logout() async {
    await _prefs?.remove(_keyUserProfile);
  }

  static String getDeviceId() {
    String? id = _prefs?.getString(_keyDeviceId);
    if (id == null || id.isEmpty) {
      id = 'zp_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
      _prefs?.setString(_keyDeviceId, id);
    }
    return id;
  }

  static String getDeviceName() {
    String? name = _prefs?.getString(_keyDeviceName);
    if (name != null && name.isNotEmpty) return name;

    // Check saved user profile first
    final profile = getUserProfile();
    if (profile != null && profile.name.isNotEmpty) {
      return profile.name;
    }

    String defaultName = 'ZeroPing Node';
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          defaultName = 'Android Peer';
        } else if (Platform.isWindows) {
          defaultName = 'Windows PC';
        } else if (Platform.isMacOS) {
          defaultName = "Piyush's Mac";
        } else if (Platform.isLinux) {
          defaultName = 'Linux Node';
        }
      } catch (_) {}
    } else {
      defaultName = 'Web Peer';
    }

    _prefs?.setString(_keyDeviceName, defaultName);
    return defaultName;
  }

  static Future<void> setDeviceName(String name) async {
    await _prefs?.setString(_keyDeviceName, name);
  }

  /// Get directory where received files should be stored (Web Safe)
  static Future<Directory> getDownloadsDirectoryPath() async {
    if (kIsWeb) {
      return Directory('/zeroping_web_vault');
    }

    Directory? dir;
    try {
      if (Platform.isAndroid) {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          dir = Directory('${ext.path}/ZeroPing');
        }
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        dir = await getDownloadsDirectory();
      }
    } catch (_) {}

    try {
      dir ??= await getApplicationDocumentsDirectory();
      final target = Directory('${dir.path}/ZeroPing');
      if (!await target.exists()) {
        await target.create(recursive: true);
      }
      return target;
    } catch (_) {
      return Directory('/tmp/ZeroPing');
    }
  }

  /// Save transfer tasks
  static Future<void> saveTransferTasks(List<TransferTask> tasks) async {
    final list = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs?.setStringList(_keyTransfers, list);
  }

  /// Load transfer tasks
  static List<TransferTask> loadTransferTasks() {
    final list = _prefs?.getStringList(_keyTransfers) ?? [];
    final List<TransferTask> tasks = [];
    for (final item in list) {
      try {
        tasks.add(TransferTask.fromJson(jsonDecode(item)));
      } catch (_) {}
    }
    return tasks;
  }

  /// Save chat messages for a specific peer
  static Future<void> saveChatMessages(String peerId, List<ChatMessage> messages) async {
    final list = messages.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs?.setStringList('$_keyChatPrefix$peerId', list);
  }

  /// Load chat messages for a specific peer
  static List<ChatMessage> loadChatMessages(String peerId) {
    final list = _prefs?.getStringList('$_keyChatPrefix$peerId') ?? [];
    final List<ChatMessage> messages = [];
    for (final item in list) {
      try {
        messages.add(ChatMessage.fromJson(jsonDecode(item)));
      } catch (_) {}
    }
    return messages;
  }

  /// Generic key-value helpers for local persistent vault
  static Future<void> saveString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }
}
