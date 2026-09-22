import 'package:app/features/provider/domain/provider_profile.dart';

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
    this.description,
    this.city,
    this.lowestPriceCents,
    this.currency = 'EUR',
    this.alreadyContacted = false,
  });

  final String providerId;

  /// What the provider chose to be called. Null if they stored no name.
  final String? displayName;

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

  /// Whether this request already reached this provider. Comes from the
  /// server, so it is still right after the app was closed and reopened.
  final bool alreadyContacted;

  static ProviderMatch fromJson(Map<String, dynamic> json) => ProviderMatch(
    providerId: json['provider_id'] as String,
    displayName: json['display_name'] as String?,
    description: json['description'] as String?,
    city: json['city'] as String?,
    verificationStatus: ProviderVerificationStatus.fromDb(
      json['verification_status'] as String?,
    ),
    lowestPriceCents: (json['lowest_price_cents'] as num?)?.toInt(),
    currency: json['currency'] as String? ?? 'EUR',
    alreadyContacted: json['already_contacted'] as bool? ?? false,
  );
}
