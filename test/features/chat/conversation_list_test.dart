import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/chat/domain/chat_message.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

/// Adds one accepted job and returns its request id.
Future<String> _acceptedJob(
  InMemoryServiceRequestRepository requests, {
  required String description,
  required Service service,
}) async {
  final stored = await requests.create(
    ServiceRequestDraft(description: description, service: service),
  );
  requests.contacts.send(requestId: stored.id, providerId: testProviderId);
  requests.contacts.respond(
    requests.contacts.contactId(stored.id, testProviderId),
    RequestContactStatus.accepted,
  );
  return stored.id;
}

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('with no conversations the tab says so, and only then', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      chat: FakeChatRepository(contacts: requests.contacts),
    );

    await tester.tap(_navLabel('Chats'));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Chats'), findsOneWidget);
    expect(
      find.textContaining('Sobald ein Dienstleister deine Anfrage annimmt'),
      findsOneWidget,
    );
  });

  testWidgets('a customer sees the provider, the job and the last message', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    final requestId = await _acceptedJob(
      requests,
      description: 'Kasten aufbauen',
      service: testFlatCleaning,
    );
    final chat = FakeChatRepository(
      contacts: requests.contacts,
      requests: requests,
    );
    final conversation = await chat.getOrCreateConversationForRequest(
      requestId: requestId,
      providerId: testProviderId,
    );
    await chat.sendMessage(
      conversationId: conversation.id,
      text: 'Ja, morgen passt.',
    );

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      chat: chat,
    );
    await tester.tap(_navLabel('Chats'));
    await tester.pumpAndSettle();

    // The other person, never the reader themselves.
    expect(find.text('Max Montagen'), findsOneWidget);
    expect(find.text('Anna Kundin'), findsNothing);
    expect(find.text('Wohnungsreinigung'), findsOneWidget);
    expect(find.text('Ja, morgen passt.'), findsOneWidget);
  });

  testWidgets('a provider sees the customer, not themselves', (tester) async {
    final requests = InMemoryServiceRequestRepository();
    final requestId = await _acceptedJob(
      requests,
      description: 'Kasten aufbauen',
      service: testFlatCleaning,
    );
    final chat = FakeChatRepository(
      contacts: requests.contacts,
      requests: requests,
      isProvider: true,
    );
    await chat.getOrCreateConversationForRequest(requestId: requestId);

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
      chat: chat,
    );
    await tester.tap(_navLabel('Chats'));
    await tester.pumpAndSettle();

    expect(find.text('Anna Kundin'), findsOneWidget);
    expect(find.text('Max Montagen'), findsNothing);
  });

  testWidgets('a conversation nobody has written in says so', (tester) async {
    final requests = InMemoryServiceRequestRepository();
    final requestId = await _acceptedJob(
      requests,
      description: 'Kasten aufbauen',
      service: testFlatCleaning,
    );
    final chat = FakeChatRepository(
      contacts: requests.contacts,
      requests: requests,
    );
    await chat.getOrCreateConversationForRequest(
      requestId: requestId,
      providerId: testProviderId,
    );

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      chat: chat,
    );
    await tester.tap(_navLabel('Chats'));
    await tester.pumpAndSettle();

    // A row, not the empty state: the conversation exists.
    expect(find.text('Max Montagen'), findsOneWidget);
    expect(find.text('Noch keine Chats'), findsNothing);
    expect(find.text('Noch keine Nachrichten'), findsOneWidget);
  });

  testWidgets('each chat shows its own last message, newest first', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    final firstId = await _acceptedJob(
      requests,
      description: 'Kasten aufbauen',
      service: testFlatCleaning,
    );
    final secondId = await _acceptedJob(
      requests,
      description: 'Lampe montieren',
      service: testFurnitureAssembly,
    );
    final chat = FakeChatRepository(
      contacts: requests.contacts,
      requests: requests,
    );
    final first = await chat.getOrCreateConversationForRequest(
      requestId: firstId,
      providerId: testProviderId,
    );
    final second = await chat.getOrCreateConversationForRequest(
      requestId: secondId,
      providerId: testProviderId,
    );
    await chat.sendMessage(conversationId: first.id, text: 'Aelter');
    // Explicitly later, so the order is about time and not insertion.
    chat.messageLog[second.id] = [
      ChatMessage(
        id: 'm-newer',
        conversationId: second.id,
        senderId: testUserId,
        message: 'Neuer',
        createdAt: DateTime(2026, 6, 1, 12),
      ),
    ];

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      chat: chat,
    );
    await tester.tap(_navLabel('Chats'));
    await tester.pumpAndSettle();

    expect(find.text('Aelter'), findsOneWidget);
    expect(find.text('Neuer'), findsOneWidget);
    // The newer conversation sits above the older one.
    final newer = tester.getTopLeft(find.text('Neuer')).dy;
    final older = tester.getTopLeft(find.text('Aelter')).dy;
    expect(newer, lessThan(older));
  });

  testWidgets('tapping a chat opens that conversation, without making one', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    final requestId = await _acceptedJob(
      requests,
      description: 'Kasten aufbauen',
      service: testFlatCleaning,
    );
    final chat = FakeChatRepository(
      contacts: requests.contacts,
      requests: requests,
    );
    final conversation = await chat.getOrCreateConversationForRequest(
      requestId: requestId,
      providerId: testProviderId,
    );
    await chat.sendMessage(
      conversationId: conversation.id,
      text: 'Bis morgen dann',
    );

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      chat: chat,
    );
    await tester.tap(_navLabel('Chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Max Montagen'));
    await tester.pumpAndSettle();

    // The existing conversation, with its message -- and still only one.
    expect(find.text('Bis morgen dann'), findsOneWidget);
    expect(find.text('Termin noch nicht vereinbart'), findsOneWidget);
    expect(chat.conversations, hasLength(1));
  });

  testWidgets('a failed read is explained, not shown as "no chats"', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      chat: FakeChatRepository(
        contacts: requests.contacts,
        listFailure: AppFailure.unknown,
      ),
    );

    await tester.tap(_navLabel('Chats'));
    await tester.pumpAndSettle();

    expect(find.text('Chats konnten nicht geladen werden.'), findsOneWidget);
    expect(find.text('Noch keine Chats'), findsNothing);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });
}
