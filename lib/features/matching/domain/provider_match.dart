import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';

/// A provider who offers a service, as a customer may see them.
///
/// This is deliberately everything the backend will hand out for matching:
/// no phone number, no address, no documents. The shape of this class is the
/// shape of the function that fills it.
class ProviderMatch {
  const ProviderMatch({
    required this.providerId,
    required this.verificationStatus,
    this.displayName,
    this.avatarUrl,
    this.description,
    this.city,
    this.lowestPriceCents,
    this.currency = 'EUR',
    this.contactStatus,
    this.ratingAverage,
    this.ratingCount = 0,
  });

  final String providerId;

  /// What the provider chose to be called. Null if they stored no name.
  final String? displayName;

  /// Their picture, or null. Never a placeholder photograph: a stock face
  /// beside a real name would be worse than no face.
  final String? avatarUrl;

  final String? description;
  final String? city;

  /// Only ever what the server says. The app must not imply a check that
  /// has not happened.
  final ProviderVerificationStatus verificationStatus;

  /// Cheapest active price for this service, or null when the provider has
  /// not priced it — then the app says "price on request" instead of
  /// inventing a number.
  final int? lowestPriceCents;

  final String currency;

  /// What this provider answered to this request. Null means the request
  /// never reached them. Comes from the server, so it is still right after
  /// the app was closed and reopened.
  final RequestContactStatus? contactStatus;

  bool get alreadyContacted => contactStatus != null;

  /// What this provider's reviews add up to. Null while nobody has rated
  /// them — a different fact from a bad rating, and shown as such.
  final double? ratingAverage;
  final int ratingCount;

  bool get hasRating => ratingCount > 0 && ratingAverage != null;

  static ProviderMatch fromJson(Map<String, dynamic> json) => ProviderMatch(
    providerId: json['provider_id'] as String,
    displayName: json['display_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    description: json['description'] as String?,
    city: json['city'] as String?,
    verificationStatus: ProviderVerificationStatus.fromDb(
      json['verification_status'] as String?,
    ),
    lowestPriceCents: (json['lowest_price_cents'] as num?)?.toInt(),
    currency: json['currency'] as String? ?? 'EUR',
    contactStatus: RequestContactStatus.fromDb(
      json['contact_status'] as String?,
    ),
    ratingAverage: (json['rating_average'] as num?)?.toDouble(),
    ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
  );
}
