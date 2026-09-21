import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/features/catalog/application/catalog_providers.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/domain/service_category.dart';
import 'package:app/features/catalog/presentation/widgets/catalog_async.dart';
import 'package:app/features/catalog/presentation/widgets/category_icon.dart';
import 'package:app/l10n/app_localizations.dart';

/// Lets a provider tick the services they offer, grouped by category.
///
/// The list is the central catalog, loaded from the backend — a provider
/// picks from it and can never add to or change it.
class ProviderServicePicker extends ConsumerWidget {
  const ProviderServicePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Catalog service ids.
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  void _toggle(String serviceId, bool isSelected) {
    final next = {...selected};
    if (isSelected) {
      next.add(serviceId);
    } else {
      next.remove(serviceId);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final categories = ref.watch(serviceCategoriesProvider);
    final services = ref.watch(allServicesProvider);

    return CatalogAsync<List<ServiceCategory>>(
      value: categories,
      onRetry: () => ref.invalidate(serviceCategoriesProvider),
      builder: (categoryList) => CatalogAsync<List<Service>>(
        value: services,
        onRetry: () => ref.invalidate(allServicesProvider),
        builder: (serviceList) {
          if (serviceList.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: l10n.catalogEmptyTitle,
              message: l10n.catalogEmptyMessage,
            );
          }
          return ListView(
            children: [
              for (final category in categoryList)
                _CategorySection(
                  category: category,
                  language: language,
                  services: [
                    for (final service in serviceList)
                      if (service.categoryId == category.id) service,
                  ],
                  selected: selected,
                  onToggle: _toggle,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.language,
    required this.services,
    required this.selected,
    required this.onToggle,
  });

  final ServiceCategory category;
  final String language;
  final List<Service> services;
  final Set<String> selected;
  final void Function(String serviceId, bool isSelected) onToggle;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                iconForCategory(category.iconKey),
                size: AppIconSize.sm,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                category.nameFor(language),
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
        for (final service in services)
          CheckboxListTile(
            value: selected.contains(service.id),
            onChanged: (isSelected) =>
                onToggle(service.id, isSelected ?? false),
            title: Text(service.nameFor(language)),
            subtitle: switch (service.shortDescriptionFor(language)) {
              final String text when text.isNotEmpty => Text(text),
              _ => null,
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ],
    );
  }
}
