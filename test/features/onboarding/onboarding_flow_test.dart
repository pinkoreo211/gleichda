import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets(
    'new user signs up with an email code, chooses customer mode and lands '
    'in the customer area',
    (tester) async {
      final auth = FakeAuthRepository();
      final roles = FakeRoleRepository();
      final store = InMemorySessionStore();
      await pumpApp(tester, auth: auth, roles: roles, store: store);

      await tester.tap(find.text("Los geht's"));
      await tester.pumpAndSettle();
      expect(find.text('Anmelden oder registrieren'), findsOneWidget);

      await tester.enterText(find.byType(TextField), testEmail);
      await tester.tap(find.widgetWithText(FilledButton, 'Code senden'));
      await tester.pumpAndSettle();
      expect(auth.sentCodesTo, [testEmail]);
      expect(find.text('Code eingeben'), findsOneWidget);

      await tester.enterText(find.byType(TextField), validCode);
      await tester.tap(find.widgetWithText(FilledButton, 'Bestätigen'));
      await tester.pumpAndSettle();
      expect(find.text('Wie möchtest du GleichDa nutzen?'), findsOneWidget);

      final continueButton = find.widgetWithText(FilledButton, 'Weiter');
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      await tester.tap(find.text('Ich brauche eine Dienstleistung'));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(roles.roles, {AppRole.customer});
      expect(store.activeRoles, {testUserId: AppRole.customer});
      expect(find.text('Was brauchst du?'), findsOneWidget);
      for (final label in ['Start', 'Buchungen', 'Chats', 'Profil']) {
        expect(_navLabel(label), findsOneWidget);
      }
      expect(_navLabel('Aufträge'), findsNothing);
    },
  );

  testWidgets('mode stays unchanged when the server rejects the role', (
    tester,
  ) async {
    final roles = FakeRoleRepository()..failure = AppFailure.unknown;
    await pumpSignedInApp(tester, role: null, roles: roles);

    await tester.tap(find.text('Ich biete Dienstleistungen an'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Das hat nicht geklappt'), findsOneWidget);
    expect(find.text('Wie möchtest du GleichDa nutzen?'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('user switches from customer to provider mode in the profile', (
    tester,
  ) async {
    final roles = FakeRoleRepository();
    final store = InMemorySessionStore({testUserId: AppRole.customer});
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      roles: roles,
      store: store,
    );

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();
    expect(find.text(testEmail), findsOneWidget);
    expect(find.text('Kundenmodus'), findsOneWidget);

    await tester.tap(find.text('Zum Anbietermodus wechseln'));
    await tester.pumpAndSettle();

    expect(roles.roles, contains(AppRole.provider));
    expect(store.activeRoles[testUserId], AppRole.provider);
    expect(find.text('Noch keine Aufträge'), findsOneWidget);
    for (final label in [
      'Aufträge',
      'Kalender',
      'Chats',
      'Finanzen',
      'Profil',
    ]) {
      expect(_navLabel(label), findsOneWidget);
    }
    expect(_navLabel('Buchungen'), findsNothing);
  });

  testWidgets('provider tabs open their screens', (tester) async {
    await pumpSignedInApp(tester, role: AppRole.provider);

    await tester.tap(_navLabel('Kalender'));
    await tester.pumpAndSettle();
    expect(find.text('Deine Verfügbarkeit'), findsOneWidget);

    await tester.tap(_navLabel('Finanzen'));
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Einnahmen'), findsOneWidget);
  });

  testWidgets('signing out returns to the welcome screen', (tester) async {
    final auth = FakeAuthRepository(signedIn: true);
    await pumpSignedInApp(tester, role: AppRole.provider, auth: auth);

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.widgetWithText(TextButton, 'Abmelden'));
    await tester.tap(find.widgetWithText(TextButton, 'Abmelden'));
    await tester.pumpAndSettle();

    expect(auth.currentUserId, isNull);
    expect(find.text("Los geht's"), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('signing out is possible from mode selection', (tester) async {
    final auth = FakeAuthRepository(signedIn: true);
    await pumpSignedInApp(tester, role: null, auth: auth);

    await tester.tap(find.widgetWithText(TextButton, 'Abmelden'));
    await tester.pumpAndSettle();

    expect(auth.currentUserId, isNull);
    expect(find.text("Los geht's"), findsOneWidget);
  });
}
