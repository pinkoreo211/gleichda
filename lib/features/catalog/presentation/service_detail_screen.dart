import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_money_format.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/features/catalog/application/catalog_providers.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/domain/service_price_option.dart';
import 'package:app/features/catalog/presentation/widgets/catalog_async.dart';
import 'package:app/features/requests/application/service_request_draft_controller.dart';
import 'package:app/l10n/app_localizations.dart';

/// One service in full: what it covers and what the options cost.
///
/// "Weiter" does not book anything yet — booking comes later. It carries the
/// chosen service into the existing request flow, which is where the
/// customer already describes what they need.
class ServiceDetailScreen extends ConsumerStatefulWidget {
  const ServiceDetailScreen({
    super.key,
    required this.categorySlug,
    required this.serviceId,
  });

  final String categorySlug;
  final String serviceId;

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  ServicePriceOption? _selected;

  void _continueToRequest(Service service) {
    final language = Localizations.localeOf(context).languageCode;
    final option = _selected;
    // A starting point the customer can freely edit — the request screen
    // never locks them into the catalog's wording.
    final description = option == null
        ? service.nameFor(language)
        : '${service.nameFor(language)} – ${option.nameFor(language)}';

    ref
        .read(serviceRequestDraftProvider.notifier)
        .start(
          description: description,
          category: ref.read(categoryBySlugProvider(widget.categorySlug)),
          // The customer picked this service, so the request knows it from
          // the start -- no guessing needed later.
          service: service,
        );
    context.push(AppRoutes.customerRequest);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final service = ref.watch(serviceByIdProvider(widget.serviceId));

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: CatalogAsync<Service?>(
          value: service,
          onRetry: () => ref.invalidate(serviceByIdProvider(widget.serviceId)),
          builder: (value) {
            if (value == null) {
              return EmptyState(
                icon: Icons.search_off,
                title: l10n.serviceNotFound,
                message: l10n.catalogEmptyMessage,
              );
            }
            return _Details(
              service: value,
              language: language,
              selected: _selected,
              onSelect: (option) => setState(() => _selected = option),
              onContinue: () => _continueToRequest(value),
              onShowProviders: () =>
                  context.push(AppRoutes.customerProviders(value.id)),
            );
          },
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.service,
    required this.language,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
    required this.onShowProviders,
  });

  final Service service;
  final String language;
  final ServicePriceOption? selected;
  final ValueChanged<ServicePriceOption> onSelect;
  final VoidCallback onContinue;
  final VoidCallback onShowProviders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final description = service.descriptionFor(language);
    final options = service.hasPrices
        ? service.priceOptions
        : const <ServicePriceOption>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                Text(
                  service.nameFor(language),
                  style: theme.textTheme.headlineSmall,
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (options.isEmpty)
                  Text(
                    l10n.serviceQuoteHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else ...[
                  Text(
                    l10n.servicePriceOptionsTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final option in options) ...[
                    _PriceOptionTile(
                      option: option,
                      language: language,
                      isSelected: option.id == selected?.id,
                      onTap: () => onSelect(option),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.servicePricesExampleHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onShowProviders,
            icon: const Icon(Icons.person_search_outlined),
            label: Text(l10n.providerMatchesShow),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: onContinue,
            child: Text(l10n.serviceContinue),
          ),
        ],
      ),
    );
  }
}

class _PriceOptionTile extends StatelessWidget {
  const _PriceOptionTile({
    required this.option,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final ServicePriceOption option;
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final duration = option.durationMinutes;
    final subtitle = [
      if (option.unit != null && option.unit!.isNotEmpty) option.unit!,
      if (duration != null) l10n.serviceDurationMinutes(duration),
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.nameFor(language),
                      style: theme.textTheme.titleSmall,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatCents(option.priceCents, currency: option.currency),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
