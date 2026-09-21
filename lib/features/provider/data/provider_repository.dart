import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/provider/domain/provider_profile.dart';

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
}

final providerRepositoryProvider = Provider<ProviderRepository>(
  (ref) => SupabaseProviderRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseProviderRepository implements ProviderRepository {
  SupabaseProviderRepository(this._client);

  final SupabaseClient _client;

  static const _providers = 'providers';
  static const _providerServices = 'provider_services';

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
