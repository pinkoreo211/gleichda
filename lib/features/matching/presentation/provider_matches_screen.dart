import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_money_format.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/features/catalog/presentation/widgets/catalog_async.dart';
import 'package:app/features/matching/application/provider_matches.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/provider/presentation/widgets/verification_badge.dart';
import 'package:app/l10n/app_localizations.dart';

/// The providers who offer one service, verified first and then cheapest.
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
                  _MatchCard(match: match),
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

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final ProviderMatch match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final price = match.lowestPriceCents;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.displayName ?? l10n.providerUnnamed,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                // Only ever what the server stored.
                if (match.verificationStatus.isVerified) ...[
                  Icon(
                    match.verificationStatus.icon,
                    size: AppIconSize.sm,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    match.verificationStatus.label(l10n),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            if (match.city != null && match.city!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                match.city!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (match.description != null && match.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                match.description!,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              price == null
                  ? l10n.providerNoPriceGiven
                  : l10n.servicePriceFrom(
                      formatCents(price, currency: match.currency),
                    ),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
