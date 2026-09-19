import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/requests/application/my_requests.dart';
import 'package:app/features/requests/data/service_request_repository.dart';
import 'package:app/features/requests/domain/request_timing.dart';
import 'package:app/features/requests/domain/service_category.dart';
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
  void start({String description = '', ServiceCategory? category}) {
    state = ServiceRequestDraft(description: description, category: category);
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

  void clear() => state = const ServiceRequestDraft();

  /// Saves the draft. Returns `false` if it was empty or storing failed.
  ///
  /// The request is stored on this device only; nothing is sent to providers
  /// yet. Throws [AppFailure] so the screen can show the usual message.
  Future<bool> submit() async {
    if (!state.isSubmittable) return false;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return false;

    final now = DateTime.now();
    final request = state.toRequest(
      id: 'req-${now.microsecondsSinceEpoch}',
      createdAt: now,
    );
    await ref.read(serviceRequestRepositoryProvider).save(userId, request);

    if (ref.mounted) {
      ref.invalidate(myRequestsProvider);
      state = const ServiceRequestDraft();
    }
    return true;
  }
}
