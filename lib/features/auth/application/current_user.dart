import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/data/auth_repository.dart';

/// The signed-in user's id, or `null` when signed out. Updates on sign-in,
/// sign-out and when a session expires.
final currentUserIdProvider = NotifierProvider<CurrentUserId, String?>(
  CurrentUserId.new,
);

class CurrentUserId extends Notifier<String?> {
  @override
  String? build() {
    final repository = ref.watch(authRepositoryProvider);
    final subscription = repository.userIdChanges().listen(
      (userId) => state = userId,
      onError: (Object _) => state = repository.currentUserId,
    );
    ref.onDispose(subscription.cancel);
    return repository.currentUserId;
  }
}
