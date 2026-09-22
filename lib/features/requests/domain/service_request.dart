import 'package:app/features/requests/domain/request_timing.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/domain/service_category.dart';

/// One customer request: "what do you need?" in the customer's own words,
/// plus whatever details they chose to add.
///
/// [originalDescription] is deliberately kept exactly as typed and is never
/// narrowed down by the app. A later AI step reads it and fills the
/// `detected*` and `estimated*` fields; until then those stay null, and the
/// app never invents a price.
class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.originalDescription,
    required this.createdAt,
    this.category,
    this.service,
    this.timing = RequestTiming.asap,
    this.preferredDate,
    this.locationLabel,
    this.city,
    this.postalCode,
    this.detectedService,
    this.aiConfidence,
    this.estimatedPriceMinCents,
    this.estimatedPriceMaxCents,
    this.estimatedDurationMinutes,
    this.imagePaths = const [],
    this.videoPaths = const [],
    this.sentToProviderCount = 0,
  });

  final String id;

  /// What the customer typed, unchanged.
  final String originalDescription;

  final DateTime createdAt;

  /// Optional: the customer may pick one, or leave it to the AI.
  final ServiceCategory? category;

  /// The concrete catalog service, once known. Null while the request is
  /// only free text.
  final Service? service;

  final RequestTiming timing;

  /// Only set when [timing] is [RequestTiming.onDate].
  final DateTime? preferredDate;

  /// Human-readable place, e.g. "Wien, 1070". Coordinates follow with the
  /// map integration.
  final String? locationLabel;

  /// Where the work is. Kept with the request so matching asks the database,
  /// not the phone, where to look.
  final String? city;
  final String? postalCode;

  /// True once the request names a service, which is what matching needs.
  bool get canBeMatched => service != null;

  /// How many providers this request has been sent to. Counted by the
  /// backend over rows the customer is allowed to see, so it is never a
  /// guess made on the phone.
  final int sentToProviderCount;

  bool get wasSent => sentToProviderCount > 0;

  // --- Filled by the AI step later; always null for now. ---

  /// The concrete service the AI recognised, e.g. "Waschmaschinen-Reparatur".
  final String? detectedService;

  /// How sure the AI is, 0.0 to 1.0.
  final double? aiConfidence;

  /// Non-binding price range, in whole cents (money is never a double).
  final int? estimatedPriceMinCents;
  final int? estimatedPriceMaxCents;

  final int? estimatedDurationMinutes;

  // --- Attachments; local file paths until storage exists. ---

  final List<String> imagePaths;
  final List<String> videoPaths;

  ServiceRequest copyWith({
    String? originalDescription,
    ServiceCategory? category,
    bool clearCategory = false,
    RequestTiming? timing,
    DateTime? preferredDate,
    bool clearPreferredDate = false,
    String? locationLabel,
    int? sentToProviderCount,
  }) {
    return ServiceRequest(
      id: id,
      originalDescription: originalDescription ?? this.originalDescription,
      createdAt: createdAt,
      category: clearCategory ? null : (category ?? this.category),
      service: service,
      timing: timing ?? this.timing,
      preferredDate: clearPreferredDate
          ? null
          : (preferredDate ?? this.preferredDate),
      locationLabel: locationLabel ?? this.locationLabel,
      city: city,
      postalCode: postalCode,
      detectedService: detectedService,
      aiConfidence: aiConfidence,
      estimatedPriceMinCents: estimatedPriceMinCents,
      estimatedPriceMaxCents: estimatedPriceMaxCents,
      estimatedDurationMinutes: estimatedDurationMinutes,
      imagePaths: imagePaths,
      videoPaths: videoPaths,
      sentToProviderCount: sentToProviderCount ?? this.sentToProviderCount,
    );
  }

  static ServiceRequest fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as String,
      originalDescription: json['original_description'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      // Loaded together with the request, so the list can show the category
      // name without a second query. Null when none was chosen.
      category: switch (json['service_categories']) {
        final Map<String, dynamic> row => ServiceCategory.fromJson(row),
        _ => null,
      },
      service: switch (json['services']) {
        final Map<String, dynamic> row => Service.fromJson(row),
        _ => null,
      },
      timing: RequestTiming.byName(json['timing'] as String?),
      preferredDate: DateTime.tryParse(json['preferred_date'] as String? ?? ''),
      locationLabel: json['location_label'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      detectedService: json['detected_service'] as String?,
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      estimatedPriceMinCents: json['estimated_price_min_cents'] as int?,
      estimatedPriceMaxCents: json['estimated_price_max_cents'] as int?,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int?,
      imagePaths:
          (json['image_paths'] as List?)?.whereType<String>().toList() ??
          const [],
      videoPaths:
          (json['video_paths'] as List?)?.whereType<String>().toList() ??
          const [],
      sentToProviderCount: _countOf(json['request_contacts']),
    );
  }

  /// PostgREST returns a counted relation as `[{"count": 2}]`.
  static int _countOf(Object? value) => switch (value) {
    final List<dynamic> rows when rows.isNotEmpty => switch (rows.first) {
      final Map<String, dynamic> row => (row['count'] as num?)?.toInt() ?? 0,
      _ => 0,
    },
    _ => 0,
  };
}
