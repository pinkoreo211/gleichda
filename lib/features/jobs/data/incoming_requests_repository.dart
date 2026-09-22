import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/jobs/domain/incoming_request.dart';

/// The requests a provider has received.
///
/// No id is passed in: the backend works out which provider profile belongs
/// to the caller. A provider therefore cannot ask for another provider's
/// requests, however the app is called. Throws [AppFailure] on errors.
abstract interface class IncomingRequestsRepository {
  /// Newest first.
  Future<List<IncomingRequest>> myIncomingRequests();
}

final incomingRequestsRepositoryProvider = Provider<IncomingRequestsRepository>(
  (ref) =>
      SupabaseIncomingRequestsRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseIncomingRequestsRepository implements IncomingRequestsRepository {
  SupabaseIncomingRequestsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<IncomingRequest>> myIncomingRequests() async {
    try {
      final rows = await _client.rpc<List<dynamic>>('requests_for_me');
      return [
        for (final row in rows.whereType<Map<String, dynamic>>())
          IncomingRequest.fromJson(row),
      ];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
