import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/provider/data/provider_repository.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/provider/domain/provider_service_offering.dart';

/// The signed-in provider's own profile, or null when they have not started
/// onboarding yet. Empty when signed out, so no other account's data can
/// appear.
final myProviderProfileProvider = FutureProvider<ProviderProfile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(providerRepositoryProvider).myProfile();
});

/// Whether onboarding is finished, for the navigation guard.
///
/// Null means "not known yet" — the profile is still loading. The guard
/// treats that as "do not redirect", so a slow connection never bounces
/// someone out of the screen they are on.
final providerOnboardingCompletedProvider = Provider<bool?>((ref) {
  return switch (ref.watch(myProviderProfileProvider)) {
    AsyncData(:final value) => value?.onboardingStatus.isCompleted ?? false,
    _ => null,
  };
});

/// The catalog services this provider offers.
final myProviderServiceIdsProvider = FutureProvider<Set<String>>((ref) async {
  final profile = await ref.watch(myProviderProfileProvider.future);
  if (profile == null) return const {};
  return ref.watch(providerRepositoryProvider).myServiceIds(profile.id);
});

/// The services this provider offers, with their own prices.
final myOfferingsProvider = FutureProvider<List<ProviderServiceOffering>>((
  ref,
) async {
  final profile = await ref.watch(myProviderProfileProvider.future);
  if (profile == null) return const [];
  return ref.watch(providerRepositoryProvider).myOfferings(profile.id);
});
