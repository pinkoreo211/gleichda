import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/notifications/application/push_controller.dart';
import 'package:app/features/notifications/domain/push_message.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

const _cleaning = 'Bitte einmal die Wohnung reinigen';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// One request waiting for the provider.
Future<InMemoryServiceRequestRepository> _waitingRequest() async {
  final requests = InMemoryServiceRequestRepository();
  final stored = await requests.create(
    ServiceRequestDraft(
      description: _cleaning,
      service: testFlatCleaning,
      city: 'Wien',
    ),
  );
  requests.contacts.send(requestId: stored.id, providerId: testProviderId);
  return requests;
}

Future<void> _pumpProvider(
  WidgetTester tester, {
  required FakePushService push,
  FakePushTokenRepository? tokens,
  InMemoryServiceRequestRepository? requests,
}) async {
  final store = requests ?? InMemoryServiceRequestRepository();
  await pumpSignedInApp(
    tester,
    role: AppRole.provider,
    requests: store,
    incoming: FakeIncomingRequestsRepository(requests: store),
    provider: FakeProviderRepository(
      hasProfile: true,
      status: ProviderOnboardingStatus.completed,
    ),
    push: push,
    pushTokens: tokens,
  );
}

void main() {
  testWidgets('a provider on their job list is asked about notifications', (
    tester,
  ) async {
    final push = FakePushService();
    final tokens = FakePushTokenRepository();
    await _pumpProvider(tester, push: push, tokens: tokens);

    expect(push.permissionRequests, 1);
    // Saying yes registers this device, so the backend knows where to
    // reach them.
    expect(tokens.registered, contains('device-token-1'));
  });

  testWidgets('the app asks once, not on every rebuild', (tester) async {
    final push = FakePushService();
    await _pumpProvider(tester, push: push);

    // Moving around the app must not ask again: the operating system shows
    // its dialog once, and asking again would only look broken.
    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('Aufträge'));
    await tester.pumpAndSettle();

    expect(push.permissionRequests, 1);
  });

  testWidgets('saying no leaves the app working and registers nothing', (
    tester,
  ) async {
    final push = FakePushService(grantsPermission: false);
    final tokens = FakePushTokenRepository();
    final requests = await _waitingRequest();
    await _pumpProvider(tester, push: push, tokens: tokens, requests: requests);

    expect(tokens.registered, isEmpty);
    // And the screen is the screen, not an error.
    expect(find.text('Hallo'), findsWidgets);
    await scrollTo(tester, find.text(_cleaning));
    expect(find.text(_cleaning), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a build with no push provider asks nobody anything', (
    tester,
  ) async {
    final push = FakePushService(isAvailable: false);
    final tokens = FakePushTokenRepository();
    await _pumpProvider(tester, push: push, tokens: tokens);

    expect(push.permissionRequests, 0);
    expect(tokens.registered, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a backend that refuses the token does not break anything', (
    tester,
  ) async {
    final tokens = FakePushTokenRepository()..failure = AppFailure.unknown;
    await _pumpProvider(tester, push: FakePushService(), tokens: tokens);

    expect(tokens.registered, isEmpty);
    // The person sees their screen; they did nothing wrong.
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new token replaces the old one', (tester) async {
    final push = FakePushService();
    final tokens = FakePushTokenRepository();
    await _pumpProvider(tester, push: push, tokens: tokens);

    push.rotateToken('device-token-2');
    await tester.pumpAndSettle();

    expect(tokens.registered, contains('device-token-2'));
  });

  testWidgets('tapping a notification opens the job it was about', (
    tester,
  ) async {
    final push = FakePushService();
    final requests = await _waitingRequest();
    await _pumpProvider(tester, push: push, requests: requests);

    final contactId = requests.contacts.contactId(
      requests.requests.single.id,
      testProviderId,
    );

    push.tap(PushMessage(kind: PushKind.bookingReceived, contactId: contactId));
    await tester.pumpAndSettle();

    final container = providerContainerOf(tester);
    expect(container.read(highlightedJobProvider), contactId);

    // And the card for that job is the one marked out.
    await scrollTo(tester, find.text(_cleaning));
    final cards = tester.widgetList<Card>(find.byType(Card));
    expect(
      cards.where((card) => card.shape is RoundedRectangleBorder).length,
      1,
    );
  });

  testWidgets('one arriving while the app is open reloads the list', (
    tester,
  ) async {
    final push = FakePushService();
    final requests = InMemoryServiceRequestRepository();
    await _pumpProvider(tester, push: push, requests: requests);

    expect(find.text(_cleaning), findsNothing);

    // The request arrives on the server while the provider is looking at
    // the screen. Android shows nothing in that case, so the app has to.
    final stored = await requests.create(
      ServiceRequestDraft(
        description: _cleaning,
        service: testFlatCleaning,
        city: 'Wien',
      ),
    );
    requests.contacts.send(requestId: stored.id, providerId: testProviderId);

    push.arrive(const PushMessage(kind: PushKind.bookingReceived));
    await tester.pumpAndSettle();

    // No pull to refresh, no tab switch: it is simply there.
    await scrollTo(tester, find.text(_cleaning));
    expect(find.text(_cleaning), findsOneWidget);
  });

  testWidgets('a notification about an accepted job marks that job too', (
    tester,
  ) async {
    // The gap this test exists for: a request the provider already
    // accepted is no longer in "requests for you", it is a job. A
    // notification about it has to mark it there.
    final requests = await _waitingRequest();
    final contactId = requests.contacts.contactId(
      requests.requests.single.id,
      testProviderId,
    );
    requests.contacts.respond(contactId, RequestContactStatus.accepted);

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

    push.tap(PushMessage(kind: PushKind.bookingReceived, contactId: contactId));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Wohnungsreinigung').first);
    final outlined = tester
        .widgetList<Card>(find.byType(Card))
        .where((card) => card.shape is RoundedRectangleBorder);
    expect(outlined.length, 1);
  });

  testWidgets('a notification about nothing opens nothing in particular', (
    tester,
  ) async {
    final push = FakePushService();
    await _pumpProvider(tester, push: push);

    push.tap(const PushMessage(kind: PushKind.bookingReceived));
    await tester.pumpAndSettle();

    expect(providerContainerOf(tester).read(highlightedJobProvider), isNull);
  });

  testWidgets('a notification that started the app is handled too', (
    tester,
  ) async {
    final requests = await _waitingRequest();
    final contactId = requests.contacts.contactId(
      requests.requests.single.id,
      testProviderId,
    );
    // Nobody was listening when this was tapped: the app was closed.
    final push = FakePushService(
      startedFrom: PushMessage(
        kind: PushKind.bookingReceived,
        contactId: contactId,
      ),
    );

    await _pumpProvider(tester, push: push, requests: requests);
    await tester.pumpAndSettle();

    expect(providerContainerOf(tester).read(highlightedJobProvider), contactId);
  });

  testWidgets('signing out takes this device off the account', (tester) async {
    final push = FakePushService();
    final tokens = FakePushTokenRepository();
    await _pumpProvider(tester, push: push, tokens: tokens);
    expect(tokens.registered, contains('device-token-1'));

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Abmelden'));
    await tester.tap(find.text('Abmelden'));
    await tester.pumpAndSettle();

    // Otherwise the next person on this phone gets the last one's pushes.
    expect(tokens.forgotten, contains('device-token-1'));
    expect(tokens.registered, isEmpty);
  });

  testWidgets('the kinds match the names the database uses', (tester) async {
    // A mismatch here would mean a real notification arrives and the app
    // quietly does not know what it is.
    expect(PushKind.fromName('booking_received'), PushKind.bookingReceived);
    expect(PushKind.fromName('request_accepted'), PushKind.requestAccepted);
    expect(PushKind.fromName('chat_message'), PushKind.chatMessage);
    expect(PushKind.fromName('something_new'), isNull);

    final message = PushMessage.fromData(const {
      'kind': 'booking_received',
      'contact_id': 'contact-1',
    });
    expect(message.kind, PushKind.bookingReceived);
    expect(message.contactId, 'contact-1');
    expect(message.opensAJob, isTrue);

    // FCM sends empty strings rather than leaving a key out.
    expect(
      PushMessage.fromData(const {'kind': 'chat_message', 'contact_id': ''})
          .opensAJob,
      isFalse,
    );
  });
}
