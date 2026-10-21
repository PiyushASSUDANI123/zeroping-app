class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final String? attachedFileId;
  final String? attachedFileName;
  final int? attachedFileSize;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    DateTime? timestamp,
    required this.isMe,
    this.attachedFileId,
    this.attachedFileName,
    this.attachedFileSize,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isMe': isMe,
        'attachedFileId': attachedFileId,
        'attachedFileName': attachedFileName,
        'attachedFileSize': attachedFileSize,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json, {bool isMe = false}) {
    return ChatMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Peer',
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isMe: isMe,
      attachedFileId: json['attachedFileId'] as String?,
      attachedFileName: json['attachedFileName'] as String?,
      attachedFileSize: (json['attachedFileSize'] as num?)?.toInt(),
    );
  }
}
