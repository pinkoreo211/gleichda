import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_date_format.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/jobs/application/incoming_requests.dart';
import 'package:app/features/jobs/domain/incoming_request.dart';
import 'package:app/features/requests/presentation/widgets/request_timing_display.dart';
import 'package:app/l10n/app_localizations.dart';

/// The requests customers sent to this provider.
///
/// Read through one backend function that only ever returns the requests
/// handed to the caller's own profile — a provider cannot see requests that
/// went to someone else, or requests nobody sent them.
///
/// Answering a request does not exist yet, and the list says so rather than
/// showing buttons that would do nothing.
class IncomingRequestList extends ConsumerWidget {
  const IncomingRequestList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
            _IncomingRequestCard(request: request),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            l10n.providerIncomingNoReplyYet,
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
  const _IncomingRequestCard({required this.request});

  final IncomingRequest request;

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
          ],
        ),
      ),
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
