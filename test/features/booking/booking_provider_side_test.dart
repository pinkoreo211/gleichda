import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

const _otherProviderId = 'provider-someone-else';
const _cleaning = 'Bitte einmal die Wohnung reinigen';

/// One booking: a request with a price and a wanted hour, handed to
/// [providerId].
Future<InMemoryServiceRequestRepository> _booking({
  String providerId = testProviderId,
  int priceCents = 5900,
}) async {
  final requests = InMemoryServiceRequestRepository();
  final stored = await requests.create(
    ServiceRequestDraft(
      description: _cleaning,
      service: testFlatCleaning,
      city: 'Wien',
      postalCode: '1190',
    ),
  );
  requests.contacts.send(
    requestId: stored.id,
    providerId: providerId,
    priceCents: priceCents,
    wantedAt: DateTime(2026, 10, 3, 14),
  );
  return requests;
}

void main() {
  testWidgets('the provider sees the price and the hour before answering', (
    tester,
  ) async {
    final requests = await _booking();

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
    );

    await scrollTo(tester, find.text('Wohnungsreinigung'));
    expect(find.text(_cleaning), findsOneWidget);
    // Accepting without seeing either would be answering blind.
    expect(find.textContaining('59,00'), findsOneWidget);
    expect(find.text('3.10.2026, 14:00'), findsOneWidget);
    expect(find.textContaining('Wien'), findsOneWidget);
  });

  testWidgets('an open request without a price shows none', (tester) async {
    final requests = InMemoryServiceRequestRepository();
    final stored = await requests.create(
      ServiceRequestDraft(
        description: _cleaning,
        service: testFlatCleaning,
        city: 'Wien',
      ),
    );
    // Sent the older way: no price was ever agreed.
    requests.contacts.send(requestId: stored.id, providerId: testProviderId);

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
    );

    await scrollTo(tester, find.text('Wohnungsreinigung'));
    expect(find.textContaining('59,00'), findsNothing);
    expect(find.textContaining('€'), findsNothing);
  });

  testWidgets('another provider never sees the booking', (tester) async {
    // The booking went to somebody else entirely.
    final requests = await _booking(providerId: _otherProviderId);

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
    );

    expect(find.text(_cleaning), findsNothing);
    expect(find.textContaining('59,00'), findsNothing);
    expect(find.textContaining('noch keine Anfragen'), findsOneWidget);
  });

  testWidgets('accepting a booking turns it into a job on both sides', (
    tester,
  ) async {
    final requests = await _booking();
    final incoming = FakeIncomingRequestsRepository(requests: requests);

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: incoming,
      jobs: FakeJobsRepository(
        contacts: requests.contacts,
        requests: requests,
        isProvider: true,
      ),
    );

    await scrollTo(tester, find.widgetWithText(FilledButton, 'Annehmen'));
    await tester.tap(find.widgetWithText(FilledButton, 'Annehmen'));
    await tester.pumpAndSettle();

    final contactId = requests.contacts.contactId(
      requests.requests.single.id,
      testProviderId,
    );
    expect(
      requests.contacts.statusOf(contactId),
      RequestContactStatus.accepted,
    );
    // And the price travels with it into the job.
    expect(find.textContaining('Festpreis:'), findsOneWidget);
  });

  testWidgets('the customer cannot change what a provider is worth', (
    tester,
  ) async {
    final requests = await _booking();
    final contacts = requests.contacts;
    final contactId = contacts.contactId(
      requests.requests.single.id,
      testProviderId,
    );

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
      ),
    );

    // Nothing a customer can reach writes the price or the verification.
    // Both live where only the backend and the team put them.
    expect(contacts.bookedPrice[contactId], 5900);
    expect(contacts.statusOf(contactId), RequestContactStatus.sent);
  });
}
