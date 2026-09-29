import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_money_format.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/avatar.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/provider/presentation/widgets/verification_badge.dart';
import 'package:app/l10n/app_localizations.dart';

/// One provider, as a customer may see them.
///
/// Everything on this card comes from the backend's matching function:
/// name, city, description, price and the verification status. Nothing is
/// derived in the app, so nothing can claim more than the server stored.
///
/// [action] is the button underneath — sending the request from a saved
/// request's list. Browsing the catalog passes none, because there is no
/// request to send yet.
class ProviderMatchCard extends StatelessWidget {
  const ProviderMatchCard({super.key, required this.match, this.action});

  final ProviderMatch match;
  final Widget? action;

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
                Avatar(imageUrl: match.avatarUrl, name: match.displayName),
                const SizedBox(width: AppSpacing.sm),
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
            // Only what customers actually said. A provider nobody has
            // rated gets no line at all — not a default score, and not a
            // zero that reads like a bad one.
            if (match.hasRating) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: AppIconSize.sm,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    formatRating(match.ratingAverage!),
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.reviewCount(match.ratingCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity, child: action),
            ],
          ],
        ),
      ),
    );
  }
}
