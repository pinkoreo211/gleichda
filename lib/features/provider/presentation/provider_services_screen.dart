import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_money_format.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/presentation/widgets/catalog_async.dart';
import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/provider/domain/provider_service_offering.dart';
import 'package:app/l10n/app_localizations.dart';

/// What the provider offers, and what they charge for it.
///
/// Each row shows their own cheapest price — not the catalog's example — or
/// says plainly that no price is set yet.
class ProviderServicesScreen extends ConsumerWidget {
  const ProviderServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final offerings = ref.watch(myOfferingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.providerHomeMyServices)),
      body: SafeArea(
        child: CatalogAsync<List<ProviderServiceOffering>>(
          value: offerings,
          onRetry: () => ref.invalidate(myOfferingsProvider),
          builder: (list) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (list.isEmpty)
                EmptyState(
                  icon: Icons.handyman_outlined,
                  title: l10n.providerHomeMyServices,
                  message: l10n.providerServicesEmpty,
                )
              else
                for (final offering in list) ...[
                  _OfferingCard(offering: offering),
                  const SizedBox(height: AppSpacing.sm),
                ],
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.providerServicesAdd),
                icon: const Icon(Icons.add),
                label: Text(l10n.providerAddService),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferingCard extends StatelessWidget {
  const _OfferingCard({required this.offering});

  final ProviderServiceOffering offering;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final lowest = offering.lowestPriceCents;

    // A quoted service needs no price; a fixed-price one without a price is
    // worth pointing out rather than showing a blank.
    final priceLine = switch (lowest) {
      final int cents => l10n.servicePriceFrom(formatCents(cents)),
      _ when offering.service.serviceType == ServiceType.quote =>
        l10n.serviceQuoteBadge,
      _ => l10n.providerNoPriceYet,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offering.service.nameFor(language),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    priceLine,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: offering.needsPrice
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.push(AppRoutes.providerServicePrices(offering.id)),
              child: Text(l10n.providerEdit),
            ),
          ],
        ),
      ),
    );
  }
}
