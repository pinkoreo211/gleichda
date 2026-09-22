import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/jobs/data/incoming_requests_repository.dart';
import 'package:app/features/jobs/domain/incoming_request.dart';

/// The requests handed to the signed-in provider, newest first. Empty when
/// signed out, so no other account's requests can ever appear.
final myIncomingRequestsProvider = FutureProvider<List<IncomingRequest>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(incomingRequestsRepositoryProvider).myIncomingRequests();
});
