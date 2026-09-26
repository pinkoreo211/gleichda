import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/request_timing.dart';

/// A customer request that reached this provider.
///
/// This is exactly what the backend hands a provider and nothing more: no
/// customer id, no email, none of the AI columns. The shape of this class
/// is the shape of the function that fills it, so a field that is not here
/// cannot appear by accident.
class IncomingRequest {
  const IncomingRequest({
    required this.contactId,
    required this.requestId,
    required this.description,
    required this.sentAt,
    this.status = RequestContactStatus.sent,
    this.serviceName,
    this.serviceNameEn,
    this.city,
    this.postalCode,
    this.timing = RequestTiming.asap,
    this.preferredDate,
    this.customerName,
    this.priceCents,
    this.currency = 'EUR',
    this.requestedAt,
  });

  final String contactId;
  final String requestId;

  /// What the customer typed, unchanged.
  final String description;

  final DateTime sentAt;

  /// What this provider answered. Only the backend ever changes it, and
  /// only once — the app shows it, it does not decide it.
  final RequestContactStatus status;

  /// The catalog service the request is about. Null only if the service was
  /// removed from the catalog afterwards.
  final String? serviceName;
  final String? serviceNameEn;

  final String? city;
  final String? postalCode;

  final RequestTiming timing;
  final DateTime? preferredDate;

  /// The name the customer chose to show. Null when they stored none.
  final String? customerName;

  /// What the customer booked at, when they came through the booking flow.
  /// Null for an open request — accepting that one agrees to no price.
  final int? priceCents;
  final String currency;

  /// The time the customer asked for. A wish, not an appointment.
  final DateTime? requestedAt;

  bool get isBooking => priceCents != null;

  /// Falls back to German, because the catalog is German-first and a
  /// missing translation must never blank out the name.
  String? nameFor(String language) {
    if (language == 'en') {
      final english = serviceNameEn;
      if (english != null && english.isNotEmpty) return english;
    }
    return serviceName;
  }

  /// "Wien, 1070" — whichever parts the customer gave.
  String? get place {
    final parts = [
      if (city != null && city!.isNotEmpty) city!,
      if (postalCode != null && postalCode!.isNotEmpty) postalCode!,
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  static IncomingRequest fromJson(Map<String, dynamic> json) => IncomingRequest(
    contactId: json['contact_id'] as String,
    requestId: json['request_id'] as String,
    description: json['description'] as String? ?? '',
    sentAt:
        DateTime.tryParse(json['sent_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    status:
        RequestContactStatus.fromDb(json['status'] as String?) ??
        RequestContactStatus.sent,
    serviceName: json['service_name'] as String?,
    serviceNameEn: json['service_name_en'] as String?,
    city: json['city'] as String?,
    postalCode: json['postal_code'] as String?,
    timing: RequestTiming.byName(json['timing'] as String?),
    preferredDate: DateTime.tryParse(json['preferred_date'] as String? ?? ''),
    customerName: json['customer_name'] as String?,
    priceCents: (json['price_cents'] as num?)?.toInt(),
    currency: json['currency'] as String? ?? 'EUR',
    requestedAt: DateTime.tryParse(json['requested_at'] as String? ?? ''),
  );
}
