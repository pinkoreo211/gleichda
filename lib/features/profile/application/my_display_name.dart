import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/profile/data/profile_repository.dart';

/// The signed-in user's display name, or `null` when signed out or when the
/// account has none yet. Re-reads when the account changes.
final myDisplayNameProvider = FutureProvider<String?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).myDisplayName();
});
