import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/core/formatting/app_money_format.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/presentation/widgets/catalog_async.dart';
import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/provider/data/provider_repository.dart';
import 'package:app/features/provider/domain/provider_service_offering.dart';
import 'package:app/l10n/app_localizations.dart';

/// The provider's own prices for one service.
///
/// Prices belong to the provider's offering, never to the catalog entry —
/// nothing here can change what the service itself is or what the catalog
/// suggests it costs.
class ProviderServicePricesScreen extends ConsumerWidget {
  const ProviderServicePricesScreen({super.key, required this.offeringId});

  final String offeringId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final offerings = ref.watch(myOfferingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.providerPricingTitle)),
      body: SafeArea(
        child: CatalogAsync<List<ProviderServiceOffering>>(
          value: offerings,
          onRetry: () => ref.invalidate(myOfferingsProvider),
          builder: (list) {
            final offering = list
                .where((item) => item.id == offeringId)
                .firstOrNull;
            if (offering == null) {
              return Center(child: Text(l10n.serviceNotFound));
            }
            return _Prices(offering: offering, language: language);
          },
        ),
      ),
    );
  }
}

class _Prices extends ConsumerWidget {
  const _Prices({required this.offering, required this.language});

  final ProviderServiceOffering offering;
  final String language;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      ref.invalidate(myOfferingsProvider);
    } catch (error) {
      if (context.mounted) showFailureSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repository = ref.read(providerRepositoryProvider);
    final isQuote = offering.service.serviceType == ServiceType.quote;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          offering.service.nameFor(language),
          style: theme.textTheme.headlineSmall,
        ),
        // A quoted service is fine without a fixed price, and saying so stops
        // providers hunting for a field they do not need. The "no price yet"
        // line only belongs there while that is actually true.
        if (isQuote || offering.prices.isEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            isQuote
                ? l10n.providerQuoteNoPriceNeeded
                : l10n.providerPricesEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        for (final price in offering.prices) ...[
          _PriceCard(
            price: price,
            onToggle: () => _run(
              context,
              ref,
              () => repository.updatePrice(price.id, {
                'is_active': !price.isActive,
              }),
            ),
            onDelete: () =>
                _run(context, ref, () => repository.deletePrice(price.id)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => _openEditor(context, ref),
          icon: const Icon(Icons.add),
          label: Text(l10n.providerAddPrice),
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_PriceDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _PriceEditor(),
    );
    if (result == null || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref
          .read(providerRepositoryProvider)
          .addPrice(
            offering.id,
            name: result.name,
            priceCents: result.priceCents,
            unit: result.unit,
            durationMinutes: result.durationMinutes,
          ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.price,
    required this.onToggle,
    required this.onDelete,
  });

  final ProviderServicePrice price;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final details = [
      if (price.unit != null && price.unit!.isNotEmpty) price.unit!,
      if (price.durationMinutes != null)
        l10n.serviceDurationMinutes(price.durationMinutes!),
      if (!price.isActive) l10n.providerPriceInactive,
    ].join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(price.name, style: theme.textTheme.titleSmall),
                ),
                Text(
                  formatCents(price.priceCents, currency: price.currency),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: price.isActive
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                details,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton(
                  onPressed: onToggle,
                  child: Text(
                    price.isActive
                        ? l10n.providerPriceDeactivate
                        : l10n.providerPriceActivate,
                  ),
                ),
                TextButton(
                  onPressed: onDelete,
                  child: Text(l10n.providerPriceDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// What the editor hands back.
class _PriceDraft {
  const _PriceDraft({
    required this.name,
    required this.priceCents,
    this.unit,
    this.durationMinutes,
  });

  final String name;
  final int priceCents;
  final String? unit;
  final int? durationMinutes;
}

/// Four fields, one button. Deliberately not a form builder.
class _PriceEditor extends StatefulWidget {
  const _PriceEditor();

  @override
  State<_PriceEditor> createState() => _PriceEditorState();
}

class _PriceEditorState extends State<_PriceEditor> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _unit = TextEditingController();
  final _duration = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _amount, _unit, _duration]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Accepts "49,99" and "49.99": people type the separator their keyboard
  /// offers, and money is stored as whole cents either way.
  int? _parseCents(String input) {
    final normalised = input.trim().replaceAll(',', '.');
    final euros = double.tryParse(normalised);
    if (euros == null || euros < 0) return null;
    return (euros * 100).round();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = l10n.errorPriceNameRequired);
      return;
    }
    final cents = _parseCents(_amount.text);
    if (cents == null) {
      setState(() => _error = l10n.errorPriceInvalid);
      return;
    }
    Navigator.of(context).pop(
      _PriceDraft(
        name: _name.text,
        priceCents: cents,
        unit: _unit.text,
        durationMinutes: int.tryParse(_duration.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.providerAddPrice, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.providerPriceNameLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.providerPriceAmountLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _unit,
            decoration: InputDecoration(labelText: l10n.providerPriceUnitLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _duration,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.providerPriceDurationLabel,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: _submit, child: Text(l10n.providerPriceSave)),
        ],
      ),
    );
  }
}
