import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/chat/data/chat_repository.dart';
import 'package:app/features/chat/domain/chat_message.dart';
import 'package:app/features/chat/domain/conversation.dart';

/// Which job a chat belongs to.
///
/// [providerId] is null when the provider opens it — the backend then works
/// out which profile that is from the signed-in account.
typedef ChatTarget = ({String requestId, String? providerId});

/// The conversation for one job, opened on first use.
///
/// `autoDispose` so leaving the chat and coming back asks the server again
/// instead of showing what was true when the screen was first built.
final conversationProvider = FutureProvider.autoDispose
    .family<Conversation, ChatTarget>((ref, target) async {
      return ref
          .watch(chatRepositoryProvider)
          .getOrCreateConversationForRequest(
            requestId: target.requestId,
            providerId: target.providerId,
          );
    });

/// The messages in one conversation, oldest first.
///
/// Re-read after sending and when the chat is reopened. Without realtime
/// that is the honest amount of freshness this can promise.
final chatMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, conversationId) async {
      return ref.watch(chatRepositoryProvider).messages(conversationId);
    });
