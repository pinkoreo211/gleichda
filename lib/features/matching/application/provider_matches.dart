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
