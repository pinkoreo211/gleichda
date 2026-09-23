import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_date_format.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/features/chat/application/chat_providers.dart';
import 'package:app/features/chat/domain/conversation_summary.dart';
import 'package:app/features/chat/presentation/chat_screen.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/domain/app_role.dart';
import 'package:app/l10n/app_localizations.dart';

/// Every conversation this person is part of, shared by customers and
/// providers.
///
/// One backend call fills it: the other person's name, the job it is about
/// and the last message all arrive together, so a provider with a hundred
/// jobs costs no more than one with two. The list only ever holds the
/// caller's own conversations — that is decided in the database, not here.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final conversations = ref.watch(myConversationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMessages)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myConversationsProvider);
          await ref.read(myConversationsProvider.future);
        },
        child: switch (conversations) {
          AsyncData(:final value) when value.isEmpty => const _Empty(),
          AsyncData(:final value) => _List(conversations: value),
          AsyncError() => _Error(
            onRetry: () => ref.invalidate(myConversationsProvider),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// Only shown when the backend really returned nothing — a failed read has
/// its own message, so "no chats" never stands in for "we could not ask".
class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isProvider = ref.watch(activeRoleProvider) == AppRole.provider;

    return EmptyState(
      icon: Icons.chat_bubble_outline,
      title: l10n.conversationsEmptyTitle,
      message: isProvider
          ? l10n.conversationsEmptyProvider
          : l10n.conversationsEmptyCustomer,
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: AppIconSize.xl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.conversationsLoadFailed, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.catalogRetry)),
          ],
        ),
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.conversations});

  final List<ConversationSummary> conversations;

  /// Opens the conversation that is already there. The provider is named,
  /// so the backend lands on this exact one rather than working one out —
  /// and nothing new is created.
  void _open(BuildContext context, WidgetRef ref, ConversationSummary item) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final isProvider = ref.read(activeRoleProvider) == AppRole.provider;
    final path = isProvider
        ? AppRoutes.providerMessagesChat(item.requestId, item.providerId)
        : AppRoutes.customerMessagesChat(item.requestId, item.providerId);

    context.push(
      path,
      extra: ChatArgs(
        otherName: item.otherName ?? _fallbackName(l10n, item),
        serviceName: item.serviceFor(language),
      ),
    );
  }

  static String _fallbackName(
    AppLocalizations l10n,
    ConversationSummary item,
  ) => item.viewerIsCustomer
      ? l10n.providerUnnamed
      : l10n.providerIncomingCustomerUnknown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = Localizations.localeOf(context).languageCode;

    return ListView.separated(
      // So a short list can still be pulled down to refresh.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: conversations.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = conversations[index];
        return _ConversationCard(
          item: item,
          language: language,
          name:
              item.otherName ??
              _fallbackName(AppLocalizations.of(context), item),
          onTap: () => _open(context, ref, item),
        );
      },
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.item,
    required this.language,
    required this.name,
    required this.onTap,
  });

  final ConversationSummary item;
  final String language;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final service = item.serviceFor(language);
    final message = item.lastMessage;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(imageUrl: item.otherImageUrl, name: name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          formatMessageStamp(item.sortedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (service != null && service.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        service,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message ?? l10n.chatEmptyTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        // An empty conversation reads as a note, not as
                        // something somebody said.
                        color: message == null
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                        fontStyle: message == null ? FontStyle.italic : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The provider's picture when there is one. Uploading does not exist yet,
/// so in practice this is the initial — which is why it is drawn properly
/// rather than left as a grey blank.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;

    return CircleAvatar(
      radius: AppIconSize.md,
      backgroundColor: theme.colorScheme.secondaryContainer,
      foregroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      child: Text(
        initial.toUpperCase(),
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
