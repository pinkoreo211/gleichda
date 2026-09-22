import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/jobs/domain/incoming_request.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';

/// The requests a provider has received.
///
/// No id is passed in: the backend works out which provider profile belongs
/// to the caller. A provider therefore cannot ask for another provider's
/// requests, however the app is called. Throws [AppFailure] on errors.
abstract interface class IncomingRequestsRepository {
  /// Newest first.
  Future<List<IncomingRequest>> myIncomingRequests();

  /// Answers one received request with [status], which must be
  /// [RequestContactStatus.accepted] or [RequestContactStatus.declined].
  ///
  /// The backend refuses an answer to a request that is not this provider's
  /// or that was already answered, so the decision cannot be taken twice.
  Future<void> respond({
    required String contactId,
    required RequestContactStatus status,
  });
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

  @override
  Future<void> respond({
    required String contactId,
    required RequestContactStatus status,
  }) async {
    try {
      await _client.rpc<dynamic>(
        'respond_to_request',
        params: {'target_contact_id': contactId, 'new_status': status.name},
      );
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
