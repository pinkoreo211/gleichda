/// The private conversation for one accepted job.
///
/// There is exactly one per (request, provider) pair, which is what an
/// accepted job is. The customer and that provider open the same row.
class Conversation {
  const Conversation({
    required this.id,
    required this.requestId,
    required this.customerId,
    required this.providerId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String requestId;

  /// The customer's account.
  final String customerId;

  /// The provider's profile, not their account — that is how providers are
  /// referenced throughout the app.
  final String providerId;

  final DateTime createdAt;
  final DateTime updatedAt;

  static Conversation fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    requestId: json['request_id'] as String,
    customerId: json['customer_id'] as String,
    providerId: json['provider_id'] as String,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        DateTime.tryParse(json['updated_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
