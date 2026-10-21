import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_message.dart';
import '../models/peer_device.dart';
import '../services/p2p_socket_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/glass_container.dart';

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
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(immediate: true));
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    try {
      final ok = await widget.socketService.sendChatMessage(
        peerIp: widget.peer.ip,
        peerId: widget.peer.id,
        text: text,
      );

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.accentRose,
            content: Text('Message saved locally. Peer is temporarily unreachable.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentRose,
            content: Text('Delivery error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendAttachmentWithType(FileType type) async {
    try {
      final picked = await FilePicker.pickFiles(type: type);
      if (picked.isNotEmpty) {
        final path = picked.first.path ?? picked.first.name;
        final name = picked.first.name;

        final task = await widget.socketService.offerFile(
          peerIp: widget.peer.ip,
          peerName: widget.peer.name,
          filePath: path,
        );

        if (task != null) {
          await widget.socketService.sendChatMessage(
            peerIp: widget.peer.ip,
            peerId: widget.peer.id,
            text: '📎 Sent Media: $name (${task.sizeFormatted})',
            attachedFileId: task.id,
            attachedFileName: task.fileName,
          );
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentRose,
            content: Text('Could not pick media: $e'),
          ),
        );
      }
    }
  }

  void _showMediaPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        color: AppTheme.surfaceCard.withValues(alpha: 0.98),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Files & Media',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _mediaOption(
                  icon: Icons.image_rounded,
                  label: 'Photos',
                  color: AppTheme.primaryCyan,
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendAttachmentWithType(FileType.image);
                  },
                ),
                _mediaOption(
                  icon: Icons.videocam_rounded,
                  label: 'Videos',
                  color: AppTheme.primaryViolet,
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendAttachmentWithType(FileType.video);
                  },
                ),
                _mediaOption(
                  icon: Icons.audiotrack_rounded,
                  label: 'Audio',
                  color: AppTheme.accentGreen,
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendAttachmentWithType(FileType.audio);
                  },
                ),
                _mediaOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Documents',
                  color: AppTheme.accentYellow,
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendAttachmentWithType(FileType.any);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _mediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteLinkSheet() {
    final myProfile = StorageService.getUserProfile();
    final inviteLink = 'http://${widget.peer.ip}:8080/chat?peer=${widget.peer.id}&node=${Uri.encodeComponent(myProfile?.name ?? "ZeroPingUser")}';
    final shareMessage = '⚡ Join my ZeroPing Direct P2P Chat Room!\n\nLink: $inviteLink\nDirect Socket IP: ${widget.peer.ip}\n\nUnlimited speeds, 0% cloud uploads. Download ZeroPing app: https://github.com/PiyushASSUDANI123/zeroping-app';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(22),
        color: AppTheme.surfaceCard.withValues(alpha: 0.98),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.link_rounded, color: AppTheme.primaryCyan, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite to Chat via Link',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Share with any phone, PC or Mac on Wi-Fi',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.http_rounded, color: AppTheme.primaryCyan, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      inviteLink,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryCyan, size: 18),
                    tooltip: 'Copy Link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteLink));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.primaryCyan,
                          content: Text('Chat invite link copied to clipboard!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share via Apps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryCyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      SharePlus.instance.share(
                        ShareParams(
                          text: shareMessage,
                          subject: 'Join my ZeroPing P2P Chat Room',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send in Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryCyan,
                      side: const BorderSide(color: AppTheme.primaryCyan),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _textController.text = '🔗 Join my ZeroPing Direct Room: $inviteLink';
                      _sendMessage();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(
              avatar: widget.peer.avatar,
              size: 38,
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
            icon: const Icon(Icons.link_rounded, color: AppTheme.primaryCyan),
            tooltip: 'Invite via Link',
            onPressed: _showInviteLinkSheet,
          ),
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, color: AppTheme.textSecondary),
            tooltip: 'Send Media',
            onPressed: _showMediaPickerSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Security / Mode Banner with Invite Quick-Tap
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppTheme.surfaceCard.withValues(alpha: 0.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 13, color: AppTheme.accentGreen),
                      SizedBox(width: 6),
                      Text(
                        '100% Local P2P • 0% Cloud',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _showInviteLinkSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.add_link_rounded, size: 14, color: AppTheme.primaryCyan),
                          SizedBox(width: 4),
                          Text(
                            'Invite via Link',
                            style: TextStyle(fontSize: 11, color: AppTheme.primaryCyan, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
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
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppTheme.primaryCyan),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Say hi to start local peer chat!',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Direct TCP socket with sub-millisecond ping',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.link_rounded, size: 16),
                            label: const Text('Invite via Link'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryCyan,
                              side: const BorderSide(color: AppTheme.primaryCyan),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: _showInviteLinkSheet,
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
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryCyan, size: 22),
                            tooltip: 'Attach Media',
                            onPressed: _showMediaPickerSheet,
                          ),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isSending ? null : _sendMessage,
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe ? AppTheme.primaryCyan.withValues(alpha: 0.16) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isMe ? AppTheme.primaryCyan.withValues(alpha: 0.4) : AppTheme.glassBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.attachedFileName != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file_rounded, color: AppTheme.primaryCyan, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        msg.attachedFileName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Text(
              msg.text,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: AppTheme.textMuted.withValues(alpha: 0.8),
                    fontSize: 9.5,
                  ),
                ),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all_rounded, size: 12, color: AppTheme.primaryCyan),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
