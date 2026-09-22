import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/matching/data/matching_repository.dart';
import 'package:app/features/matching/domain/provider_match.dart';

/// The providers who offer one service.
///
/// No city is passed yet: the customer has not told the app where they are.
/// The backend already filters by city as soon as one is given, so adding
/// location later is a one-line change here, not a rewrite.
final providerMatchesProvider =
    FutureProvider.family<List<ProviderMatch>, String>((ref, serviceId) {
      return ref
          .watch(matchingRepositoryProvider)
          .providersForService(serviceId);
    });

/// The providers for one saved request.
///
/// Takes the request's id, not its contents: the service and the city come
/// from the stored request on the server. That is what makes the result the
/// database's answer rather than the app's.
final requestMatchesProvider =
    FutureProvider.family<List<ProviderMatch>, String>((ref, requestId) {
      return ref
          .watch(matchingRepositoryProvider)
          .providersForRequest(requestId);
    });
