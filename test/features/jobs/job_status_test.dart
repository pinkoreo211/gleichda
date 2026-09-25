import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

/// One accepted job, optionally already moved along to [status].
Future<InMemoryServiceRequestRepository> _job({
  RequestContactStatus status = RequestContactStatus.accepted,
}) async {
  final requests = InMemoryServiceRequestRepository();
  final stored = await requests.create(
    ServiceRequestDraft(
      description: 'Kasten aufbauen',
      service: testFlatCleaning,
      city: 'Wien',
    ),
  );
  final contactId = requests.contacts.contactId(stored.id, testProviderId);
  requests.contacts.send(requestId: stored.id, providerId: testProviderId);
  requests.contacts.respond(contactId, RequestContactStatus.accepted);
  if (status != RequestContactStatus.accepted) {
    requests.contacts.setStatus(contactId, status);
  }
  return requests;
}

String _contactOf(InMemoryServiceRequestRepository requests) =>
    requests.contacts.contactId(requests.requests.single.id, testProviderId);

RequestContactStatus? _statusOf(InMemoryServiceRequestRepository requests) =>
    requests.contacts.statusOf(_contactOf(requests));

Future<FakeJobsRepository> _pump(
  WidgetTester tester,
  InMemoryServiceRequestRepository requests, {
  required bool asProvider,
}) async {
  final jobs = FakeJobsRepository(
    contacts: requests.contacts,
    requests: requests,
    isProvider: asProvider,
  );
  await pumpSignedInApp(
    tester,
    role: asProvider ? AppRole.provider : AppRole.customer,
    requests: requests,
    incoming: FakeIncomingRequestsRepository(requests: requests),
    jobs: jobs,
  );
  if (!asProvider) {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Buchungen'),
      ),
    );
    await tester.pumpAndSettle();
  }
  return jobs;
}

void main() {
  testWidgets('a fresh job offers a time and nothing further', (tester) async {
    final requests = await _job();
    await _pump(tester, requests, asProvider: true);

    expect(find.text('Angenommen'), findsOneWidget);
    expect(find.text('Termin noch nicht vereinbart'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Termin vereinbaren'), findsOne);
    // The later steps are shown as still ahead, not as something to press.
    expect(
      find.widgetWithText(FilledButton, 'Ich bin unterwegs'),
      findsNothing,
    );
    expect(find.widgetWithText(FilledButton, 'Auftrag fertig'), findsNothing);
  });

  testWidgets('the provider walks the job through to done', (tester) async {
    final requests = await _job(status: RequestContactStatus.scheduled);
    await _pump(tester, requests, asProvider: true);

    await tester.tap(find.widgetWithText(FilledButton, 'Ich bin unterwegs'));
    await tester.pumpAndSettle();
    expect(_statusOf(requests), RequestContactStatus.onTheWay);

    await tester.tap(find.widgetWithText(FilledButton, 'Arbeit beginnen'));
    await tester.pumpAndSettle();
    expect(_statusOf(requests), RequestContactStatus.inProgress);

    await tester.tap(find.widgetWithText(FilledButton, 'Auftrag fertig'));
    await tester.pumpAndSettle();
    expect(_statusOf(requests), RequestContactStatus.completed);

    // And then it is the customer's turn, which the card says plainly.
    expect(find.textContaining('Warte auf die Bestätigung'), findsWidgets);
    expect(
      find.widgetWithText(FilledButton, 'Auftrag bestätigen'),
      findsNothing,
    );
  });

  testWidgets('the customer confirms, and the job is finished', (tester) async {
    final requests = await _job(status: RequestContactStatus.completed);
    await _pump(tester, requests, asProvider: false);

    // Twice: as the headline and as the reached step in the list below it.
    expect(find.text('Fertig'), findsNWidgets(2));
    expect(find.textContaining('Bitte bestätige'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Auftrag bestätigen'));
    await tester.pumpAndSettle();

    expect(_statusOf(requests), RequestContactStatus.customerConfirmed);
    expect(find.text('Auftrag abgeschlossen'), findsOneWidget);
  });

  testWidgets('the customer is not offered the provider\'s steps', (
    tester,
  ) async {
    final requests = await _job(status: RequestContactStatus.scheduled);
    await _pump(tester, requests, asProvider: false);

    expect(find.text('Termin vereinbart'), findsWidgets);
    expect(
      find.widgetWithText(FilledButton, 'Ich bin unterwegs'),
      findsNothing,
    );
    expect(find.widgetWithText(FilledButton, 'Arbeit beginnen'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Auftrag fertig'), findsNothing);
  });

  testWidgets(
    'the provider cannot confirm the work on the customer\'s behalf',
    (tester) async {
      final requests = await _job(status: RequestContactStatus.completed);
      final jobs = await _pump(tester, requests, asProvider: true);

      expect(
        find.widgetWithText(FilledButton, 'Auftrag bestätigen'),
        findsNothing,
      );
      // And not merely hidden: the store refuses it the way the backend does.
      expect(
        () => jobs.advance(
          contactId: _contactOf(requests),
          status: RequestContactStatus.customerConfirmed,
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(_statusOf(requests), RequestContactStatus.completed);
    },
  );

  testWidgets('a job cannot skip from accepted straight to done', (
    tester,
  ) async {
    final requests = await _job();
    final jobs = await _pump(tester, requests, asProvider: true);

    for (final skipped in [
      RequestContactStatus.onTheWay,
      RequestContactStatus.inProgress,
      RequestContactStatus.completed,
      RequestContactStatus.customerConfirmed,
    ]) {
      expect(
        () => jobs.advance(contactId: _contactOf(requests), status: skipped),
        throwsA(isA<AppFailure>()),
        reason: 'accepted must not jump to ${skipped.dbValue}',
      );
    }
    expect(_statusOf(requests), RequestContactStatus.accepted);
  });

  testWidgets('a finished job cannot be pushed backwards', (tester) async {
    final requests = await _job(status: RequestContactStatus.customerConfirmed);
    final jobs = await _pump(tester, requests, asProvider: true);

    expect(
      () => jobs.advance(
        contactId: _contactOf(requests),
        status: RequestContactStatus.inProgress,
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(_statusOf(requests), RequestContactStatus.customerConfirmed);
  });

  testWidgets('a time must be given with the appointment', (tester) async {
    final requests = await _job();
    final jobs = await _pump(tester, requests, asProvider: true);

    expect(
      () => jobs.advance(
        contactId: _contactOf(requests),
        status: RequestContactStatus.scheduled,
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(_statusOf(requests), RequestContactStatus.accepted);
  });

  testWidgets('the chat is reachable from the job', (tester) async {
    final requests = await _job(status: RequestContactStatus.scheduled);
    await _pump(tester, requests, asProvider: true);

    expect(
      find.widgetWithText(OutlinedButton, 'Nachricht schreiben'),
      findsOneWidget,
    );
  });
}
