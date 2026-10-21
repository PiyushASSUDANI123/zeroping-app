import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/transfer_task.dart';

class StorageService {
  static const String _keyDeviceId = 'zeroping_device_id';
  static const String _keyDeviceName = 'zeroping_device_name';
  static const String _keyTransfers = 'zeroping_transfers';
  static const String _keyChatPrefix = 'zeroping_chat_';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
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

    String defaultName = 'ZeroPing Device';
    if (Platform.isAndroid) {
      defaultName = 'Android Peer';
    } else if (Platform.isWindows) defaultName = 'Windows PC';
    else if (Platform.isMacOS) defaultName = "Piyush's Mac";
    else if (Platform.isLinux) defaultName = 'Linux Node';

    _prefs?.setString(_keyDeviceName, defaultName);
    return defaultName;
  }

  static Future<void> setDeviceName(String name) async {
    await _prefs?.setString(_keyDeviceName, name);
  }

  /// Get directory where received files should be stored
  static Future<Directory> getDownloadsDirectoryPath() async {
    Directory? dir;
    if (Platform.isAndroid) {
      // In Android, try public downloads or app external files
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        dir = Directory('${ext.path}/ZeroPing');
      }
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      dir = await getDownloadsDirectory();
    }

    dir ??= await getApplicationDocumentsDirectory();
    final target = Directory('${dir.path}/ZeroPing');
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target;
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
}
