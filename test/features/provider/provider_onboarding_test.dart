import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Finder _field(String label) => find.widgetWithText(TextField, label);

Future<void> _tapContinue(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
  await tester.pumpAndSettle();
}

/// Steps 1 and 2, which every later step depends on.
Future<void> _fillPersonalAndBusiness(WidgetTester tester) async {
  await tester.enterText(_field('Vorname'), 'Max');
  await tester.enterText(_field('Nachname'), 'Mustermann');
  await _tapContinue(tester);
  await tester.enterText(_field('Name deines Betriebs'), 'Max Montagen');
  await _tapContinue(tester);
}

void main() {
  testWidgets('a provider without a profile starts onboarding, not the app', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      provider: FakeProviderRepository(),
    );

    expect(find.text('Erzähl uns kurz etwas über dich.'), findsOneWidget);
    expect(find.text('Schritt 1 von 5'), findsOneWidget);
    // Onboarding is one thing at a time: no tabs to wander off into.
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('the first step asks for a name before moving on', (
    tester,
  ) async {
    final provider = FakeProviderRepository();
    await pumpSignedInApp(tester, role: AppRole.provider, provider: provider);

    await _tapContinue(tester);
    expect(find.text('Bitte gib deinen Vornamen ein.'), findsOneWidget);

    await tester.enterText(_field('Vorname'), 'Max');
    await _tapContinue(tester);
    expect(find.text('Bitte gib deinen Nachnamen ein.'), findsOneWidget);

    // Nothing was written while the input was incomplete.
    expect(provider.profile?.firstName, isNull);
  });

  testWidgets('the services step requires at least one service', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      provider: FakeProviderRepository(),
    );

    await _fillPersonalAndBusiness(tester);
    expect(find.text('Welche Leistungen bietest du an?'), findsOneWidget);

    await _tapContinue(tester);
    expect(
      find.text('Bitte wähle mindestens eine Leistung aus.'),
      findsOneWidget,
    );
  });

  testWidgets('the services come from the catalog, grouped by category', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      provider: FakeProviderRepository(),
    );
    await _fillPersonalAndBusiness(tester);

    expect(find.text('Reinigung'), findsOneWidget);
    expect(find.text('Wohnungsreinigung'), findsOneWidget);
    expect(find.text('Möbelmontage'), findsOneWidget);
  });

  testWidgets('a provider walks through onboarding and reaches their area', (
    tester,
  ) async {
    final provider = FakeProviderRepository();
    await pumpSignedInApp(tester, role: AppRole.provider, provider: provider);

    await _fillPersonalAndBusiness(tester);
    await tester.tap(find.text('Wohnungsreinigung'));
    await tester.pumpAndSettle();
    await _tapContinue(tester);

    expect(find.text('Wo möchtest du Aufträge annehmen?'), findsOneWidget);
    await tester.enterText(_field('Stadt'), 'Wien');
    await tester.enterText(_field('Postleitzahl'), '1070');
    await _tapContinue(tester);

    expect(find.text('Fast geschafft.'), findsOneWidget);
    // Nothing has been checked, and the screen says exactly that.
    expect(find.text('Nicht verifiziert'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Profil fertigstellen'));
    await tester.pumpAndSettle();

    // Everything the steps collected reached the backend.
    final profile = provider.profile;
    expect(profile?.firstName, 'Max');
    expect(profile?.lastName, 'Mustermann');
    expect(profile?.businessName, 'Max Montagen');
    expect(profile?.city, 'Wien');
    expect(profile?.serviceRadiusKm, isNotNull);
    expect(profile?.onboardingStatus, ProviderOnboardingStatus.completed);
    expect(provider.serviceIds, {testFlatCleaning.id});

    // Finishing does not verify anyone.
    expect(profile?.verificationStatus, ProviderVerificationStatus.unverified);

    // And they land in their own area, not the customer's.
    expect(find.text('Hallo, Max Montagen'), findsOneWidget);
    expect(_navLabel('Aufträge'), findsOneWidget);
    expect(_navLabel('Buchungen'), findsNothing);
  });

  testWidgets('a returning provider resumes where they left off', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.servicesSelected,
        fields: const {
          'first_name': 'Max',
          'last_name': 'Mustermann',
          'provider_kind': 'self_employed',
          'business_name': 'Max Montagen',
        },
        serviceIds: {'svc-flat-cleaning'},
      ),
    );

    // Not back at the beginning: straight to the step after services.
    expect(find.text('Wo möchtest du Aufträge annehmen?'), findsOneWidget);
    expect(find.text('Schritt 4 von 5'), findsOneWidget);
  });

  testWidgets('the provider home shows the greeting and service count', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
        fields: const {'display_name': 'Max Montagen'},
        serviceIds: {'svc-flat-cleaning', 'svc-assembly'},
      ),
    );

    expect(find.text('Hallo, Max Montagen'), findsOneWidget);
    expect(find.text('Du hast noch keine Aufträge.'), findsOneWidget);
    expect(find.text('2 Leistungen'), findsOneWidget);
  });

  testWidgets('changing services later does not restart onboarding', (
    tester,
  ) async {
    final provider = FakeProviderRepository(
      hasProfile: true,
      status: ProviderOnboardingStatus.completed,
      fields: const {'display_name': 'Max Montagen'},
      serviceIds: {'svc-flat-cleaning'},
    );
    await pumpSignedInApp(tester, role: AppRole.provider, provider: provider);

    await tester.tap(find.text('Meine Leistungen'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Leistung hinzufügen'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Möbelmontage'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(provider.serviceIds, {'svc-flat-cleaning', 'svc-assembly'});
    // Still finished, so they stay in their area instead of being sent back
    // through the wizard.
    expect(
      provider.profile?.onboardingStatus,
      ProviderOnboardingStatus.completed,
    );
    // Back on the services list, not in the wizard.
    expect(find.text('Meine Leistungen'), findsWidgets);
  });

  testWidgets('a verified provider is only shown as verified by the server', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
        verification: ProviderVerificationStatus.verified,
      ),
    );

    await scrollTo(tester, find.text('Verifizierung'));
    expect(find.text('Verifiziert'), findsOneWidget);
    expect(find.text('Nicht verifiziert'), findsNothing);
  });
}
