/// One row of the chat list: who it is with, what about, and the last thing
/// that was said.
///
/// Read through one backend function, so the other person's name arrives
/// already resolved — the app never joins customer and provider profiles
/// itself, and could not: each side's table is closed to the other.
class ConversationSummary {
  const ConversationSummary({
    required this.conversationId,
    required this.requestId,
    required this.providerId,
    required this.viewerIsCustomer,
    required this.updatedAt,
    this.otherName,
    this.otherImageUrl,
    this.serviceName,
    this.serviceNameEn,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String conversationId;
  final String requestId;

  /// Passed back when opening the chat, so the backend lands on this exact
  /// conversation instead of working one out.
  final String providerId;

  /// Whether the signed-in person is the customer here. Used only to say
  /// what the other person is when they stored no name.
  final bool viewerIsCustomer;

  final String? otherName;
  final String? otherImageUrl;

  final String? serviceName;
  final String? serviceNameEn;

  /// Null while nobody has written anything.
  final String? lastMessage;
  final DateTime? lastMessageAt;

  final DateTime updatedAt;

  /// What the list sorts and timestamps by: the last message, or when the
  /// conversation was opened while there is none.
  DateTime get sortedAt => lastMessageAt ?? updatedAt;

  /// Falls back to German, because the catalog is German-first and a
  /// missing translation must never blank out the name.
  String? serviceFor(String language) {
    if (language == 'en') {
      final english = serviceNameEn;
      if (english != null && english.isNotEmpty) return english;
    }
    return serviceName;
  }

  static ConversationSummary fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        conversationId: json['conversation_id'] as String,
        requestId: json['request_id'] as String,
        providerId: json['provider_id'] as String,
        viewerIsCustomer: json['viewer_is_customer'] as bool? ?? true,
        otherName: json['other_name'] as String?,
        otherImageUrl: json['other_image_url'] as String?,
        serviceName: json['service_name'] as String?,
        serviceNameEn: json['service_name_en'] as String?,
        lastMessage: json['last_message'] as String?,
        lastMessageAt: DateTime.tryParse(
          json['last_message_at'] as String? ?? '',
        ),
        updatedAt:
            DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
