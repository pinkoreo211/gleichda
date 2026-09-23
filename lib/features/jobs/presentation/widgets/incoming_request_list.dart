import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/core/formatting/app_date_format.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/features/jobs/application/incoming_requests.dart';
import 'package:app/features/jobs/data/incoming_requests_repository.dart';
import 'package:app/features/chat/presentation/chat_screen.dart';
import 'package:app/features/jobs/domain/incoming_request.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/presentation/widgets/request_status_display.dart';
import 'package:app/features/requests/presentation/widgets/request_timing_display.dart';
import 'package:app/l10n/app_localizations.dart';

/// The requests customers sent to this provider, and the answer to them.
///
/// Read through one backend function that only ever returns the requests
/// handed to the caller's own profile — a provider cannot see requests that
/// went to someone else, or requests nobody sent them.
///
/// Accepting or declining goes through a second function that answers once
/// and only for the right provider, so the decision cannot be taken twice
/// or taken by anyone else.
class IncomingRequestList extends ConsumerStatefulWidget {
  const IncomingRequestList({super.key});

  @override
  ConsumerState<IncomingRequestList> createState() =>
      _IncomingRequestListState();
}

class _IncomingRequestListState extends ConsumerState<IncomingRequestList> {
  /// The request currently being answered, so only its own buttons wait.
  String? _answering;

  Future<void> _respond(
    IncomingRequest request,
    RequestContactStatus status,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _answering = request.contactId);
    try {
      await ref
          .read(incomingRequestsRepositoryProvider)
          .respond(contactId: request.contactId, status: status);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == RequestContactStatus.accepted
                ? l10n.providerIncomingAcceptedToast
                : l10n.providerIncomingDeclinedToast,
          ),
        ),
      );
      // Re-read: the answer that counts is the one the server stored.
      ref.invalidate(myIncomingRequestsProvider);
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    }
    if (mounted) setState(() => _answering = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final requests = ref.watch(myIncomingRequestsProvider);

    final list = switch (requests) {
      AsyncData(:final value) => value,
      // A failed read is not worth its own error screen on the home page;
      // the list simply stays empty until the next refresh.
      _ => const <IncomingRequest>[],
    };

    return Column(
      // Stretch, not start: a card that shrinks to its text would sit
      // narrower than everything else on the screen.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.providerIncomingTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (list.isNotEmpty)
              Text(
                l10n.providerIncomingCount(list.length),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (requests.isLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (list.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.providerIncomingEmpty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          for (final request in list) ...[
            _IncomingRequestCard(
              request: request,
              isAnswering: _answering == request.contactId,
              // One at a time: a second decision while the first is on its
              // way would only confuse.
              onRespond: _answering == null
                  ? (status) => _respond(request, status)
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            l10n.providerIncomingChatHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({
    required this.request,
    required this.isAnswering,
    required this.onRespond,
  });

  final IncomingRequest request;
  final bool isAnswering;

  /// Null while another request is being answered.
  final ValueChanged<RequestContactStatus>? onRespond;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final serviceName = request.nameFor(language);
    final place = request.place;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (serviceName != null && serviceName.isNotEmpty) ...[
              Text(serviceName, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              l10n.providerIncomingFrom(
                request.customerName ?? l10n.providerIncomingCustomerUnknown,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Not truncated: a provider decides on the whole text, not on
            // the first two lines of it.
            Text(request.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (place != null)
                  _Detail(icon: Icons.place_outlined, text: place),
                _Detail(
                  icon: Icons.schedule,
                  text: request.timing.label(l10n, date: request.preferredDate),
                ),
                _Detail(
                  icon: Icons.mark_email_unread_outlined,
                  text: formatShortDate(request.sentAt),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (request.status.isOpen)
              _Decision(isAnswering: isAnswering, onRespond: onRespond)
            else ...[
              // Answered: what was decided, and no way to decide again.
              // The backend refuses a second answer either way.
              _Answered(status: request.status),
              // Only an accepted job has two people who agreed to talk.
              if (request.status == RequestContactStatus.accepted) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.providerChat(request.requestId),
                      extra: ChatArgs(
                        otherName:
                            request.customerName ??
                            l10n.providerIncomingCustomerUnknown,
                        serviceName: serviceName,
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(l10n.chatWithCustomer),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Accept or decline, side by side and equally weighted: neither answer is
/// the one the app would rather have.
class _Decision extends StatelessWidget {
  const _Decision({required this.isAnswering, required this.onRespond});

  final bool isAnswering;
  final ValueChanged<RequestContactStatus>? onRespond;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isAnswering
                ? null
                : () => onRespond?.call(RequestContactStatus.declined),
            child: Text(l10n.providerIncomingDecline),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton(
            onPressed: isAnswering
                ? null
                : () => onRespond?.call(RequestContactStatus.accepted),
            child: isAnswering
                ? const ButtonProgress()
                : Text(l10n.providerIncomingAccept),
          ),
        ),
      ],
    );
  }
}

class _Answered extends StatelessWidget {
  const _Answered({required this.status});

  final RequestContactStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = status.color(theme.colorScheme);

    return Row(
      children: [
        Icon(status.icon, size: AppIconSize.sm, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          status == RequestContactStatus.accepted
              ? l10n.providerIncomingAccepted
              : l10n.providerIncomingDeclined,
          style: theme.textTheme.labelLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
