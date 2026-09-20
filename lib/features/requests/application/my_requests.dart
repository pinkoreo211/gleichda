import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/requests/data/service_request_repository.dart';
import 'package:app/features/requests/domain/service_request.dart';

/// The signed-in customer's own requests, newest first. Empty when signed
/// out, so no other account's data can ever appear.
final myRequestsProvider = FutureProvider<List<ServiceRequest>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(serviceRequestRepositoryProvider).myRequests();
});
