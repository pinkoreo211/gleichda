import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_date_format.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/features/requests/application/my_requests.dart';
import 'package:app/features/requests/domain/service_request.dart';
import 'package:app/features/requests/presentation/widgets/request_timing_display.dart';
import 'package:app/features/requests/presentation/widgets/service_category_display.dart';
import 'package:app/l10n/app_localizations.dart';

/// The customer's requests and, later, their booked jobs.
///
/// Requests shown here are real ones the customer created; they are stored
/// on this device only and marked as not sent, because there is no backend
/// table for them yet. Bookings stay empty until booking exists — none are
/// invented.
class CustomerBookingsScreen extends ConsumerWidget {
  const CustomerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requests = ref.watch(myRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabBookings)),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Reading local storage failing is not worth its own error screen.
        error: (_, _) => _emptyState(l10n),
        data: (list) =>
            list.isEmpty ? _emptyState(l10n) : _RequestList(requests: list),
      ),
    );
  }

  Widget _emptyState(AppLocalizations l10n) => EmptyState(
    icon: Icons.event_note_outlined,
    title: l10n.customerBookingsEmptyTitle,
    message: l10n.customerBookingsEmptyMessage,
  );
}

class _RequestList extends StatelessWidget {
  const _RequestList({required this.requests});

  final List<ServiceRequest> requests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(l10n.customerRequestsTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        for (final request in requests) ...[
          _RequestCard(request: request),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.requestNotSentYet,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final category = request.category;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.originalDescription,
              style: theme.textTheme.bodyLarge,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (category != null)
                  _Detail(icon: category.icon, text: category.label(l10n)),
                _Detail(
                  icon: Icons.schedule,
                  text: request.timing.label(l10n, date: request.preferredDate),
                ),
                _Detail(
                  icon: Icons.edit_calendar_outlined,
                  text: formatShortDate(request.createdAt),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.customerRequestsNotSent,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
