import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/features/session/domain/app_role.dart';

/// Remembers the last used mode per account on this device, so a returning
/// user lands in the same mode and a different account on the same phone
/// does not inherit it.
abstract interface class SessionStore {
  AppRole? readActiveRole(String userId);

  Future<void> writeActiveRole(String userId, AppRole role);
}

/// [SessionStore] backed by the platform's key-value storage
/// (SharedPreferences on Android, UserDefaults on iOS).
class SharedPreferencesSessionStore implements SessionStore {
  SharedPreferencesSessionStore(this._preferences);

  final SharedPreferencesWithCache _preferences;

  static String _activeRoleKey(String userId) => 'session.active_role.$userId';

  @override
  AppRole? readActiveRole(String userId) {
    final stored = _preferences.getString(_activeRoleKey(userId));
    // Unknown values (e.g. from an older app version) count as "no role".
    return AppRole.values.asNameMap()[stored];
  }

  @override
  Future<void> writeActiveRole(String userId, AppRole role) =>
      _preferences.setString(_activeRoleKey(userId), role.name);
}
