import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/core/formatting/app_date_format.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/chat/application/chat_providers.dart';
import 'package:app/features/chat/data/chat_repository.dart';
import 'package:app/features/chat/domain/chat_message.dart';
import 'package:app/features/chat/domain/conversation.dart';
import 'package:app/l10n/app_localizations.dart';

/// What the screen knows about the other person before it loads anything.
///
/// Passed along when the chat is opened, because the side that opens it
/// already has the name on screen. Both are optional: a link opened cold
/// still works, it just says less in the header.
class ChatArgs {
  const ChatArgs({this.otherName, this.serviceName});

  final String? otherName;
  final String? serviceName;
}

/// The private conversation for one accepted job.
///
/// Customer and provider open the same conversation: the backend keys it by
/// the job, so there is no way for the two of them to end up in separate
/// rooms talking past each other.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.requestId,
    this.providerId,
    this.args = const ChatArgs(),
  });

  final String requestId;

  /// The provider the customer picked. Null when the provider opens their
  /// own job — the backend then resolves it from the signed-in account.
  final String? providerId;

  final ChatArgs args;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _isSending = false;

  ChatTarget get _target =>
      (requestId: widget.requestId, providerId: widget.providerId);

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// After the list has rebuilt, not before: the new message has no extent
  /// until then, so scrolling now would stop short of it.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send(Conversation conversation) async {
    final text = _input.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(conversationId: conversation.id, text: text);
      if (!mounted) return;
      // Cleared only after the backend accepted it, so a failed send does
      // not also lose what was typed.
      _input.clear();
      ref.invalidate(chatMessagesProvider(conversation.id));
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final conversation = ref.watch(conversationProvider(_target));

    return Scaffold(
      appBar: AppBar(
        title: _Header(
          name: widget.args.otherName ?? l10n.chatOtherUnknown,
          serviceName: widget.args.serviceName,
        ),
      ),
      body: SafeArea(
        child: switch (conversation) {
          AsyncData(:final value) => _Conversation(
            conversation: value,
            input: _input,
            scroll: _scroll,
            isSending: _isSending,
            onSend: () => _send(value),
            onMessagesShown: _scrollToEnd,
          ),
          AsyncError() => _LoadError(
            onRetry: () => ref.invalidate(conversationProvider(_target)),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// Who this is with, and about what. The appointment line is deliberately
/// plain: nothing in the app agrees a time yet, and the customer's "as soon
/// as possible" is a wish, not an arrangement — showing it as one would be
/// the app putting words in the provider's mouth.
class _Header extends StatelessWidget {
  const _Header({required this.name, required this.serviceName});

  final String name;
  final String? serviceName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: theme.textTheme.titleMedium),
        if (serviceName != null && serviceName!.isNotEmpty)
          Text(
            serviceName!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Text(
          l10n.chatNoAppointment,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: AppIconSize.xl,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.chatLoadFailed, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.catalogRetry)),
          ],
        ),
      ),
    );
  }
}

class _Conversation extends ConsumerWidget {
  const _Conversation({
    required this.conversation,
    required this.input,
    required this.scroll,
    required this.isSending,
    required this.onSend,
    required this.onMessagesShown,
  });

  final Conversation conversation;
  final TextEditingController input;
  final ScrollController scroll;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onMessagesShown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final messages = ref.watch(chatMessagesProvider(conversation.id));
    final myId = ref.watch(currentUserIdProvider);

    return Column(
      children: [
        Expanded(
          child: switch (messages) {
            AsyncData(:final value) when value.isEmpty => EmptyState(
              icon: Icons.chat_bubble_outline,
              title: l10n.chatEmptyTitle,
              message: l10n.chatEmptyMessage,
            ),
            AsyncData(:final value) => _MessageList(
              messages: value,
              myId: myId,
              scroll: scroll,
              onShown: onMessagesShown,
            ),
            AsyncError() => _LoadError(
              onRetry: () =>
                  ref.invalidate(chatMessagesProvider(conversation.id)),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
        _Composer(input: input, isSending: isSending, onSend: onSend),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.myId,
    required this.scroll,
    required this.onShown,
  });

  final List<ChatMessage> messages;
  final String? myId;
  final ScrollController scroll;
  final VoidCallback onShown;

  @override
  Widget build(BuildContext context) {
    onShown();
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _Bubble(message: message, isMine: message.isFrom(myId)),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The accent belongs to what the reader said; the other side stays on
    // the calm surface colour so a long conversation does not shout.
    final background = isMine
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;
    final foreground = isMine
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.message,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatShortTime(message.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.input,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController input;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: input,
              builder: (context, value, _) => TextField(
                controller: input,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  filled: true,
                  hintText: l10n.chatMessageHint,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: input,
            builder: (context, value, _) {
              final canSend = value.text.trim().isNotEmpty && !isSending;
              return IconButton.filled(
                onPressed: canSend ? onSend : null,
                tooltip: l10n.chatSend,
                icon: isSending
                    ? const SizedBox.square(
                        dimension: AppIconSize.sm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
