import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

/// One provider who offers the cleaning service, priced.
const _maxMontagen = ProviderMatch(
  providerId: testProviderId,
  displayName: 'Max Montagen',
  city: 'Wien',
  verificationStatus: ProviderVerificationStatus.unverified,
  lowestPriceCents: 3999,
);

/// Home → Reinigung → Wohnungsreinigung → "Weiter", fills in the city and
/// saves. Ends on the provider list for the saved request.
Future<void> _createRequest(WidgetTester tester, {String city = 'Wien'}) async {
  await scrollTo(tester, find.text('Reinigung'));
  await tester.tap(find.text('Reinigung'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Wohnungsreinigung'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
  await tester.pumpAndSettle();

  // The form is longer than the test screen, so the fields have to be
  // scrolled into view before they exist to type into.
  await scrollTo(tester, find.text('Ort'));
  await tester.enterText(find.widgetWithText(TextField, 'Ort'), city);
  await tester.enterText(find.widgetWithText(TextField, 'PLZ'), '1070');
  await tester.pump();

  await scrollTo(
    tester,
    find.widgetWithText(FilledButton, 'Anfrage erstellen'),
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Anfrage erstellen'));
  await tester.pumpAndSettle();
}

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('a saved request keeps the service and the place', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(matches: [_maxMontagen]),
    );
    await _createRequest(tester);

    final stored = requests.requests.single;
    expect(stored.service?.id, testFlatCleaning.id);
    expect(stored.city, 'Wien');
    expect(stored.postalCode, '1070');
  });

  testWidgets('saving a request leads to the providers for that request', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    final matching = FakeMatchingRepository(matches: [_maxMontagen]);
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: matching,
    );
    await _createRequest(tester);

    // Looked up by the stored request, not by the catalog entry: the
    // backend reads the service and the city from the request itself.
    expect(matching.askedForRequest, [requests.requests.single.id]);
    expect(find.text('Passende Anbieter'), findsOneWidget);
    expect(find.text('Max Montagen'), findsOneWidget);
    expect(find.textContaining('39,99'), findsOneWidget);
  });

  testWidgets('the customer sends the request to one provider', (tester) async {
    final requests = InMemoryServiceRequestRepository();
    final matching = FakeMatchingRepository(
      matches: [_maxMontagen],
      requests: requests,
    );
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: matching,
    );
    await _createRequest(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Anfrage senden'));
    await tester.pumpAndSettle();

    final requestId = requests.requests.single.id;
    expect(matching.sent[requestId], [testProviderId]);
    // Shown as done, so the same request cannot be sent twice by mistake.
    expect(find.text('Anfrage gesendet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Anfrage senden'), findsNothing);
  });

  testWidgets('the booking list says how many providers have the request', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    final matching = FakeMatchingRepository(
      matches: [_maxMontagen],
      requests: requests,
    );
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: matching,
    );
    await _createRequest(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Anfrage senden'));
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();
    expect(find.text('An 1 Anbieter gesendet'), findsOneWidget);
    expect(find.text('Wien'), findsOneWidget);
  });

  testWidgets('the booking list opens the providers for a saved request', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    final matching = FakeMatchingRepository(matches: [_maxMontagen]);
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: matching,
    );
    await _createRequest(tester);

    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Passende Anbieter'));
    await tester.pumpAndSettle();

    expect(find.text('Max Montagen'), findsOneWidget);
    // The bottom navigation stays on bookings, so the customer does not
    // get moved to another tab by opening a list.
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a provider sees the request a customer sent them', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    final matching = FakeMatchingRepository(
      matches: [_maxMontagen],
      requests: requests,
    );
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      store: InMemorySessionStore({testUserId: AppRole.customer}),
      requests: requests,
      matching: matching,
      // Derived from what was actually sent, so this test follows one
      // request all the way from the customer to the provider.
      incoming: FakeIncomingRequestsRepository(requests: requests),
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
      ),
    );
    await _createRequest(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Anfrage senden'));
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zum Anbietermodus wechseln'));
    await tester.pumpAndSettle();

    expect(find.text('Anfragen an dich'), findsOneWidget);
    // Twice: as the service the request is about, and as the description,
    // which the catalog prefilled with the same words.
    expect(find.text('Wohnungsreinigung'), findsNWidgets(2));
    expect(find.text('Wien, 1070'), findsOneWidget);
    expect(find.text('1 Anfrage'), findsOneWidget);
    // Open, so both answers are offered and neither has been taken.
    expect(find.widgetWithText(FilledButton, 'Annehmen'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Ablehnen'), findsOneWidget);
  });

  testWidgets('a provider without requests is told so plainly', (tester) async {
    await pumpSignedInApp(tester, role: AppRole.provider);

    expect(find.text('Anfragen an dich'), findsOneWidget);
    expect(find.textContaining('noch keine Anfragen erhalten'), findsOneWidget);
    // No invented job, and no count that suggests one.
    expect(find.text('1 Anfrage'), findsNothing);
  });

  testWidgets('a provider only ever sees requests sent to them', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    final stored = await requests.create(
      const ServiceRequestDraft(description: 'Wohnung reinigen'),
    );
    // A real contact exists -- it just belongs to someone else.
    requests.contacts.send(requestId: stored.id, providerId: testProviderId);

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      incoming: FakeIncomingRequestsRepository(
        requests: requests,
        // Somebody else's profile.
        providerId: 'provider-2',
      ),
    );

    expect(find.textContaining('noch keine Anfragen erhalten'), findsOneWidget);
    expect(find.text('Wohnung reinigen'), findsNothing);
  });

  testWidgets('a failure while sending is shown, not swallowed', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        failure: AppFailure.unknown,
      ),
    );

    await scrollTo(tester, find.text('Reinigung'));
    await tester.tap(find.text('Reinigung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wohnungsreinigung'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.widgetWithText(FilledButton, 'Anfrage erstellen'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Anfrage erstellen'));
    await tester.pumpAndSettle();

    // The request itself was stored; only the provider search failed, and
    // the screen offers a retry instead of pretending the list is empty.
    expect(requests.requests, hasLength(1));
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });
}
