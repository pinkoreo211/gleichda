import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

/// Home → Reinigung → Wohnungsreinigung → "Anbieter anzeigen".
Future<void> _openProviders(WidgetTester tester) async {
  await scrollTo(tester, find.text('Reinigung'));
  await tester.tap(find.text('Reinigung'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Wohnungsreinigung'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(OutlinedButton, 'Anbieter anzeigen'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty result says so instead of looking broken', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      matching: FakeMatchingRepository(),
    );
    await _openProviders(tester);

    expect(find.text('Noch niemand verfügbar'), findsOneWidget);
    expect(
      find.textContaining('noch kein Dienstleister eingetragen'),
      findsOneWidget,
    );
  });

  testWidgets('a match shows name, city and the provider own price', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      matching: FakeMatchingRepository(
        matches: const [
          ProviderMatch(
            providerId: 'p1',
            displayName: 'Max Montagen',
            city: 'Wien',
            verificationStatus: ProviderVerificationStatus.verified,
            lowestPriceCents: 4999,
          ),
        ],
      ),
    );
    await _openProviders(tester);

    expect(find.text('Max Montagen'), findsOneWidget);
    expect(find.text('Wien'), findsOneWidget);
    expect(find.textContaining('49,99'), findsOneWidget);
  });

  testWidgets('the verified badge only appears when the server says so', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      matching: FakeMatchingRepository(
        matches: const [
          ProviderMatch(
            providerId: 'p1',
            displayName: 'Geprüft GmbH',
            verificationStatus: ProviderVerificationStatus.verified,
            lowestPriceCents: 4999,
          ),
          ProviderMatch(
            providerId: 'p2',
            displayName: 'Noch ungeprüft',
            verificationStatus: ProviderVerificationStatus.unverified,
            lowestPriceCents: 3999,
          ),
        ],
      ),
    );
    await _openProviders(tester);

    expect(find.text('Geprüft GmbH'), findsOneWidget);
    expect(find.text('Noch ungeprüft'), findsOneWidget);
    // Exactly one badge: the unverified provider gets no claim of any kind.
    expect(find.text('Verifiziert'), findsOneWidget);
  });

  testWidgets('a provider without a price says "auf Anfrage"', (tester) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      matching: FakeMatchingRepository(
        matches: const [
          ProviderMatch(
            providerId: 'p1',
            displayName: 'Ohne Preis',
            verificationStatus: ProviderVerificationStatus.unverified,
          ),
        ],
      ),
    );
    await _openProviders(tester);

    expect(find.text('Preis auf Anfrage'), findsOneWidget);
  });

  testWidgets('the providers are looked up for the chosen service', (
    tester,
  ) async {
    final matching = FakeMatchingRepository();
    await pumpSignedInApp(tester, role: AppRole.customer, matching: matching);
    await _openProviders(tester);

    expect(matching.askedFor, [testFlatCleaning.id]);
  });

  testWidgets('a request started from the catalog carries the service', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    await pumpSignedInApp(tester, role: AppRole.customer, requests: requests);

    await scrollTo(tester, find.text('Reinigung'));
    await tester.tap(find.text('Reinigung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wohnungsreinigung'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Anfrage erstellen'));
    await tester.pumpAndSettle();

    // The catalog choice is kept, so matching does not have to guess later.
    expect(requests.requests.single.service?.id, testFlatCleaning.id);
  });
}
