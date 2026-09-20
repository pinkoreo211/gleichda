import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/features/catalog/application/catalog_providers.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/presentation/widgets/catalog_async.dart';
import 'package:app/features/catalog/presentation/widgets/category_icon.dart';
import 'package:app/features/catalog/presentation/widgets/service_card.dart';
import 'package:app/l10n/app_localizations.dart';

/// The services of one category, e.g. everything under "Reinigung".
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.slug});

  /// From the route, so the screen survives a deep link.
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final category = ref.watch(categoryBySlugProvider(slug));

    // Until the categories are loaded there is no id to fetch services for,
    // so this screen follows the categories request first.
    if (category == null) {
      return Scaffold(
        appBar: AppBar(),
        body: CatalogAsync(
          value: ref.watch(serviceCategoriesProvider),
          onRetry: () => ref.invalidate(serviceCategoriesProvider),
          // Loaded, but the slug matched nothing: the category is gone.
          builder: (_) => EmptyState(
            icon: Icons.search_off,
            title: l10n.catalogEmptyTitle,
            message: l10n.catalogEmptyMessage,
          ),
        ),
      );
    }

    final services = ref.watch(servicesInCategoryProvider(category.id));
    final description = category.descriptionFor(language);

    return Scaffold(
      appBar: AppBar(title: Text(category.nameFor(language))),
      body: CatalogAsync<List<Service>>(
        value: services,
        onRetry: () => ref.invalidate(servicesInCategoryProvider(category.id)),
        builder: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: iconForCategory(category.iconKey),
              title: category.nameFor(language),
              message: l10n.categoryServicesEmptyMessage,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (description != null && description.isNotEmpty) ...[
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              for (final service in list) ...[
                ServiceCard(
                  service: service,
                  onTap: () =>
                      context.push(AppRoutes.customerService(slug, service.id)),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}
