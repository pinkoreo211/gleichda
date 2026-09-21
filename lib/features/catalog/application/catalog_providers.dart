import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/catalog/data/catalog_repository.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/domain/service_category.dart';

/// All categories a customer may browse, in display order.
///
/// Shared by the home screen and the category chips on the request form, so
/// both always offer exactly the same list and it is fetched once.
final serviceCategoriesProvider = FutureProvider<List<ServiceCategory>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

/// One category by its slug, taken from the already loaded list rather than
/// a second request. Null while loading or if the slug is unknown.
final categoryBySlugProvider = Provider.family<ServiceCategory?, String>((
  ref,
  slug,
) {
  final categories = switch (ref.watch(serviceCategoriesProvider)) {
    AsyncData(:final value) => value,
    _ => null,
  };
  if (categories == null) return null;
  for (final category in categories) {
    if (category.slug == slug) return category;
  }
  return null;
});

/// The services of one category, each with its price options.
final servicesInCategoryProvider = FutureProvider.family<List<Service>, String>(
  (ref, categoryId) {
    return ref.watch(catalogRepositoryProvider).servicesInCategory(categoryId);
  },
);

/// One service with its price options.
final serviceByIdProvider = FutureProvider.family<Service?, String>((ref, id) {
  return ref.watch(catalogRepositoryProvider).serviceById(id);
});

/// Every service in the catalog, for screens that show all of them at once.
final allServicesProvider = FutureProvider<List<Service>>(
  (ref) => ref.watch(catalogRepositoryProvider).allServices(),
);
