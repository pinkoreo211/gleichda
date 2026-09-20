import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/requests/domain/request_timing.dart';

import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

const _washingMachine = 'Meine Waschmaschine verliert unten Wasser';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

FilterChip _chip(WidgetTester tester, String label) =>
    tester.widget<FilterChip>(find.widgetWithText(FilterChip, label));

/// Home → type something → "Weiter", the way a customer reaches the form.
Future<void> _openRequestForm(
  WidgetTester tester, {
  String description = _washingMachine,
}) async {
  await tester.enterText(find.byType(TextField), description);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
  await tester.pumpAndSettle();
}

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

  testWidgets('the category chips come from the catalog and can be cleared', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _openRequestForm(tester);

    // Exactly the categories the backend returned, not a compiled-in list.
    await scrollTo(tester, find.widgetWithText(FilterChip, 'Reinigung'));
    expect(find.widgetWithText(FilterChip, 'Handwerker'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Reinigung'));
    await tester.pumpAndSettle();
    expect(_chip(tester, 'Reinigung').selected, isTrue);

    // Tapping it again clears it: "no category" stays a valid answer.
    await tester.tap(find.widgetWithText(FilterChip, 'Reinigung'));
    await tester.pumpAndSettle();
    expect(_chip(tester, 'Reinigung').selected, isFalse);
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

    final stored = requests.requests;
    expect(stored, hasLength(1));
    expect(stored.single.originalDescription, _washingMachine);
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

  testWidgets('a chosen category is stored with the request', (tester) async {
    final requests = InMemoryServiceRequestRepository();
    await pumpSignedInApp(tester, role: AppRole.customer, requests: requests);
    await _openRequestForm(tester, description: 'Lampe montieren');

    await scrollTo(tester, find.widgetWithText(FilterChip, 'Handwerker'));
    await tester.tap(find.widgetWithText(FilterChip, 'Handwerker'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Anfrage erstellen'));
    await tester.pumpAndSettle();

    expect(requests.requests.single.category?.id, testHandymanCategory.id);
  });

  testWidgets('a request that the server rejects is not lost', (tester) async {
    final requests = InMemoryServiceRequestRepository()
      ..failure = AppFailure.unknown;
    await pumpSignedInApp(tester, role: AppRole.customer, requests: requests);

    await tester.enterText(find.byType(TextField), _washingMachine);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Anfrage erstellen'));
    await tester.pumpAndSettle();

    // The customer stays on the form with their text intact and is told why,
    // instead of losing what they wrote.
    expect(find.textContaining('Das hat nicht geklappt'), findsOneWidget);
    expect(find.text('Erzähl uns kurz, was du brauchst'), findsOneWidget);
    expect(find.text(_washingMachine), findsOneWidget);
    expect(requests.requests, isEmpty);
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

    // The form first, while the text field is still on screen.
    await _openRequestForm(tester);
    await scrollTo(tester, find.text('Fotos'));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Then every section of the home screen, including the category grid.
    await scrollTo(tester, find.text('Deine nächsten Buchungen'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the profile says so when no name is stored yet', (tester) async {
    await pumpSignedInApp(tester, role: AppRole.customer);

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Noch nicht hinterlegt'), findsOneWidget);
  });
}
