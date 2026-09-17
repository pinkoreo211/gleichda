import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/session/data/session_store.dart';
import 'package:app/features/session/domain/app_role.dart';

/// The device storage for session choices. Replaced with the real
/// implementation in `main()` and with an in-memory one in tests.
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => throw UnimplementedError('sessionStoreProvider must be overridden'),
);

/// The role the user is currently using the app as, or `null` before
/// onboarding is finished.
final activeRoleProvider = NotifierProvider<ActiveRoleController, AppRole?>(
  ActiveRoleController.new,
);

class ActiveRoleController extends Notifier<AppRole?> {
  @override
  AppRole? build() => ref.watch(sessionStoreProvider).readActiveRole();

  /// Chooses or switches the active role.
  Future<void> select(AppRole role) async {
    await ref.read(sessionStoreProvider).writeActiveRole(role);
    state = role;
  }

  /// Forgets the role, which sends the user back to onboarding.
  Future<void> clear() async {
    await ref.read(sessionStoreProvider).writeActiveRole(null);
    state = null;
  }
}
