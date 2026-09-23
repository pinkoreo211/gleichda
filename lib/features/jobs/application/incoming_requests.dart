import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/jobs/data/incoming_requests_repository.dart';
import 'package:app/features/jobs/domain/incoming_request.dart';

/// The requests handed to the signed-in provider, newest first. Empty when
/// signed out, so no other account's requests can ever appear.
///
/// `autoDispose` on purpose: without it the list is read once and then kept
/// for the whole run of the app, so a provider who leaves the app open
/// never learns that a new request arrived. Disposing when nobody is
/// looking means every return to the provider's home asks the server again.
/// While the screen is open, pull to refresh.
final myIncomingRequestsProvider =
    FutureProvider.autoDispose<List<IncomingRequest>>((ref) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return const [];
      return ref.watch(incomingRequestsRepositoryProvider).myIncomingRequests();
    });
