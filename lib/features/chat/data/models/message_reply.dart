class MessageReply {
  const MessageReply({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.preview,
  });

  final String messageId;
  final String senderId;
  final String senderName;
  final String type;
  final String preview;

  factory MessageReply.fromMessage({
    required String messageId,
    required Map<String, dynamic> data,
    required String senderName,
  }) {
    final type = data['type'] as String? ?? 'text';
    return MessageReply(
      messageId: messageId,
      senderId: data['senderId'] as String? ?? '',
      senderName: senderName,
      type: type,
      preview: switch (type) {
        'image' => 'Photo',
        'voice' => 'Voice message',
        'file' => data['fileName'] as String? ?? 'File',
        _ => data['text'] as String? ?? 'Message',
      },
    );
  }

  factory MessageReply.fromMap(Map<String, dynamic> data) => MessageReply(
    messageId: data['messageId'] as String? ?? '',
    senderId: data['senderId'] as String? ?? '',
    senderName: data['senderName'] as String? ?? 'User',
    type: data['type'] as String? ?? 'text',
    preview: data['preview'] as String? ?? 'Message',
  );

  Map<String, dynamic> toMap() => {
    'messageId': messageId,
    'senderId': senderId,
    'senderName': senderName,
    'type': type,
    'preview': preview,
  };
}
