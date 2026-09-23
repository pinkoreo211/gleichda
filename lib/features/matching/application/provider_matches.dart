import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/matching/data/matching_repository.dart';
import 'package:app/features/matching/domain/provider_match.dart';

/// The providers who offer one service.
///
/// No city is passed yet: the customer has not told the app where they are.
/// The backend already filters by city as soon as one is given, so adding
/// location later is a one-line change here, not a rewrite.
/// `autoDispose` on every provider in this file: a result kept for the whole
/// run of the app would still claim "request sent" after the provider had
/// long since answered — and would survive a sign-out, which is no state to
/// hand to whoever signs in next.
final providerMatchesProvider = FutureProvider.autoDispose
    .family<List<ProviderMatch>, String>((ref, serviceId) {
      return ref
          .watch(matchingRepositoryProvider)
          .providersForService(serviceId);
    });

/// The providers for one saved request.
///
/// Takes the request's id, not its contents: the service and the city come
/// from the stored request on the server. That is what makes the result the
/// database's answer rather than the app's.
final requestMatchesProvider = FutureProvider.autoDispose
    .family<List<ProviderMatch>, String>((ref, requestId) {
      return ref
          .watch(matchingRepositoryProvider)
          .providersForRequest(requestId);
    });
