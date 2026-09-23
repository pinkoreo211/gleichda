import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/features/catalog/presentation/widgets/catalog_async.dart';
import 'package:app/features/chat/presentation/chat_screen.dart';
import 'package:app/features/matching/application/provider_matches.dart';
import 'package:app/features/matching/data/matching_repository.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/matching/presentation/widgets/provider_match_card.dart';
import 'package:app/features/requests/application/my_requests.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/service_request.dart';
import 'package:app/features/requests/presentation/widgets/request_status_display.dart';
import 'package:app/l10n/app_localizations.dart';

/// The providers who can do one saved request — and the place the customer
/// hands the request over.
///
/// Only the request's id travels to the backend. Which service it is about,
/// which city it is in and whether it belongs to this customer are all read
/// from the stored request on the server, so the list is the database's
/// answer rather than the app's.
class RequestMatchesScreen extends ConsumerStatefulWidget {
  const RequestMatchesScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<RequestMatchesScreen> createState() =>
      _RequestMatchesScreenState();
}

class _RequestMatchesScreenState extends ConsumerState<RequestMatchesScreen> {
  /// The provider currently being contacted, so only that one button shows
  /// a spinner instead of the whole list freezing.
  String? _sendingTo;

  Future<void> _send(ProviderMatch match) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sendingTo = match.providerId);
    try {
      await ref
          .read(matchingRepositoryProvider)
          .sendRequestToProvider(
            requestId: widget.requestId,
            providerId: match.providerId,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.requestSentToProvider(
              match.displayName ?? l10n.providerUnnamed,
            ),
          ),
        ),
      );
      // Re-read rather than patch the list in place: the server is the one
      // that knows the request reached them.
      ref.invalidate(requestMatchesProvider(widget.requestId));
      ref.invalidate(myRequestsProvider);
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    }
    if (mounted) setState(() => _sendingTo = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final request = ref.watch(requestByIdProvider(widget.requestId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestMatchesTitle)),
      body: SafeArea(
        child: CatalogAsync<ServiceRequest?>(
          value: request,
          onRetry: () => ref.invalidate(myRequestsProvider),
          builder: (value) {
            // A free-text request names no service yet, so there is nothing
            // to match against. Say that instead of showing an empty list
            // that looks like "nobody wants your job".
            if (value == null || !value.canBeMatched) {
              return EmptyState(
                icon: Icons.help_outline,
                title: l10n.requestMatchesNoServiceTitle,
                message: l10n.requestMatchesNoServiceMessage,
              );
            }
            return _Matches(
              requestId: widget.requestId,
              serviceName: value.service?.nameFor(
                Localizations.localeOf(context).languageCode,
              ),
              sendingTo: _sendingTo,
              onSend: _send,
            );
          },
        ),
      ),
    );
  }
}

class _Matches extends ConsumerWidget {
  const _Matches({
    required this.requestId,
    required this.serviceName,
    required this.sendingTo,
    required this.onSend,
  });

  final String requestId;
  final String? serviceName;
  final String? sendingTo;
  final ValueChanged<ProviderMatch> onSend;

  /// The chat is a child of this screen's own route, so it opens inside
  /// whichever tab the customer came from and "back" returns here.
  void _openChat(BuildContext context, ProviderMatch match) {
    final l10n = AppLocalizations.of(context);
    context.push(
      AppRoutes.chatUnder(
        GoRouterState.of(context).matchedLocation,
        match.providerId,
      ),
      extra: ChatArgs(
        otherName: match.displayName ?? l10n.providerUnnamed,
        serviceName: serviceName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final matches = ref.watch(requestMatchesProvider(requestId));

    return CatalogAsync<List<ProviderMatch>>(
      value: matches,
      onRetry: () => ref.invalidate(requestMatchesProvider(requestId)),
      builder: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.person_search_outlined,
            title: l10n.providerMatchesEmptyTitle,
            message: l10n.providerMatchesEmptyMessage,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            for (final match in list) ...[
              ProviderMatchCard(
                match: match,
                action: _Action(
                  match: match,
                  isSending: sendingTo == match.providerId,
                  // One at a time: a second tap while a request is on its
                  // way would only confuse.
                  onSend: sendingTo == null ? () => onSend(match) : null,
                  onChat: () => _openChat(context, match),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.match,
    required this.isSending,
    required this.onSend,
    required this.onChat,
  });

  final ProviderMatch match;
  final bool isSending;
  final VoidCallback? onSend;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Already contacted: what the provider answered, not a button that
    // would send the same request twice.
    if (match.contactStatus case final status?) {
      final theme = Theme.of(context);
      final color = status.color(theme.colorScheme);
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(status.icon, size: AppIconSize.sm, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                // "Anfrage gesendet" says more than "Noch offen" while
                // nothing has come back; once it has, the answer is the news.
                status.isOpen ? l10n.providerMatchSent : status.label(l10n),
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
          // Only a provider who said yes has agreed to be talked to.
          if (status == RequestContactStatus.accepted) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(l10n.chatWithProvider),
              ),
            ),
          ],
        ],
      );
    }
    return FilledButton(
      onPressed: isSending ? null : onSend,
      child: isSending ? const ButtonProgress() : Text(l10n.providerMatchSend),
    );
  }
}
