import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/requests/application/my_requests.dart';
import 'package:app/features/requests/data/service_request_repository.dart';
import 'package:app/features/requests/domain/request_timing.dart';
import 'package:app/features/requests/domain/service_request.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/domain/service_category.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';

/// The request the customer is currently writing.
///
/// Lives above both screens so the home screen's text survives the step into
/// the request screen, and so going back never loses what was typed.
final serviceRequestDraftProvider =
    NotifierProvider<ServiceRequestDraftController, ServiceRequestDraft>(
      ServiceRequestDraftController.new,
    );

class ServiceRequestDraftController extends Notifier<ServiceRequestDraft> {
  @override
  ServiceRequestDraft build() => const ServiceRequestDraft();

  /// Starts a new request, either from typed text or from a category card.
  void start({
    String description = '',
    ServiceCategory? category,
    Service? service,
  }) {
    state = ServiceRequestDraft(
      description: description,
      category: category,
      service: service,
    );
  }

  void setDescription(String description) =>
      state = state.copyWith(description: description);

  /// Passing null clears the category: "no category" is a valid choice.
  void setCategory(ServiceCategory? category) => state = category == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(category: category);

  void setTiming(RequestTiming timing, {DateTime? date}) {
    state = timing == RequestTiming.onDate
        ? state.copyWith(timing: timing, preferredDate: date)
        : state.copyWith(timing: timing, clearPreferredDate: true);
  }

  void setLocation(String label) =>
      state = state.copyWith(locationLabel: label);

  void setCity(String city) => state = state.copyWith(city: city);

  void setPostalCode(String postalCode) =>
      state = state.copyWith(postalCode: postalCode);

  void clear() => state = const ServiceRequestDraft();

  /// Stores the draft on the server and returns the saved request, so the
  /// next screen can look for providers by its id instead of guessing.
  ///
  /// Returns null when the draft was empty or nobody is signed in. Throws
  /// [AppFailure] so the screen can show the usual message.
  Future<ServiceRequest?> submit() async {
    if (!state.isSubmittable) return null;
    if (ref.read(currentUserIdProvider) == null) return null;

    final saved = await ref
        .read(serviceRequestRepositoryProvider)
        .create(state);

    if (ref.mounted) {
      ref.invalidate(myRequestsProvider);
      state = const ServiceRequestDraft();
    }
    return saved;
  }
}
