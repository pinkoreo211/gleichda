import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/features/catalog/presentation/widgets/catalog_async.dart';
import 'package:app/features/matching/application/provider_matches.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/matching/presentation/widgets/provider_match_card.dart';
import 'package:app/l10n/app_localizations.dart';

/// The providers who offer one service, verified first and then cheapest.
///
/// Reached by browsing the catalog, where there is no request yet — so the
/// cards only show who is there. Sending happens on the list that belongs
/// to a saved request.
class ProviderMatchesScreen extends ConsumerWidget {
  const ProviderMatchesScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final matches = ref.watch(providerMatchesProvider(serviceId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.providerMatchesTitle)),
      body: SafeArea(
        child: CatalogAsync<List<ProviderMatch>>(
          value: matches,
          onRetry: () => ref.invalidate(providerMatchesProvider(serviceId)),
          builder: (list) {
            if (list.isEmpty) {
              // At this stage an empty list is the normal case, not a bug.
              // Saying so beats an empty screen that looks broken.
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
                  ProviderMatchCard(match: match),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
