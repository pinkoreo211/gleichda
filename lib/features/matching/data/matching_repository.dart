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

  /// Providers for a saved request. Only the request id is sent: the server
  /// reads the service and the city from the stored request itself, so the
  /// phone cannot widen its own search.
  Future<List<ProviderMatch>> providersForRequest(String requestId);

  /// Hands the request to one provider. The server checks that the request
  /// belongs to the caller and that the provider really offers the service.
  Future<void> sendRequestToProvider({
    required String requestId,
    required String providerId,
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
      return _parse(rows);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<List<ProviderMatch>> providersForRequest(String requestId) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'find_providers_for_request',
        params: {'target_request_id': requestId},
      );
      return _parse(rows);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> sendRequestToProvider({
    required String requestId,
    required String providerId,
  }) async {
    try {
      await _client.rpc<dynamic>(
        'send_request_to_provider',
        params: {
          'target_request_id': requestId,
          'target_provider_id': providerId,
        },
      );
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  List<ProviderMatch> _parse(List<dynamic> rows) => [
    for (final row in rows.whereType<Map<String, dynamic>>())
      ProviderMatch.fromJson(row),
  ];
}
