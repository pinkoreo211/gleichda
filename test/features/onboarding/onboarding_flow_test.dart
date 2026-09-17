import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('new user chooses customer mode and lands in the customer area', (
    tester,
  ) async {
    final store = InMemorySessionStore();
    await pumpApp(tester, store: store);

    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();
    expect(find.text('Wie möchtest du GleichDa nutzen?'), findsOneWidget);

    // Nothing selected yet: continuing is not possible.
    final continueButton = find.widgetWithText(FilledButton, 'Weiter');
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    await tester.tap(find.text('Ich brauche eine Dienstleistung'));
    await tester.pump();
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(store.activeRole, AppRole.customer);
    expect(find.text('Was brauchst du?'), findsOneWidget);
    for (final label in ['Start', 'Buchungen', 'Chats', 'Profil']) {
      expect(_navLabel(label), findsOneWidget);
    }
    expect(_navLabel('Aufträge'), findsNothing);
  });

  testWidgets('user switches from customer to provider mode in the profile', (
    tester,
  ) async {
    final store = InMemorySessionStore(AppRole.customer);
    await pumpApp(tester, store: store);

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Kundenmodus'), findsOneWidget);

    await tester.tap(find.text('Zum Anbietermodus wechseln'));
    await tester.pumpAndSettle();

    expect(store.activeRole, AppRole.provider);
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
    await pumpApp(tester, store: InMemorySessionStore(AppRole.provider));

    await tester.tap(_navLabel('Kalender'));
    await tester.pumpAndSettle();
    expect(find.text('Deine Verfügbarkeit'), findsOneWidget);

    await tester.tap(_navLabel('Finanzen'));
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Einnahmen'), findsOneWidget);
  });

  testWidgets('restarting onboarding returns to the welcome screen', (
    tester,
  ) async {
    final store = InMemorySessionStore(AppRole.provider);
    await pumpApp(tester, store: store);

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onboarding neu starten (nur Testversion)'));
    await tester.pumpAndSettle();

    expect(store.activeRole, isNull);
    expect(find.text("Los geht's"), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
