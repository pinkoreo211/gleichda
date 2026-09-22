import 'package:app/features/requests/domain/request_timing.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/domain/service_category.dart';

/// A request while the customer is still writing it.
///
/// Separate from a stored request because a draft has no id and no creation
/// time yet — the server assigns both — and because it may be incomplete at
/// any moment.
class ServiceRequestDraft {
  const ServiceRequestDraft({
    this.description = '',
    this.category,
    this.service,
    this.timing = RequestTiming.asap,
    this.preferredDate,
    this.locationLabel,
  });

  /// Exactly what the customer typed; never narrowed down by the app.
  final String description;

  final ServiceCategory? category;

  /// The catalog service, once it is known. Set when the customer picked
  /// one; the AI step fills it in for free text later.
  final Service? service;

  final RequestTiming timing;
  final DateTime? preferredDate;
  final String? locationLabel;

  /// The only requirement for creating a request: a description.
  /// Category, location and date stay optional on purpose.
  bool get isSubmittable => description.trim().isNotEmpty;

  ServiceRequestDraft copyWith({
    String? description,
    ServiceCategory? category,
    bool clearCategory = false,
    Service? service,
    RequestTiming? timing,
    DateTime? preferredDate,
    bool clearPreferredDate = false,
    String? locationLabel,
  }) {
    return ServiceRequestDraft(
      description: description ?? this.description,
      category: clearCategory ? null : (category ?? this.category),
      service: service ?? this.service,
      timing: timing ?? this.timing,
      preferredDate: clearPreferredDate
          ? null
          : (preferredDate ?? this.preferredDate),
      locationLabel: locationLabel ?? this.locationLabel,
    );
  }
}
