import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/features/profile/domain/user_profile.dart';

/// The signed-in user's display name, or `null` when signed out or when the
/// account has none yet. Re-reads when the account changes.
final myDisplayNameProvider = FutureProvider<String?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).myDisplayName();
});

/// Name and picture together, for the screen that edits them and for the
/// profile tab that shows them.
///
/// Empty when signed out, so no other account's face can appear.
final myProfileProvider = FutureProvider<UserProfile>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const UserProfile();
  return ref.watch(profileRepositoryProvider).myProfile();
});
