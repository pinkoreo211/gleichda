import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/features/requests/domain/request_timing.dart';
import 'package:app/features/requests/domain/service_category.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

const _washingMachine = 'Meine Waschmaschine verliert unten Wasser';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('the continue button stays disabled while nothing is typed', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Weiter'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a freely written request is carried over unchanged', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);

    await tester.enterText(find.byType(TextField), _washingMachine);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('Erzähl uns kurz, was du brauchst'), findsOneWidget);
    // The exact wording survives: nothing is reduced to a category here.
    expect(find.text(_washingMachine), findsOneWidget);
    // The request opens inside the tab, so the tabs stay reachable.
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a category card preselects that category', (tester) async {
    await pumpSignedInApp(tester, role: AppRole.customer);

    await scrollTo(tester, find.text('Reinigung'));
    await tester.tap(find.text('Reinigung'));
    await tester.pumpAndSettle();

    expect(find.text('Erzähl uns kurz, was du brauchst'), findsOneWidget);
    await scrollTo(tester, find.widgetWithText(FilterChip, 'Reinigung'));
    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Reinigung'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('the category can be removed again', (tester) async {
    await pumpSignedInApp(tester, role: AppRole.customer);

    await scrollTo(tester, find.text('Reinigung'));
    await tester.tap(find.text('Reinigung'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.widgetWithText(FilterChip, 'Reinigung'));
    await tester.tap(find.widgetWithText(FilterChip, 'Reinigung'));
    await tester.pumpAndSettle();

    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Reinigung'),
    );
    expect(chip.selected, isFalse);
  });

  testWidgets('going back keeps what was already typed', (tester) async {
    await pumpSignedInApp(tester, role: AppRole.customer);

    await tester.enterText(find.byType(TextField), _washingMachine);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Was brauchst du?'), findsOneWidget);
    expect(find.text(_washingMachine), findsOneWidget);
  });

  testWidgets('a created request is stored and listed under bookings', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    await pumpSignedInApp(tester, role: AppRole.customer, requests: requests);

    await tester.enterText(find.byType(TextField), _washingMachine);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Anfrage erstellen'));
    await tester.pumpAndSettle();

    final stored = requests.requests[testUserId];
    expect(stored, hasLength(1));
    expect(stored!.single.originalDescription, _washingMachine);
    // Nothing is invented: no category was chosen, and no AI ran yet.
    expect(stored.single.category, isNull);
    expect(stored.single.timing, RequestTiming.asap);
    expect(stored.single.detectedService, isNull);
    expect(stored.single.estimatedPriceMinCents, isNull);

    // Saving returns to the home screen.
    expect(find.text('Was brauchst du?'), findsOneWidget);

    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();
    expect(find.text('Deine Anfragen'), findsOneWidget);
    expect(find.text(_washingMachine), findsOneWidget);
  });

  testWidgets('a request keeps the category chosen on a card', (tester) async {
    final requests = InMemoryServiceRequestRepository();
    await pumpSignedInApp(tester, role: AppRole.customer, requests: requests);

    await scrollTo(tester, find.text('Handwerker'));
    await tester.tap(find.text('Handwerker'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Lampe montieren');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Anfrage erstellen'));
    await tester.pumpAndSettle();

    expect(
      requests.requests[testUserId]!.single.category,
      ServiceCategory.handyman,
    );
  });

  testWidgets('bookings stay empty when no request was created', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);

    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Buchungen'), findsOneWidget);
    expect(find.text('Deine Anfragen'), findsNothing);
  });

  testWidgets('the profile shows the account and its mode', (tester) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      profile: FakeProfileRepository(displayName: 'Anna'),
    );

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Anna'), findsOneWidget);
    expect(find.text(testEmail), findsOneWidget);
    expect(find.text('Kundenmodus'), findsOneWidget);
    await scrollTo(tester, find.widgetWithText(TextButton, 'Abmelden'));
    expect(find.widgetWithText(TextButton, 'Abmelden'), findsOneWidget);
  });

  testWidgets('the customer screens fit a small phone without overflowing', (
    tester,
  ) async {
    // Narrower and shorter than most phones in use; if it fits here, it fits.
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpSignedInApp(tester, role: AppRole.customer);
    expect(tester.takeException(), isNull);

    // Lay out every section of the home screen, including the category grid.
    await scrollTo(tester, find.text('Deine nächsten Buchungen'));
    expect(tester.takeException(), isNull);

    await scrollTo(tester, find.text('Sonstiges'));
    await tester.tap(find.text('Sonstiges'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await scrollTo(tester, find.text('Fotos'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the profile says so when no name is stored yet', (tester) async {
    await pumpSignedInApp(tester, role: AppRole.customer);

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Noch nicht hinterlegt'), findsOneWidget);
  });
}
