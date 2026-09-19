import 'package:app/features/requests/domain/request_timing.dart';
import 'package:app/features/requests/domain/service_category.dart';

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
    this.timing = RequestTiming.asap,
    this.preferredDate,
    this.locationLabel,
    this.detectedService,
    this.aiConfidence,
    this.estimatedPriceMinCents,
    this.estimatedPriceMaxCents,
    this.estimatedDurationMinutes,
    this.imagePaths = const [],
    this.videoPaths = const [],
  });

  final String id;

  /// What the customer typed, unchanged.
  final String originalDescription;

  final DateTime createdAt;

  /// Optional: the customer may pick one, or leave it to the AI.
  final ServiceCategory? category;

  final RequestTiming timing;

  /// Only set when [timing] is [RequestTiming.onDate].
  final DateTime? preferredDate;

  /// Human-readable place, e.g. "Wien, 1070". Coordinates follow with the
  /// map integration.
  final String? locationLabel;

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
  }) {
    return ServiceRequest(
      id: id,
      originalDescription: originalDescription ?? this.originalDescription,
      createdAt: createdAt,
      category: clearCategory ? null : (category ?? this.category),
      timing: timing ?? this.timing,
      preferredDate: clearPreferredDate
          ? null
          : (preferredDate ?? this.preferredDate),
      locationLabel: locationLabel ?? this.locationLabel,
      detectedService: detectedService,
      aiConfidence: aiConfidence,
      estimatedPriceMinCents: estimatedPriceMinCents,
      estimatedPriceMaxCents: estimatedPriceMaxCents,
      estimatedDurationMinutes: estimatedDurationMinutes,
      imagePaths: imagePaths,
      videoPaths: videoPaths,
    );
  }

  /// Field names match the columns the backend table will use, so moving
  /// from device storage to Supabase does not change this shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'original_description': originalDescription,
    'created_at': createdAt.toIso8601String(),
    'category': category?.name,
    'timing': timing.name,
    'preferred_date': preferredDate?.toIso8601String(),
    'location_label': locationLabel,
    'detected_service': detectedService,
    'ai_confidence': aiConfidence,
    'estimated_price_min_cents': estimatedPriceMinCents,
    'estimated_price_max_cents': estimatedPriceMaxCents,
    'estimated_duration_minutes': estimatedDurationMinutes,
    'image_paths': imagePaths,
    'video_paths': videoPaths,
  };

  static ServiceRequest fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as String,
      originalDescription: json['original_description'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      category: ServiceCategory.byName(json['category'] as String?),
      timing: RequestTiming.byName(json['timing'] as String?),
      preferredDate: DateTime.tryParse(json['preferred_date'] as String? ?? ''),
      locationLabel: json['location_label'] as String?,
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
    );
  }
}
