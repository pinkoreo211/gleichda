import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/app.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/data/session_store.dart';
import 'package:app/features/session/domain/app_role.dart';

/// [SessionStore] that keeps everything in memory, for tests.
class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([this.activeRole]);

  AppRole? activeRole;

  @override
  AppRole? readActiveRole() => activeRole;

  @override
  Future<void> writeActiveRole(AppRole? role) async => activeRole = role;
}

/// Starts the whole app on a device with [locale] (default: Austrian German)
/// and the given stored session.
Future<void> pumpApp(
  WidgetTester tester, {
  InMemorySessionStore? store,
  Locale locale = const Locale('de', 'AT'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(store ?? InMemorySessionStore()),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}
