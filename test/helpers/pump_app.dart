import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/app.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/data/role_repository.dart';
import 'package:app/features/session/data/session_store.dart';
import 'package:app/features/session/domain/app_role.dart';

const testUserId = 'user-1';
const testEmail = 'anna@example.at';

/// The code [FakeAuthRepository] accepts.
const validCode = '123456';

/// [AuthRepository] without a backend. Any plausible email receives a code;
/// [validCode] signs in as [testUserId].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({bool signedIn = false})
    : _userId = signedIn ? testUserId : null,
      _email = signedIn ? testEmail : null;

  final _changes = StreamController<String?>.broadcast();
  String? _userId;
  String? _email;

  final sentCodesTo = <String>[];

  /// When set, [sendEmailCode] throws it.
  AppFailure? sendFailure;

  @override
  String? get currentUserId => _userId;

  @override
  String? get currentEmail => _email;

  @override
  Stream<String?> userIdChanges() => _changes.stream;

  @override
  Future<void> sendEmailCode(String email) async {
    if (sendFailure case final failure?) throw failure;
    sentCodesTo.add(email);
  }

  @override
  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    if (code != validCode) throw AppFailure.invalidOrExpiredCode;
    _email = email;
    _setUser(testUserId);
  }

  @override
  Future<void> signOut() async {
    _email = null;
    _setUser(null);
  }

  void _setUser(String? userId) {
    _userId = userId;
    _changes.add(userId);
  }
}

/// [RoleRepository] that records roles in memory.
class FakeRoleRepository implements RoleRepository {
  final roles = <AppRole>{};

  /// When set, [addMyRole] throws it.
  AppFailure? failure;

  @override
  Future<void> addMyRole(AppRole role) async {
    if (failure case final failure?) throw failure;
    roles.add(role);
  }
}

/// [SessionStore] that keeps everything in memory.
class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([Map<String, AppRole>? activeRoles])
    : activeRoles = {...?activeRoles};

  final Map<String, AppRole> activeRoles;

  @override
  AppRole? readActiveRole(String userId) => activeRoles[userId];

  @override
  Future<void> writeActiveRole(String userId, AppRole role) async =>
      activeRoles[userId] = role;
}

/// Starts the whole app with fake backend services on a device with [locale]
/// (default: Austrian German).
Future<void> pumpApp(
  WidgetTester tester, {
  FakeAuthRepository? auth,
  FakeRoleRepository? roles,
  InMemorySessionStore? store,
  Locale locale = const Locale('de', 'AT'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
        roleRepositoryProvider.overrideWithValue(roles ?? FakeRoleRepository()),
        sessionStoreProvider.overrideWithValue(store ?? InMemorySessionStore()),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

/// A signed-in user whose last used mode was [role].
Future<void> pumpSignedInApp(
  WidgetTester tester, {
  required AppRole? role,
  FakeAuthRepository? auth,
  FakeRoleRepository? roles,
  InMemorySessionStore? store,
}) {
  return pumpApp(
    tester,
    auth: auth ?? FakeAuthRepository(signedIn: true),
    roles: roles ?? (FakeRoleRepository()..roles.addAll([?role])),
    store: store ?? InMemorySessionStore({testUserId: ?role}),
  );
}
