import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/peer_device.dart';
import '../services/p2p_socket_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final PeerDevice peer;
  final P2PSocketService socketService;

  const ChatScreen({
    super.key,
    required this.peer,
    required this.socketService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final ok = await widget.socketService.sendChatMessage(
      peerIp: widget.peer.ip,
      peerId: widget.peer.id,
      text: text,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.accentRose,
          content: Text('Failed to deliver message. Check peer connection.'),
        ),
      );
    }
    _scrollToBottom();
  }

  Future<void> _sendAttachment() async {
    final picked = await FilePicker.pickFile();
    if (picked != null && picked.path != null) {
      final path = picked.path!;
      final task = await widget.socketService.offerFile(
          peerIp: widget.peer.ip,
          peerName: widget.peer.name,
          filePath: path,
        );

        if (task != null) {
          await widget.socketService.sendChatMessage(
            peerIp: widget.peer.ip,
            peerId: widget.peer.id,
            text: '📎 Sent File: ${task.fileName} (${task.sizeFormatted})',
            attachedFileId: task.id,
            attachedFileName: task.fileName,
          );
          _scrollToBottom();
        }
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryViolet.withOpacity(0.2),
                border: Border.all(color: AppTheme.primaryViolet, width: 1.5),
              ),
              child: const Icon(Icons.person_rounded, color: AppTheme.primaryViolet, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Direct Socket • ${widget.peer.ip}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.accentGreen,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, color: AppTheme.primaryCyan),
            tooltip: 'Send File',
            onPressed: _sendAttachment,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Security / Mode Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: AppTheme.surfaceCard.withOpacity(0.6),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 12, color: AppTheme.accentGreen),
                  SizedBox(width: 6),
                  Text(
                    'Walkie-Talkie Mode: 0% Cloud • 100% Local P2P Socket',
                    style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: AnimatedBuilder(
                animation: widget.socketService,
                builder: (context, _) {
                  final messages = widget.socketService.getChatHistory(widget.peer.id);
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppTheme.textMuted.withOpacity(0.4)),
                          const SizedBox(height: 10),
                          const Text(
                            'Say hi to start local peer chat!',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _buildChatBubble(msg);
                    },
                  );
                },
              ),
            ),

            // Input Box
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Type peer message...',
                                hintStyle: TextStyle(color: AppTheme.textMuted),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.attach_file_rounded, color: AppTheme.textSecondary, size: 20),
                            onPressed: _sendAttachment,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final timeStr = DateFormat('hh:mm a').format(msg.timestamp);

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe ? AppTheme.primaryCyan.withOpacity(0.18) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isMe ? AppTheme.primaryCyan.withOpacity(0.4) : AppTheme.glassBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: AppTheme.textMuted.withOpacity(0.8),
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
