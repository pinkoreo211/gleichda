import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/chat/domain/chat_message.dart';
import 'package:app/features/chat/domain/conversation.dart';
import 'package:app/features/chat/domain/conversation_summary.dart';

/// The chat between a customer and the provider who took their job.
///
/// Opening a conversation goes through one backend function, so whether the
/// job was really accepted and whether the caller belongs in it are decided
/// by the database, not by the phone. Throws [AppFailure] on errors.
abstract interface class ChatRepository {
  /// The conversation for one accepted job, created the first time and
  /// returned unchanged after that.
  ///
  /// [providerId] is the provider the customer picked. A provider passes
  /// null: the backend then uses their own profile, so they cannot open a
  /// job that was never theirs.
  Future<Conversation> getOrCreateConversationForRequest({
    required String requestId,
    String? providerId,
  });

  /// Every conversation the signed-in person is part of, newest activity
  /// first, each with the other person's name and the last message.
  Future<List<ConversationSummary>> myConversations();

  /// Oldest first, the order a conversation is read in.
  Future<List<ChatMessage>> messages(String conversationId);

  /// Sends [text] as the signed-in user. The sender is set by the backend;
  /// it is not something the app can choose.
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
  });
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => SupabaseChatRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client);

  final SupabaseClient _client;

  static const _messages = 'messages';

  @override
  Future<Conversation> getOrCreateConversationForRequest({
    required String requestId,
    String? providerId,
  }) async {
    try {
      final row = await _client.rpc<Map<String, dynamic>>(
        'get_or_create_conversation',
        params: {
          'target_request_id': requestId,
          'target_provider_id': providerId,
        },
      );
      return Conversation.fromJson(row);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<List<ConversationSummary>> myConversations() async {
    try {
      // One call: the backend joins the names and the last message, so a
      // provider with a hundred jobs costs the same round trip as one
      // with two.
      final rows = await _client.rpc<List<dynamic>>('my_conversations');
      return [
        for (final row in rows.whereType<Map<String, dynamic>>())
          ConversationSummary.fromJson(row),
      ];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<List<ChatMessage>> messages(String conversationId) async {
    try {
      final rows = await _client
          .from(_messages)
          .select()
          .eq('conversation_id', conversationId)
          // Spelled out: the Supabase client sorts descending by default,
          // which would show a conversation back to front.
          .order('created_at', ascending: true);
      return [for (final row in rows) ChatMessage.fromJson(row)];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw AppFailure.messageEmpty;
    try {
      // sender_id is absent on purpose: the column is not writable by
      // clients and defaults to the signed-in user.
      final row = await _client
          .from(_messages)
          .insert({'conversation_id': conversationId, 'message': trimmed})
          .select()
          .single();
      return ChatMessage.fromJson(row);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
