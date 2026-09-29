import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/features/notifications/application/push_controller.dart';
import 'package:app/features/notifications/domain/push_message.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

const _job = 'Kasten aufbauen';

/// One job, left at [status].
Future<InMemoryServiceRequestRepository> _jobAt(
  RequestContactStatus status,
) async {
  final requests = InMemoryServiceRequestRepository();
  final stored = await requests.create(
    ServiceRequestDraft(
      description: _job,
      service: testFlatCleaning,
      city: 'Wien',
    ),
  );
  final contacts = requests.contacts;
  contacts.send(requestId: stored.id, providerId: testProviderId);
  if (status != RequestContactStatus.sent) {
    contacts.respond(
      contacts.contactId(stored.id, testProviderId),
      RequestContactStatus.accepted,
    );
    contacts.setStatus(contacts.contactId(stored.id, testProviderId), status);
  }
  return requests;
}

String _contactOf(InMemoryServiceRequestRepository requests) =>
    requests.contacts.contactId(requests.requests.single.id, testProviderId);

void main() {
  testWidgets('the app knows every kind the backend can send', (tester) async {
    // If one of these ever fails to parse, a real notification arrives and
    // the app quietly does nothing with it.
    for (final name in [
      'booking_received',
      'request_accepted',
      'appointment_agreed',
      'provider_on_the_way',
      'job_completed',
      'job_confirmed',
    ]) {
      expect(PushKind.fromName(name), isNotNull, reason: name);
    }
  });

  testWidgets('a customer tapping one lands on their bookings, not home', (
    tester,
  ) async {
    // The gap this test exists for: four of the five go to the customer,
    // whose jobs are a tab away from where the app opens.
    final requests = await _jobAt(RequestContactStatus.accepted);
    final push = FakePushService();

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      jobs: FakeJobsRepository(contacts: requests.contacts, requests: requests),
      push: push,
    );

    // Starts on the home screen.
    expect(find.text('Was brauchst du?'), findsOneWidget);

    push.tap(
      PushMessage(
        kind: PushKind.requestAccepted,
        contactId: _contactOf(requests),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buchungen'), findsWidgets);
    expect(find.text('Max Montagen'), findsOneWidget);
    expect(
      providerContainerOf(tester).read(highlightedJobProvider),
      _contactOf(requests),
    );
  });

  testWidgets('a provider tapping one lands on their jobs', (tester) async {
    final requests = await _jobAt(RequestContactStatus.completed);
    final push = FakePushService();

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
      jobs: FakeJobsRepository(
        contacts: requests.contacts,
        requests: requests,
        isProvider: true,
      ),
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
      ),
      push: push,
    );

    push.tap(
      PushMessage(kind: PushKind.jobConfirmed, contactId: _contactOf(requests)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Hallo'), findsWidgets);
    expect(
      providerContainerOf(tester).read(highlightedJobProvider),
      _contactOf(requests),
    );
  });

  testWidgets('one arriving while the app is open still reloads the list', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    final push = FakePushService();
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      jobs: FakeJobsRepository(contacts: requests.contacts, requests: requests),
      push: push,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Buchungen'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Max Montagen'), findsNothing);

    // The provider accepts while the customer is looking at the screen.
    final stored = await requests.create(
      ServiceRequestDraft(
        description: _job,
        service: testFlatCleaning,
        city: 'Wien',
      ),
    );
    requests.contacts.send(requestId: stored.id, providerId: testProviderId);
    requests.contacts.respond(
      requests.contacts.contactId(stored.id, testProviderId),
      RequestContactStatus.accepted,
    );

    push.arrive(const PushMessage(kind: PushKind.requestAccepted));
    await tester.pumpAndSettle();

    // No pull to refresh, no tab switch: the job is simply there.
    await scrollTo(tester, find.text('Max Montagen'));
    expect(find.text('Max Montagen'), findsOneWidget);
  });

  testWidgets('a notification about nothing does not move anybody', (
    tester,
  ) async {
    final push = FakePushService();
    await pumpSignedInApp(tester, role: AppRole.customer, push: push);

    push.tap(const PushMessage(kind: PushKind.appointmentAgreed));
    await tester.pumpAndSettle();

    // Still where they were: without a job to open, moving them would be
    // taking the screen away for nothing.
    expect(find.text('Was brauchst du?'), findsOneWidget);
    expect(providerContainerOf(tester).read(highlightedJobProvider), isNull);
  });

  testWidgets('the steps that notify are the steps that happen', (
    tester,
  ) async {
    // Reads as documentation of who hears about what. The database decides
    // it; this records the intent next to the code that relies on it.
    const goesToCustomer = {
      RequestContactStatus.accepted,
      RequestContactStatus.scheduled,
      RequestContactStatus.onTheWay,
      RequestContactStatus.completed,
    };
    const goesToProvider = {RequestContactStatus.customerConfirmed};
    const tellsNobody = {RequestContactStatus.inProgress};

    // Every status in the flow is accounted for, so a new one cannot be
    // added without somebody deciding who hears about it.
    final covered = {...goesToCustomer, ...goesToProvider, ...tellsNobody};
    final inFlow = RequestContactStatus.values
        .where((status) => status.isJob)
        .toSet();
    expect(covered, inFlow);
  });
}
