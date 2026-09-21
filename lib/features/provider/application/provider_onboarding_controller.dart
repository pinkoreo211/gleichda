import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/provider/data/provider_repository.dart';
import 'package:app/features/provider/domain/provider_profile.dart';

/// The steps of provider onboarding, in order.
///
/// Kept as an enum so the progress line ("Schritt 2 von 5") and the resume
/// logic cannot drift apart from the screens.
enum ProviderOnboardingStep {
  personal,
  business,
  services,
  area,
  finish;

  int get number => index + 1;

  static int get count => ProviderOnboardingStep.values.length;

  /// Where a returning provider continues, derived from what the server
  /// already knows. Someone who closed the app after picking services comes
  /// back to the service area, not to their own name.
  static ProviderOnboardingStep resumeFor(ProviderProfile? profile) {
    if (profile == null) return ProviderOnboardingStep.personal;
    return switch (profile.onboardingStatus) {
      ProviderOnboardingStatus.completed => ProviderOnboardingStep.finish,
      ProviderOnboardingStatus.verificationPending =>
        ProviderOnboardingStep.finish,
      ProviderOnboardingStatus.servicesSelected => ProviderOnboardingStep.area,
      _ when !profile.hasPersonalDetails => ProviderOnboardingStep.personal,
      _ when !profile.hasBusinessDetails => ProviderOnboardingStep.business,
      _ => ProviderOnboardingStep.services,
    };
  }
}

/// Saves one onboarding step at a time.
///
/// Every step writes straight to the server, so closing the app never loses
/// what was already entered. `verification_status` is never written here —
/// the backend refuses it, and a provider must not be able to mark
/// themselves as checked.
final providerOnboardingControllerProvider =
    NotifierProvider<ProviderOnboardingController, bool>(
      ProviderOnboardingController.new,
    );

/// The state is simply "is a save running", which is all the screen needs to
/// disable its button.
class ProviderOnboardingController extends Notifier<bool> {
  @override
  bool build() => false;

  ProviderRepository get _repository => ref.read(providerRepositoryProvider);

  /// The profile row, created on first use.
  Future<ProviderProfile> _profile() async {
    final existing = await ref.read(myProviderProfileProvider.future);
    return existing ?? await _repository.startProfile();
  }

  Future<T> _saving<T>(Future<T> Function() action) async {
    state = true;
    try {
      return await action();
    } finally {
      if (ref.mounted) state = false;
    }
  }

  /// Throws [AppFailure] if the server refuses; the screen keeps the input.
  Future<void> savePersonal({
    required String firstName,
    required String lastName,
  }) async {
    await _saving(() async {
      final profile = await _profile();
      await _repository.updateProfile(profile.id, {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'onboarding_status': ProviderOnboardingStatus.profileIncomplete.dbName,
      });
      ref.invalidate(myProviderProfileProvider);
    });
  }

  Future<void> saveBusiness({
    required ProviderKind kind,
    required String name,
  }) async {
    await _saving(() async {
      final profile = await _profile();
      await _repository.updateProfile(profile.id, {
        'provider_kind': kind.dbName,
        // Both paths write the same column: a sole trader's trading name and
        // a company's name are the same thing to a customer.
        'business_name': name.trim().isEmpty ? null : name.trim(),
        'display_name': name.trim().isEmpty ? null : name.trim(),
      });
      ref.invalidate(myProviderProfileProvider);
    });
  }

  Future<void> saveServices(Set<String> serviceIds) async {
    await _saving(() async {
      final profile = await _profile();
      await _repository.setServices(profile.id, serviceIds);
      // Only ever moves onboarding forward. Editing services later must not
      // knock a finished provider back into the wizard.
      if (!profile.onboardingStatus.isCompleted) {
        await _repository.updateProfile(profile.id, {
          'onboarding_status': ProviderOnboardingStatus.servicesSelected.dbName,
        });
      }
      ref
        ..invalidate(myProviderProfileProvider)
        ..invalidate(myProviderServiceIdsProvider);
    });
  }

  Future<void> saveArea({
    required String city,
    required String postalCode,
    required int radiusKm,
  }) async {
    await _saving(() async {
      final profile = await _profile();
      await _repository.updateProfile(profile.id, {
        'city': city.trim(),
        'postal_code': postalCode.trim().isEmpty ? null : postalCode.trim(),
        'service_radius_km': radiusKm,
      });
      ref.invalidate(myProviderProfileProvider);
    });
  }

  /// Finishes onboarding. This does NOT verify anyone: the provider reaches
  /// their own area, but stays "not verified" until the team says otherwise.
  Future<void> complete() async {
    await _saving(() async {
      final profile = await _profile();
      await _repository.updateProfile(profile.id, {
        'onboarding_status': ProviderOnboardingStatus.completed.dbName,
      });
      ref.invalidate(myProviderProfileProvider);
    });
  }
}
