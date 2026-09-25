import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/chat/domain/chat_message.dart';
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

/// One request that the provider has already accepted — the only state in
/// which a chat exists at all.
Future<InMemoryServiceRequestRepository> _withAcceptedJob() async {
  final requests = InMemoryServiceRequestRepository();
  final stored = await requests.create(
    ServiceRequestDraft(
      description: 'Kasten aufbauen',
      service: testFlatCleaning,
      city: 'Wien',
    ),
  );
  requests.contacts.send(requestId: stored.id, providerId: testProviderId);
  requests.contacts.respond(
    requests.contacts.contactId(stored.id, testProviderId),
    RequestContactStatus.accepted,
  );
  return requests;
}

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Bookings → the accepted request's provider list.
Future<void> _openProviderList(WidgetTester tester) async {
  await tester.tap(_navLabel('Buchungen'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(OutlinedButton, 'Passende Anbieter'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the customer opens the chat with the provider who accepted', (
    tester,
  ) async {
    final requests = await _withAcceptedJob();
    final chat = FakeChatRepository(contacts: requests.contacts);
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        requests: requests,
      ),
      chat: chat,
    );
    await _openProviderList(tester);

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Dienstleister kontaktieren'),
    );
    await tester.pumpAndSettle();

    // The header says who and about what, and does not claim a time was
    // agreed, because nothing in the app agrees one yet.
    expect(find.text('Max Montagen'), findsOneWidget);
    expect(find.text('Wohnungsreinigung'), findsOneWidget);
    expect(find.text('Termin noch nicht vereinbart'), findsOneWidget);
    expect(find.text('Noch keine Nachrichten'), findsOneWidget);
  });

  testWidgets('a provider who has not answered offers no chat', (tester) async {
    final requests = InMemoryServiceRequestRepository();
    final stored = await requests.create(
      ServiceRequestDraft(description: 'Kasten', service: testFlatCleaning),
    );
    // Sent, not answered.
    requests.contacts.send(requestId: stored.id, providerId: testProviderId);

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        requests: requests,
      ),
      chat: FakeChatRepository(contacts: requests.contacts),
    );
    await _openProviderList(tester);

    expect(find.text('Anfrage gesendet'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Dienstleister kontaktieren'),
      findsNothing,
    );
  });

  testWidgets('a provider who declined offers no chat either', (tester) async {
    final requests = InMemoryServiceRequestRepository();
    final stored = await requests.create(
      ServiceRequestDraft(description: 'Kasten', service: testFlatCleaning),
    );
    requests.contacts.send(requestId: stored.id, providerId: testProviderId);
    requests.contacts.respond(
      requests.contacts.contactId(stored.id, testProviderId),
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
      chat: FakeChatRepository(contacts: requests.contacts),
    );
    await _openProviderList(tester);

    expect(find.text('Abgelehnt'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Dienstleister kontaktieren'),
      findsNothing,
    );
  });

  testWidgets('sending stores the message and clears the field', (
    tester,
  ) async {
    final requests = await _withAcceptedJob();
    final chat = FakeChatRepository(contacts: requests.contacts);
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        requests: requests,
      ),
      chat: chat,
    );
    await _openProviderList(tester);
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Dienstleister kontaktieren'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Passt Mittwoch 14 Uhr?');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    final stored = chat.messageLog.values.single;
    expect(stored.single.message, 'Passt Mittwoch 14 Uhr?');
    // Written as the signed-in account, never as a name the screen chose.
    expect(stored.single.senderId, testUserId);
    expect(find.text('Passt Mittwoch 14 Uhr?'), findsOneWidget);
    expect(find.text('Noch keine Nachrichten'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('an empty message cannot be sent', (tester) async {
    final requests = await _withAcceptedJob();
    final chat = FakeChatRepository(contacts: requests.contacts);
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        requests: requests,
      ),
      chat: chat,
    );
    await _openProviderList(tester);
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Dienstleister kontaktieren'),
    );
    await tester.pumpAndSettle();

    // Whitespace is not a message.
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.send),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(chat.messageLog, isEmpty);
  });

  testWidgets('the provider opens the same conversation, not a second one', (
    tester,
  ) async {
    final requests = await _withAcceptedJob();
    final chat = FakeChatRepository(contacts: requests.contacts);

    // The customer writes first.
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        requests: requests,
      ),
      chat: chat,
    );
    await _openProviderList(tester);
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Dienstleister kontaktieren'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Wann hast du Zeit?');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Now the provider. The same store serves them, the way one database
    // serves two accounts — which is the whole point of this test.
    chat.isProvider = true;
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
      chat: chat,
      jobs: FakeJobsRepository(
        contacts: requests.contacts,
        requests: requests,
        isProvider: true,
      ),
    );
    // An accepted request is a job now, and the chat hangs off its card.
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Nachricht schreiben'),
    );
    await tester.pumpAndSettle();

    // One conversation for the job, so the customer's message is here.
    expect(chat.conversations, hasLength(1));
    expect(find.text('Wann hast du Zeit?'), findsOneWidget);
  });

  testWidgets('opening the chat twice does not create a second one', (
    tester,
  ) async {
    final requests = await _withAcceptedJob();
    final chat = FakeChatRepository(contacts: requests.contacts);
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        requests: requests,
      ),
      chat: chat,
    );
    await _openProviderList(tester);

    for (var i = 0; i < 2; i++) {
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Dienstleister kontaktieren'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }

    expect(chat.conversations, hasLength(1));
  });

  testWidgets('the other person\'s messages sit on the other side', (
    tester,
  ) async {
    final requests = await _withAcceptedJob();
    final chat = FakeChatRepository(contacts: requests.contacts);
    final conversation = await chat.getOrCreateConversationForRequest(
      requestId: requests.requests.single.id,
      providerId: testProviderId,
    );
    // One message from each account. On a device with a single account
    // both would be "mine", which is why this lives in a test.
    chat.messageLog[conversation.id] = [
      ChatMessage(
        id: 'm1',
        conversationId: conversation.id,
        senderId: testUserId,
        message: 'Wann hast du Zeit?',
        createdAt: DateTime(2026, 1, 1, 10),
      ),
      ChatMessage(
        id: 'm2',
        conversationId: conversation.id,
        senderId: testProviderUserId,
        message: 'Mittwoch passt mir',
        createdAt: DateTime(2026, 1, 1, 10, 5),
      ),
    ];

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: [_maxMontagen],
        requests: requests,
      ),
      chat: chat,
    );
    await _openProviderList(tester);
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Dienstleister kontaktieren'),
    );
    await tester.pumpAndSettle();

    Alignment alignmentOf(String text) => tester
        .widget<Align>(
          find
              .ancestor(of: find.text(text), matching: find.byType(Align))
              .first,
        )
        .alignment
        .resolve(TextDirection.ltr);

    expect(alignmentOf('Wann hast du Zeit?'), Alignment.centerRight);
    expect(alignmentOf('Mittwoch passt mir'), Alignment.centerLeft);
  });

  testWidgets('a chat for a job that was never accepted is refused', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    final stored = await requests.create(
      ServiceRequestDraft(description: 'Kasten', service: testFlatCleaning),
    );
    // Sent but unanswered: there is no job to talk about yet.
    requests.contacts.send(requestId: stored.id, providerId: testProviderId);
    final chat = FakeChatRepository(contacts: requests.contacts);

    expect(
      () => chat.getOrCreateConversationForRequest(
        requestId: stored.id,
        providerId: testProviderId,
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(chat.conversations, isEmpty);
  });

  testWidgets('a chat for somebody else\'s job is refused', (tester) async {
    final requests = await _withAcceptedJob();
    final chat = FakeChatRepository(contacts: requests.contacts);

    expect(
      () => chat.getOrCreateConversationForRequest(
        requestId: requests.requests.single.id,
        // A provider who was never sent this request.
        providerId: 'provider-2',
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(chat.conversations, isEmpty);
  });
}
