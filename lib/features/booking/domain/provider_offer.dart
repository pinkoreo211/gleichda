import 'package:app/features/provider/domain/provider_profile.dart';

/// One price a provider set for the service being booked.
///
/// Every field comes from the provider's own row. Nothing here is computed
/// on the phone, because the phone is not allowed to decide what anything
/// costs.
class ProviderPrice {
  const ProviderPrice({
    required this.id,
    required this.name,
    required this.priceCents,
    this.description,
    this.currency = 'EUR',
    this.unit,
    this.durationMinutes,
  });

  final String id;
  final String name;
  final String? description;

  /// Whole cents, never a decimal: 4999 is EUR 49,99.
  final int priceCents;
  final String currency;

  /// What the price refers to, e.g. "pro Auftrag".
  final String? unit;

  /// Roughly how long the provider expects to need. Null when they did not
  /// say, and then the app says nothing either.
  final int? durationMinutes;
}

/// What a customer may see about one provider before booking them.
///
/// The shape of this class is the shape of `provider_offer()`: no phone
/// number, no address, no documents. A provider only becomes reachable in
/// person once they accept the job.
class ProviderOffer {
  const ProviderOffer({
    required this.providerId,
    required this.verificationStatus,
    required this.prices,
    this.displayName,
    this.description,
    this.city,
    this.profileImageUrl,
    this.ratingAverage,
    this.ratingCount = 0,
  });

  final String providerId;
  final String? displayName;
  final String? description;
  final String? city;
  final String? profileImageUrl;

  /// Only ever what the server says. Everyone in this list is verified,
  /// because the backend refuses to return anybody else — but the app still
  /// reads the flag rather than assuming it.
  final ProviderVerificationStatus verificationStatus;

  /// What this provider's reviews add up to. Null while nobody has rated
  /// them, which is a different fact from a bad rating.
  final double? ratingAverage;
  final int ratingCount;

  bool get hasRating => ratingCount > 0 && ratingAverage != null;

  /// Cheapest first, in the order the provider arranged them.
  final List<ProviderPrice> prices;

  /// The backend returns one row per price option, repeating the provider's
  /// details on each. This folds them back into one provider.
  static ProviderOffer? fromRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return null;
    final first = rows.first;
    return ProviderOffer(
      providerId: first['provider_id'] as String,
      displayName: first['display_name'] as String?,
      description: first['description'] as String?,
      city: first['city'] as String?,
      profileImageUrl: first['profile_image_url'] as String?,
      verificationStatus: ProviderVerificationStatus.fromDb(
        first['verification_status'] as String?,
      ),
      ratingAverage: (first['rating_average'] as num?)?.toDouble(),
      ratingCount: (first['rating_count'] as num?)?.toInt() ?? 0,
      prices: [
        for (final row in rows)
          if (row['price_id'] case final String id)
            ProviderPrice(
              id: id,
              name: row['price_name'] as String? ?? '',
              description: row['price_description'] as String?,
              priceCents: (row['price_cents'] as num?)?.toInt() ?? 0,
              currency: row['currency'] as String? ?? 'EUR',
              unit: row['unit'] as String?,
              durationMinutes: (row['duration_minutes'] as num?)?.toInt(),
            ),
      ],
    );
  }
}
