import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

const _maxMontagen = ProviderMatch(
  providerId: testProviderId,
  displayName: 'Max Montagen',
  city: 'Wien',
  verificationStatus: ProviderVerificationStatus.unverified,
  lowestPriceCents: 3999,
);

/// One request, already sent to this provider and waiting for an answer.
Future<InMemoryServiceRequestRepository> _withOpenRequest() async {
  final requests = InMemoryServiceRequestRepository();
  final stored = await requests.create(
    ServiceRequestDraft(
      description: 'Kasten aufbauen',
      // Named, so the customer's side can open the provider list for it.
      service: testFlatCleaning,
      city: 'Wien',
      postalCode: '1070',
    ),
  );
  requests.contacts.send(requestId: stored.id, providerId: testProviderId);
  return requests;
}

/// Signs in as the provider who received that request.
Future<void> _pumpProvider(
  WidgetTester tester,
  InMemoryServiceRequestRepository requests,
) {
  return pumpSignedInApp(
    tester,
    role: AppRole.provider,
    requests: requests,
    incoming: FakeIncomingRequestsRepository(requests: requests),
  );
}

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('an open request offers both answers and claims neither', (
    tester,
  ) async {
    await _pumpProvider(tester, await _withOpenRequest());

    expect(find.text('Kasten aufbauen'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Annehmen'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Ablehnen'), findsOneWidget);
    expect(find.text('Du hast angenommen'), findsNothing);
    expect(find.text('Du hast abgelehnt'), findsNothing);
  });

  testWidgets('accepting is stored and the buttons are gone afterwards', (
    tester,
  ) async {
    final requests = await _withOpenRequest();
    await _pumpProvider(tester, requests);

    await tester.tap(find.widgetWithText(FilledButton, 'Annehmen'));
    await tester.pumpAndSettle();

    final stored = requests.contacts.forRequest(requests.requests.single.id);
    expect(stored[testProviderId], RequestContactStatus.accepted);
    expect(find.text('Du hast angenommen'), findsOneWidget);
    // No second decision: the backend would refuse it, and the screen does
    // not offer what cannot happen.
    expect(find.widgetWithText(FilledButton, 'Annehmen'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Ablehnen'), findsNothing);
  });

  testWidgets('declining is stored just as plainly', (tester) async {
    final requests = await _withOpenRequest();
    await _pumpProvider(tester, requests);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ablehnen'));
    await tester.pumpAndSettle();

    final stored = requests.contacts.forRequest(requests.requests.single.id);
    expect(stored[testProviderId], RequestContactStatus.declined);
    expect(find.text('Du hast abgelehnt'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Annehmen'), findsNothing);
  });

  testWidgets('an already answered request cannot be answered again', (
    tester,
  ) async {
    final requests = await _withOpenRequest();
    final requestId = requests.requests.single.id;
    final contactId = requests.contacts.contactId(requestId, testProviderId);
    requests.contacts.respond(contactId, RequestContactStatus.accepted);

    await _pumpProvider(tester, requests);

    expect(find.text('Du hast angenommen'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Annehmen'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Ablehnen'), findsNothing);
    // And the store itself refuses a second answer, which is what the
    // backend does -- the missing buttons are convenience, not the rule.
    expect(
      () => requests.contacts.respond(contactId, RequestContactStatus.declined),
      throwsA(AppFailure.requestAlreadyAnswered),
    );
  });

  testWidgets('an answer that lost a race is explained, not swallowed', (
    tester,
  ) async {
    final requests = await _withOpenRequest();
    await _pumpProvider(tester, requests);

    // Answered elsewhere -- another device, or a screen that had not
    // refreshed -- after this screen was already built.
    requests.contacts.respond(
      requests.contacts.contactId(requests.requests.single.id, testProviderId),
      RequestContactStatus.accepted,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Annehmen'));
    await tester.pumpAndSettle();

    expect(
      find.text('Diese Anfrage wurde bereits beantwortet.'),
      findsOneWidget,
    );
  });

  testWidgets('pulling down picks up a request that arrived meanwhile', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    await _pumpProvider(tester, requests);
    expect(find.textContaining('noch keine Anfragen erhalten'), findsOneWidget);

    // A customer sends one while this screen is already open. Without a
    // refresh the provider would never learn about it.
    final stored = await requests.create(
      ServiceRequestDraft(
        description: 'Lampe montieren',
        service: testFlatCleaning,
      ),
    );
    requests.contacts.send(requestId: stored.id, providerId: testProviderId);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Lampe montieren'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Annehmen'), findsOneWidget);
  });

  testWidgets('the customer sees that a provider accepted', (tester) async {
    final requests = await _withOpenRequest();
    final requestId = requests.requests.single.id;
    requests.contacts.respond(
      requests.contacts.contactId(requestId, testProviderId),
      RequestContactStatus.accepted,
    );

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        requests: requests,
      ),
    );

    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();
    expect(find.text('1 Anbieter hat angenommen'), findsOneWidget);

    // And on the provider list, where the customer picked them.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Passende Anbieter'));
    await tester.pumpAndSettle();
    expect(find.text('Angenommen'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Anfrage senden'), findsNothing);
  });

  testWidgets('reopening the provider list picks up the answer', (
    tester,
  ) async {
    final requests = await _withOpenRequest();
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        requests: requests,
      ),
    );

    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Passende Anbieter'));
    await tester.pumpAndSettle();
    expect(find.text('Anfrage gesendet'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // The provider answers while the customer is elsewhere in the app.
    requests.contacts.respond(
      requests.contacts.contactId(requests.requests.single.id, testProviderId),
      RequestContactStatus.accepted,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Passende Anbieter'));
    await tester.pumpAndSettle();

    // Read again on reopening. A list kept from the first visit would still
    // say "sent" long after the provider had said yes.
    expect(find.text('Angenommen'), findsOneWidget);
    expect(find.text('Anfrage gesendet'), findsNothing);
  });

  testWidgets('the customer sees a refusal as a refusal', (tester) async {
    final requests = await _withOpenRequest();
    final requestId = requests.requests.single.id;
    requests.contacts.respond(
      requests.contacts.contactId(requestId, testProviderId),
      RequestContactStatus.declined,
    );

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        requests: requests,
      ),
    );

    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();
    // Not dressed up as "sent": a no is a no.
    expect(find.text('1 Anbieter hat abgelehnt'), findsOneWidget);
    expect(find.text('An 1 Anbieter gesendet'), findsNothing);
  });

  testWidgets('a request still waiting says so, not that it was accepted', (
    tester,
  ) async {
    final requests = await _withOpenRequest();

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        requests: requests,
      ),
    );

    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();
    expect(find.text('An 1 Anbieter gesendet'), findsOneWidget);
    expect(find.text('1 Anbieter hat angenommen'), findsNothing);
  });
}
