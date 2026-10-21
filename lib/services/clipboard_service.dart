import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ClipboardItem {
  final String text;
  final String senderName;
  final DateTime timestamp;
  final bool isFromMe;

  ClipboardItem({
    required this.text,
    required this.senderName,
    DateTime? timestamp,
    required this.isFromMe,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ClipboardService extends ChangeNotifier {
  Timer? _clipboardWatcherTimer;
  String _lastCopiedText = '';
  bool _autoSync = true;

  bool get autoSync => _autoSync;

  final List<ClipboardItem> _history = [];
  List<ClipboardItem> get history => List.unmodifiable(_history);

  // Callback to broadcast copied text to active peers
  void Function(String text)? onBroadcastClipboard;

  void init() {
    startWatching();
  }

  void toggleAutoSync(bool enable) {
    _autoSync = enable;
    if (_autoSync) {
      startWatching();
    } else {
      stopWatching();
    }
    notifyListeners();
  }

  void startWatching() {
    _clipboardWatcherTimer?.cancel();
    _clipboardWatcherTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
      if (!_autoSync) return;
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final currentText = data?.text?.trim() ?? '';

        if (currentText.isNotEmpty && currentText != _lastCopiedText) {
          _lastCopiedText = currentText;
          _history.insert(
            0,
            ClipboardItem(
              text: currentText,
              senderName: 'This Device',
              isFromMe: true,
            ),
          );
          notifyListeners();

          // Push to peers
          if (onBroadcastClipboard != null) {
            onBroadcastClipboard!(currentText);
          }
        }
      } catch (_) {}
    });
  }

  void stopWatching() {
    _clipboardWatcherTimer?.cancel();
    _clipboardWatcherTimer = null;
  }

  /// When a peer pushes clipboard to us
  Future<void> receiveRemoteClipboard({
    required String text,
    required String senderName,
  }) async {
    if (text.isEmpty || text == _lastCopiedText) return;

    _lastCopiedText = text;
    _history.insert(
      0,
      ClipboardItem(
        text: text,
        senderName: senderName,
        isFromMe: false,
      ),
    );

    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {}

    notifyListeners();
  }

  Future<void> copyToClipboard(String text) async {
    _lastCopiedText = text;
    await Clipboard.setData(ClipboardData(text: text));
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}
