import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/design_system/widgets/error_state.dart';
import 'package:app/features/booking/application/booking_controller.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/matching/presentation/widgets/provider_match_card.dart';
import 'package:app/l10n/app_localizations.dart';

/// Step three: who can do it.
///
/// Everyone in this list is verified and has priced this service. That is
/// stricter than the older "matching providers" list, which also shows
/// unverified providers and says so — there the customer asks, here they
/// book, and booking at a listed price is something only a checked
/// provider is offered for.
///
/// When nobody qualifies the screen says exactly that. It never falls back
/// to showing unverified providers as though they were the same thing.
class BookingProvidersScreen extends ConsumerWidget {
  const BookingProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final providers = ref.watch(bookableProvidersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingProvidersTitle)),
      body: switch (providers) {
        // Nobody qualifies. The screen says so and offers the other way
        // in, rather than quietly widening the rules to fill the list.
        AsyncData(:final value) when value.isEmpty => Column(
          children: [
            Expanded(
              child: EmptyState(
                icon: Icons.person_search_outlined,
                title: l10n.bookingNoProvidersTitle,
                message: l10n.bookingNoProviders,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.customerRequest),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.bookingWriteRequestInstead),
                ),
              ),
            ),
          ],
        ),
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(bookableProvidersProvider);
            await ref.read(bookableProvidersProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: value.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => _BookableCard(match: value[index]),
          ),
        ),
        AsyncError() => ErrorState(
          message: l10n.bookingProvidersFailed,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(bookableProvidersProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _BookableCard extends StatelessWidget {
  const _BookableCard({required this.match});

  final ProviderMatch match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // The same card as everywhere else, so a provider looks the same
    // wherever a customer meets them.
    return ProviderMatchCard(
      match: match,
      action: OutlinedButton.icon(
        onPressed: () =>
            context.push(AppRoutes.bookingProvider(match.providerId)),
        icon: const Icon(Icons.person_outline),
        label: Text(l10n.bookingViewProfile),
      ),
    );
  }
}
