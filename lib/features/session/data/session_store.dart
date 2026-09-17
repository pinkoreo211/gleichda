import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/features/session/domain/app_role.dart';

/// Remembers session choices on this device between app starts.
abstract interface class SessionStore {
  AppRole? readActiveRole();

  /// Saves [role], or forgets the saved role when [role] is `null`.
  Future<void> writeActiveRole(AppRole? role);
}

/// [SessionStore] backed by the platform's key-value storage
/// (SharedPreferences on Android, UserDefaults on iOS).
class SharedPreferencesSessionStore implements SessionStore {
  SharedPreferencesSessionStore(this._preferences);

  static const String activeRoleKey = 'session.active_role';

  final SharedPreferencesWithCache _preferences;

  @override
  AppRole? readActiveRole() {
    final stored = _preferences.getString(activeRoleKey);
    // Unknown values (e.g. from an older app version) count as "no role".
    return AppRole.values.asNameMap()[stored];
  }

  @override
  Future<void> writeActiveRole(AppRole? role) {
    if (role == null) return _preferences.remove(activeRoleKey);
    return _preferences.setString(activeRoleKey, role.name);
  }
}
