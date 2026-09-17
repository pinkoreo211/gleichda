import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/session/data/role_repository.dart';
import 'package:app/features/session/data/session_store.dart';
import 'package:app/features/session/domain/app_role.dart';

/// The device storage for session choices. Replaced with the real
/// implementation in `main()` and with an in-memory one in tests.
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => throw UnimplementedError('sessionStoreProvider must be overridden'),
);

/// The mode the signed-in user is currently using, or `null` when signed out
/// or before they chose a mode.
final activeRoleProvider = NotifierProvider<ActiveRoleController, AppRole?>(
  ActiveRoleController.new,
);

class ActiveRoleController extends Notifier<AppRole?> {
  @override
  AppRole? build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    return ref.watch(sessionStoreProvider).readActiveRole(userId);
  }

  /// Registers [role] on the server (the server decides whether it is
  /// allowed), then switches the app into that mode.
  ///
  /// Throws `AppFailure` if the server call fails; the mode stays unchanged.
  Future<void> activate(AppRole role) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('A mode can only be activated when signed in.');
    }

    await ref.read(roleRepositoryProvider).addMyRole(role);
    await ref.read(sessionStoreProvider).writeActiveRole(userId, role);
    if (ref.mounted && ref.read(currentUserIdProvider) == userId) {
      state = role;
    }
  }
}
