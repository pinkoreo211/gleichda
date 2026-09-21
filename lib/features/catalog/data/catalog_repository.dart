import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/domain/service_category.dart';

/// Reads the service catalog.
///
/// Read-only by design: the backend grants clients no write access to the
/// catalog at all, so there is nothing here to change it with. Categories
/// and services are maintained by the team, never from the app.
///
/// Inactive rows are filtered out by the backend's security rules, so the
/// app never has to remember to exclude them.
abstract interface class CatalogRepository {
  /// In display order.
  Future<List<ServiceCategory>> categories();

  /// The services of one category, each with its price options.
  Future<List<Service>> servicesInCategory(String categoryId);

  /// One service with its price options, or null if it is gone or inactive.
  Future<Service?> serviceById(String id);

  /// Every active service, for screens that show the whole catalog at once —
  /// one request instead of one per category.
  Future<List<Service>> allServices();
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => SupabaseCatalogRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._client);

  final SupabaseClient _client;

  /// Services are always fetched together with their price options, so a
  /// list of services costs one request instead of one per row.
  static const _serviceColumns = '*, service_price_options(*)';

  /// `ascending` is spelled out on every order below on purpose: the
  /// Supabase client sorts *descending* by default, which silently turns a
  /// curated order upside down.

  @override
  Future<List<ServiceCategory>> categories() async {
    try {
      final rows = await _client
          .from('service_categories')
          .select()
          .order('sort_order', ascending: true)
          .order('name', ascending: true);
      return [for (final row in rows) ServiceCategory.fromJson(row)];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<List<Service>> servicesInCategory(String categoryId) async {
    try {
      final rows = await _client
          .from('services')
          .select(_serviceColumns)
          .eq('category_id', categoryId)
          .order('sort_order', ascending: true)
          .order('name', ascending: true)
          .order(
            'sort_order',
            referencedTable: 'service_price_options',
            ascending: true,
          );
      return [for (final row in rows) Service.fromJson(row)];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<List<Service>> allServices() async {
    try {
      final rows = await _client
          .from('services')
          .select(_serviceColumns)
          .order('sort_order', ascending: true)
          .order('name', ascending: true);
      return [for (final row in rows) Service.fromJson(row)];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<Service?> serviceById(String id) async {
    try {
      final row = await _client
          .from('services')
          .select(_serviceColumns)
          .eq('id', id)
          .order(
            'sort_order',
            referencedTable: 'service_price_options',
            ascending: true,
          )
          .maybeSingle();
      return row == null ? null : Service.fromJson(row);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
