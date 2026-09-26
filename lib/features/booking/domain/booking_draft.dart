import 'package:app/features/booking/domain/provider_offer.dart';
import 'package:app/features/booking/domain/service_suggestion.dart';

/// Everything the customer has chosen so far, while they are still
/// choosing.
///
/// Nothing in here has been written anywhere: the whole booking reaches the
/// backend in one call at the end, so leaving the flow half-way leaves no
/// stray request behind for a provider to find.
///
/// Deliberately one step at a time, in the order the screens ask: service,
/// then place, then provider, then price, then time. Each [isReadyFor]
/// getter says what the next screen needs, so no screen has to guess
/// whether it may open.
class BookingDraft {
  const BookingDraft({
    this.description = '',
    this.service,
    this.address = '',
    this.postalCode = '',
    this.city = '',
    this.provider,
    this.price,
    this.wantedAt,
  });

  /// What the customer typed at the very start, kept word for word. It
  /// travels all the way into the request, because the provider reading it
  /// wants the sentence, not the category.
  final String description;

  final ServiceSuggestion? service;

  final String address;
  final String postalCode;
  final String city;

  final ProviderOffer? provider;
  final ProviderPrice? price;

  /// The time the customer would like. Not an appointment: nothing has
  /// checked whether the provider is free, and the app must not pretend
  /// otherwise.
  final DateTime? wantedAt;

  /// A town is the least the matching needs; the street is for the person
  /// who will stand in front of the door.
  bool get hasPlace => city.trim().isNotEmpty;

  bool get canPickProvider => service != null && hasPlace;

  bool get canSchedule => canPickProvider && provider != null && price != null;

  bool get canSubmit => canSchedule && wantedAt != null;

  /// "Wien 1190", or whichever half of it exists.
  String get placeLabel => [
    if (postalCode.trim().isNotEmpty) postalCode.trim(),
    if (city.trim().isNotEmpty) city.trim(),
  ].join(' ');

  BookingDraft copyWith({
    String? description,
    ServiceSuggestion? service,
    String? address,
    String? postalCode,
    String? city,
    ProviderOffer? provider,
    ProviderPrice? price,
    DateTime? wantedAt,
    bool clearProvider = false,
    bool clearPrice = false,
  }) => BookingDraft(
    description: description ?? this.description,
    service: service ?? this.service,
    address: address ?? this.address,
    postalCode: postalCode ?? this.postalCode,
    city: city ?? this.city,
    provider: clearProvider ? null : (provider ?? this.provider),
    price: clearPrice || clearProvider ? null : (price ?? this.price),
    wantedAt: wantedAt ?? this.wantedAt,
  );
}

/// What came back once the booking was written.
class BookingResult {
  const BookingResult({required this.requestId, required this.contactId});

  final String requestId;

  /// The job itself — the same id the status flow, the chat and a later
  /// review all hang off.
  final String contactId;
}
