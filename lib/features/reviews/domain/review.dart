/// One customer's verdict on one finished job.
class Review {
  const Review({
    required this.id,
    required this.contactId,
    required this.customerId,
    required this.providerId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final String id;
  final String contactId;
  final String customerId;
  final String providerId;

  /// One to five. The backend refuses anything else.
  final int rating;

  final String? comment;
  final DateTime createdAt;

  static Review fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    contactId: json['contact_id'] as String,
    customerId: json['customer_id'] as String,
    providerId: json['provider_id'] as String,
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    comment: json['comment'] as String?,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// What a provider's reviews add up to.
///
/// [average] is null while nobody has rated them. That is a different fact
/// from "rated zero", and the app says so rather than showing a number
/// nobody earned.
class ProviderRating {
  const ProviderRating({this.average, this.count = 0});

  final double? average;
  final int count;

  bool get hasReviews => count > 0 && average != null;

  /// The average of [reviews], or an empty rating when there are none.
  static ProviderRating from(List<Review> reviews) {
    if (reviews.isEmpty) return const ProviderRating();
    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return ProviderRating(
      average: total / reviews.length,
      count: reviews.length,
    );
  }
}
