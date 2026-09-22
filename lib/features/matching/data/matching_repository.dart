import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/matching/domain/provider_match.dart';

/// Finds providers for a service.
///
/// Goes through one backend function rather than reading the provider
/// tables: those stay locked to their owner, and the function's return type
/// is the entire contract of what a customer may see.
///
/// Throws [AppFailure] on errors.
abstract interface class MatchingRepository {
  /// Verified providers first, then the cheapest. No score and no weighting
  /// — ranking on fields that are still empty would only look clever.
  Future<List<ProviderMatch>> providersForService(
    String serviceId, {
    String? city,
  });
}

final matchingRepositoryProvider = Provider<MatchingRepository>(
  (ref) => SupabaseMatchingRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseMatchingRepository implements MatchingRepository {
  SupabaseMatchingRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ProviderMatch>> providersForService(
    String serviceId, {
    String? city,
  }) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'find_providers_for_service',
        params: {
          'requested_service_id': serviceId,
          // Null means "anywhere": the customer has not told us where they
          // are yet. The backend filters as soon as a city is passed.
          'requested_city': city,
        },
      );
      return [
        for (final row in rows.whereType<Map<String, dynamic>>())
          ProviderMatch.fromJson(row),
      ];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
