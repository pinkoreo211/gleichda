/// One message in a conversation.
///
/// [senderId] is the account that wrote it, set by the backend from the
/// signed-in user. The app reads it to decide which side of the screen the
/// message belongs on; it never sends it.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  /// Whether [userId] wrote this message.
  bool isFrom(String? userId) => userId != null && senderId == userId;

  static ChatMessage fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    senderId: json['sender_id'] as String,
    message: json['message'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
