import 'package:app/features/requests/domain/request_contact_status.dart';

/// One accepted job, seen from whichever side is looking.
///
/// This is exactly what the backend hands out: the other person's name, what
/// the work is, where it is and how far along it is. No email, no phone, no
/// address.
class Job {
  const Job({
    required this.contactId,
    required this.requestId,
    required this.providerId,
    required this.viewerIsCustomer,
    required this.status,
    required this.description,
    required this.updatedAt,
    this.otherName,
    this.serviceName,
    this.serviceNameEn,
    this.city,
    this.postalCode,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.customerConfirmedAt,
  });

  final String contactId;
  final String requestId;
  final String providerId;

  /// Which side the signed-in person is on. Decides which step they may
  /// take next — and the backend decides it again, independently.
  final bool viewerIsCustomer;

  final RequestContactStatus status;

  /// What the customer typed, unchanged.
  final String description;

  final String? otherName;
  final String? serviceName;
  final String? serviceNameEn;
  final String? city;
  final String? postalCode;

  /// The time the two of them agreed on. Null until they do — the
  /// customer's "as soon as possible" is a wish, not an appointment.
  final DateTime? scheduledAt;

  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? customerConfirmedAt;

  final DateTime updatedAt;

  /// Falls back to German, because the catalog is German-first and a
  /// missing translation must never blank out the name.
  String? serviceFor(String language) {
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

  /// The step this side may take next, or null while it is the other
  /// person's turn. The backend refuses anything else regardless.
  RequestContactStatus? get nextStep => switch (status) {
    // Either of them may record the time they agreed on.
    RequestContactStatus.accepted => RequestContactStatus.scheduled,
    RequestContactStatus.scheduled when !viewerIsCustomer =>
      RequestContactStatus.onTheWay,
    RequestContactStatus.onTheWay when !viewerIsCustomer =>
      RequestContactStatus.inProgress,
    RequestContactStatus.inProgress when !viewerIsCustomer =>
      RequestContactStatus.completed,
    RequestContactStatus.completed when viewerIsCustomer =>
      RequestContactStatus.customerConfirmed,
    _ => null,
  };

  static Job fromJson(Map<String, dynamic> json) => Job(
    contactId: json['contact_id'] as String,
    requestId: json['request_id'] as String,
    providerId: json['provider_id'] as String,
    viewerIsCustomer: json['viewer_is_customer'] as bool? ?? true,
    status:
        RequestContactStatus.fromDb(json['status'] as String?) ??
        RequestContactStatus.accepted,
    description: json['description'] as String? ?? '',
    otherName: json['other_name'] as String?,
    serviceName: json['service_name'] as String?,
    serviceNameEn: json['service_name_en'] as String?,
    city: json['city'] as String?,
    postalCode: json['postal_code'] as String?,
    scheduledAt: DateTime.tryParse(json['scheduled_at'] as String? ?? ''),
    startedAt: DateTime.tryParse(json['started_at'] as String? ?? ''),
    completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
    customerConfirmedAt: DateTime.tryParse(
      json['customer_confirmed_at'] as String? ?? '',
    ),
    updatedAt:
        DateTime.tryParse(json['updated_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
