import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_money_format.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/l10n/app_localizations.dart';

/// One service in a category list: what it is, and what it roughly costs.
class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, required this.onTap});

  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final short = service.shortDescriptionFor(language);
    final lowest = service.hasPrices ? service.lowestPriceCents : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.nameFor(language),
                      style: theme.textTheme.titleSmall,
                    ),
                    if (short != null && short.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        short,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      // A quoted service has no price to show, and inventing
                      // one would be worse than saying so.
                      lowest == null
                          ? l10n.serviceQuoteBadge
                          : l10n.servicePriceFrom(formatCents(lowest)),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
