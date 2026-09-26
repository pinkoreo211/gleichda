import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/booking/data/booking_repository.dart';
import 'package:app/features/booking/domain/booking_draft.dart';
import 'package:app/features/booking/domain/provider_offer.dart';
import 'package:app/features/booking/domain/service_suggestion.dart';
import 'package:app/features/jobs/application/my_jobs.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/requests/application/my_requests.dart';

/// The booking being put together, across the screens of the flow.
///
/// Not `autoDispose`: the whole point is that it survives moving from one
/// screen to the next. [start] clears it, so a new booking never inherits
/// half of the last one.
class BookingController extends Notifier<BookingDraft> {
  @override
  BookingDraft build() => const BookingDraft();

  void start(String description) =>
      state = BookingDraft(description: description);

  /// Choosing a different service invalidates the provider and the price:
  /// they were picked for the old one.
  void chooseService(ServiceSuggestion service) =>
      state = state.copyWith(service: service, clearProvider: true);

  void setPlace({
    required String address,
    required String postalCode,
    required String city,
  }) => state = state.copyWith(
    address: address,
    postalCode: postalCode,
    city: city,
    // A different town may mean different providers entirely.
    clearProvider: true,
  );

  void chooseProvider(ProviderOffer provider) =>
      state = state.copyWith(provider: provider, clearPrice: true);

  void choosePrice(ProviderPrice price) => state = state.copyWith(price: price);

  void chooseTime(DateTime wantedAt) =>
      state = state.copyWith(wantedAt: wantedAt);

  /// Sends the booking. Returns what the backend created.
  ///
  /// Throws [AppFailure] on errors, and [StateError] if a screen calls this
  /// with something still missing — that would be a bug in the flow, not
  /// something to show the customer.
  Future<BookingResult> submit() async {
    final draft = state;
    if (!draft.canSubmit) {
      throw StateError('The booking is not complete');
    }

    final result = await ref
        .read(bookingRepositoryProvider)
        .createBooking(
          description: draft.description,
          serviceId: draft.service!.serviceId,
          providerId: draft.provider!.providerId,
          priceId: draft.price!.id,
          wantedAt: draft.wantedAt!,
          address: draft.address,
          postalCode: draft.postalCode,
          city: draft.city,
        );

    // The booking list and the job list both changed. Re-read rather than
    // patch: what the backend stored is the truth about a request.
    ref.invalidate(myRequestsProvider);
    ref.invalidate(myJobsProvider);
    return result;
  }
}

final bookingProvider = NotifierProvider<BookingController, BookingDraft>(
  BookingController.new,
);

/// Catalog services that might match what the customer wrote.
///
/// Empty is a real answer, not a failure: the screen then asks which
/// service they mean instead of guessing at one.
final serviceSuggestionsProvider = FutureProvider.autoDispose
    .family<List<ServiceSuggestion>, String>((ref, text) async {
      return ref.watch(bookingRepositoryProvider).suggestServices(text);
    });

/// Which providers can be booked for the service and place chosen so far.
///
/// `autoDispose` so going back, changing the town and returning asks again.
final bookableProvidersProvider =
    FutureProvider.autoDispose<List<ProviderMatch>>((ref) async {
      final draft = ref.watch(bookingProvider);
      final service = draft.service;
      if (service == null) return const [];
      return ref
          .watch(bookingRepositoryProvider)
          .bookableProviders(
            serviceId: service.serviceId,
            city: draft.city.trim().isEmpty ? null : draft.city.trim(),
          );
    });

/// One provider's details and real prices for the chosen service.
final providerOfferProvider = FutureProvider.autoDispose
    .family<ProviderOffer?, String>((ref, providerId) async {
      final service = ref.watch(bookingProvider).service;
      if (service == null) return null;
      return ref
          .watch(bookingRepositoryProvider)
          .offerOf(providerId: providerId, serviceId: service.serviceId);
    });
