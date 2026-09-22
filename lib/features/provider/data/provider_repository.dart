import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/provider/domain/provider_service_offering.dart';

/// The signed-in provider's own profile and the services they offer.
///
/// No user id is passed in: the backend restricts every read and write to
/// the caller's own rows, and it refuses to write `verification_status` at
/// all — so nothing here can mark a provider as verified.
///
/// Throws [AppFailure] on errors.
abstract interface class ProviderRepository {
  /// The caller's provider profile, or null if they have not started yet.
  Future<ProviderProfile?> myProfile();

  /// Creates the profile row on first use and returns it.
  Future<ProviderProfile> startProfile();

  /// Writes the given fields and returns the updated profile. Only fields
  /// present in [changes] are touched, so each onboarding step saves just
  /// what it collected.
  Future<ProviderProfile> updateProfile(
    String providerId,
    Map<String, dynamic> changes,
  );

  /// The catalog service ids this provider offers.
  Future<Set<String>> myServiceIds(String providerId);

  /// Makes the provider's offering exactly [serviceIds]: adds what is new,
  /// removes what was deselected.
  Future<void> setServices(String providerId, Set<String> serviceIds);

  /// The services this provider offers, each with the catalog entry and
  /// their own prices.
  Future<List<ProviderServiceOffering>> myOfferings(String providerId);

  /// Adds a price to one of the provider's own offerings.
  ///
  /// [providerServiceId] is a `provider_services` row, which already belongs
  /// to exactly one provider — so a price can never land on a service the
  /// provider does not offer.
  Future<void> addPrice(
    String providerServiceId, {
    required String name,
    required int priceCents,
    String? unit,
    int? durationMinutes,
  });

  /// Changes one price. Pass only what should change.
  Future<void> updatePrice(String priceId, Map<String, dynamic> changes);

  Future<void> deletePrice(String priceId);
}

final providerRepositoryProvider = Provider<ProviderRepository>(
  (ref) => SupabaseProviderRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseProviderRepository implements ProviderRepository {
  SupabaseProviderRepository(this._client);

  final SupabaseClient _client;

  static const _providers = 'providers';
  static const _providerServices = 'provider_services';
  static const _providerServicePrices = 'provider_service_prices';

  @override
  Future<ProviderProfile?> myProfile() async {
    try {
      // Row level security already limits this to the caller's own row.
      final row = await _client.from(_providers).select().maybeSingle();
      return row == null ? null : ProviderProfile.fromJson(row);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<ProviderProfile> startProfile() async {
    try {
      // user_id and verification_status are left out on purpose: the server
      // sets the first and owns the second.
      final row = await _client
          .from(_providers)
          .insert({'onboarding_status': 'profile_incomplete'})
          .select()
          .single();
      return ProviderProfile.fromJson(row);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<ProviderProfile> updateProfile(
    String providerId,
    Map<String, dynamic> changes,
  ) async {
    try {
      final row = await _client
          .from(_providers)
          .update(changes)
          .eq('id', providerId)
          .select()
          .single();
      return ProviderProfile.fromJson(row);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<Set<String>> myServiceIds(String providerId) async {
    try {
      final rows = await _client
          .from(_providerServices)
          .select('service_id')
          .eq('provider_id', providerId);
      return {for (final row in rows) row['service_id'] as String};
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<List<ProviderServiceOffering>> myOfferings(String providerId) async {
    try {
      final rows = await _client
          .from(_providerServices)
          .select('*, services(*), provider_service_prices(*)')
          .eq('provider_id', providerId)
          .order(
            'sort_order',
            referencedTable: 'provider_service_prices',
            ascending: true,
          );
      return [for (final row in rows) ProviderServiceOffering.fromJson(row)];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> addPrice(
    String providerServiceId, {
    required String name,
    required int priceCents,
    String? unit,
    int? durationMinutes,
  }) async {
    try {
      await _client.from(_providerServicePrices).insert({
        'provider_service_id': providerServiceId,
        'name': name.trim(),
        'price_cents': priceCents,
        'unit': unit?.trim().isEmpty ?? true ? null : unit!.trim(),
        'duration_minutes': durationMinutes,
      });
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> updatePrice(String priceId, Map<String, dynamic> changes) async {
    try {
      await _client
          .from(_providerServicePrices)
          .update(changes)
          .eq('id', priceId);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> deletePrice(String priceId) async {
    try {
      await _client.from(_providerServicePrices).delete().eq('id', priceId);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> setServices(String providerId, Set<String> serviceIds) async {
    try {
      final existing = await myServiceIds(providerId);
      final added = serviceIds.difference(existing);
      final removed = existing.difference(serviceIds);

      if (added.isNotEmpty) {
        await _client.from(_providerServices).insert([
          for (final id in added) {'provider_id': providerId, 'service_id': id},
        ]);
      }
      if (removed.isNotEmpty) {
        await _client
            .from(_providerServices)
            .delete()
            .eq('provider_id', providerId)
            .inFilter('service_id', removed.toList());
      }
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
