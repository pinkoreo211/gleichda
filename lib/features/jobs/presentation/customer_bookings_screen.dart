import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_date_format.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/features/jobs/application/my_jobs.dart';
import 'package:app/features/jobs/presentation/widgets/jobs_section.dart';
import 'package:app/features/requests/application/my_requests.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/service_request.dart';
import 'package:app/features/requests/presentation/widgets/request_photo_strip.dart';
import 'package:app/features/requests/presentation/widgets/request_timing_display.dart';
import 'package:app/features/catalog/presentation/widgets/category_icon.dart';
import 'package:app/l10n/app_localizations.dart';

/// The customer's requests and, later, their booked jobs.
///
/// Each request says how many providers it has reached — saving one does
/// not send it, the customer picks who gets it. Bookings stay empty until
/// booking exists; none are invented.
class CustomerBookingsScreen extends ConsumerWidget {
  const CustomerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requests = ref.watch(myRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabBookings)),
      // Pull to refresh: a provider may answer while this screen is open,
      // and nothing else would tell it.
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myRequestsProvider);
          ref.invalidate(myJobsProvider);
          await ref.read(myRequestsProvider.future);
          await ref.read(myJobsProvider.future);
        },
        child: requests.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // A failed read is not worth its own error screen here.
          error: (_, _) => _emptyState(l10n),
          data: (list) =>
              list.isEmpty ? _emptyState(l10n) : _RequestList(requests: list),
        ),
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
      // So a short list can still be pulled down to refresh.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Agreed work first: a running job matters more than a request
        // still waiting for somebody to say yes.
        const JobsSection(),
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

/// How the bookings list describes a saved request.
///
/// Requests shown here are the customer's own, read back from the backend.
/// Bookings stay empty until booking exists — none are invented.

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
            // Their own request, so their own pictures — from the moment
            // it is sent, not only once somebody accepts. Anyone who
            // attached a photo should be able to check what they sent.
            RequestPhotoStrip(requestId: request.id),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (category != null)
                  _Detail(
                    icon: iconForCategory(category.iconKey),
                    text: category.nameFor(
                      Localizations.localeOf(context).languageCode,
                    ),
                  ),
                if (request.city != null && request.city!.isNotEmpty)
                  _Detail(icon: Icons.place_outlined, text: request.city!),
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
            _Status(request: request),
            // Only requests that name a service can be matched; offering
            // the button on the others would lead to an empty screen.
            if (request.canBeMatched) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  AppRoutes.customerBookingProviders(request.id),
                ),
                icon: const Icon(Icons.person_search_outlined),
                label: Text(l10n.customerRequestsShowProviders),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Where a request stands, in one line.
///
/// An acceptance is the news worth reading, so it wins over everything
/// else. Otherwise the line reports what is actually true — waiting, turned
/// down, or not sent at all — rather than the most hopeful reading of it.
class _Status extends StatelessWidget {
  const _Status({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Every provider who said yes, wherever their job has got to since —
    // "in Arbeit" still means they accepted.
    final accepted = request.contactStatuses
        .where((status) => status.isJob)
        .length;
    final open = request.countOf(RequestContactStatus.sent);
    final declined = request.countOf(RequestContactStatus.declined);

    final (text, isGoodNews) = switch ((accepted, open, declined)) {
      (> 0, _, _) => (l10n.customerRequestsAcceptedCount(accepted), true),
      (_, > 0, _) => (l10n.customerRequestsSentCount(open), true),
      (_, _, > 0) => (l10n.customerRequestsDeclinedCount(declined), false),
      _ => (l10n.customerRequestsSentCount(0), false),
    };

    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: isGoodNews
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
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
