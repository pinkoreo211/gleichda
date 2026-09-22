import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

/// A finished provider offering the fixed-price cleaning service and the
/// quoted assembly one.
FakeProviderRepository _provider() => FakeProviderRepository(
  hasProfile: true,
  status: ProviderOnboardingStatus.completed,
  fields: const {'display_name': 'Max Montagen'},
  serviceIds: {testFlatCleaning.id, testFurnitureAssembly.id},
);

Future<void> _openServices(WidgetTester tester) async {
  await tester.tap(find.text('Meine Leistungen'));
  await tester.pumpAndSettle();
}

/// Fills the price sheet and saves.
Future<void> _addPrice(
  WidgetTester tester, {
  required String name,
  required String amount,
}) async {
  await tester.tap(
    find.widgetWithText(OutlinedButton, 'Preisoption hinzufügen'),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Bezeichnung'), name);
  await tester.enterText(
    find.widgetWithText(TextField, 'Preis in Euro'),
    amount,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a service without a price says so instead of showing nothing', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      provider: _provider(),
    );
    await _openServices(tester);

    // Fixed price, nothing set: worth pointing out.
    expect(find.text('Noch kein Preis hinterlegt'), findsOneWidget);
    // Quoted: no price needed, so no nagging.
    expect(find.text('Angebot'), findsOneWidget);
  });

  testWidgets('a provider adds their own price and sees it as "ab"', (
    tester,
  ) async {
    final provider = _provider();
    await pumpSignedInApp(tester, role: AppRole.provider, provider: provider);
    await _openServices(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Bearbeiten').first);
    await tester.pumpAndSettle();
    expect(find.text('Preisgestaltung'), findsOneWidget);

    await _addPrice(tester, name: 'bis 50 m²', amount: '49,99');

    // Stored as whole cents, not as a decimal.
    final stored =
        provider.prices[FakeProviderRepository.offeringId(testFlatCleaning.id)];
    expect(stored, hasLength(1));
    expect(stored!.single.priceCents, 4999);
    expect(stored.single.name, 'bis 50 m²');
    expect(find.textContaining('49,99'), findsWidgets);

    // The list now shows the provider's own price, not the catalog's.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('ab'), findsWidgets);
    expect(find.text('Noch kein Preis hinterlegt'), findsNothing);
  });

  testWidgets('a price must have a label and a valid amount', (tester) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      provider: _provider(),
    );
    await _openServices(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Bearbeiten').first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Preisoption hinzufügen'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Bitte gib eine Bezeichnung ein.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Bezeichnung'),
      'bis 50 m²',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Preis in Euro'),
      'abc',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Bitte gib einen gültigen Preis ein.'), findsOneWidget);
  });

  testWidgets('deactivating a price takes it out of the offer, keeping it', (
    tester,
  ) async {
    final provider = _provider();
    await pumpSignedInApp(tester, role: AppRole.provider, provider: provider);
    await _openServices(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Bearbeiten').first);
    await tester.pumpAndSettle();
    await _addPrice(tester, name: 'bis 50 m²', amount: '49,99');

    await tester.tap(find.widgetWithText(TextButton, 'Deaktivieren'));
    await tester.pumpAndSettle();

    final stored =
        provider.prices[FakeProviderRepository.offeringId(testFlatCleaning.id)];
    // Kept, not deleted -- just no longer offered.
    expect(stored, hasLength(1));
    expect(stored!.single.isActive, isFalse);
    expect(find.text('Aktivieren'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Noch kein Preis hinterlegt'), findsOneWidget);
  });

  testWidgets('deleting a price removes it', (tester) async {
    final provider = _provider();
    await pumpSignedInApp(tester, role: AppRole.provider, provider: provider);
    await _openServices(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Bearbeiten').first);
    await tester.pumpAndSettle();
    await _addPrice(tester, name: 'bis 50 m²', amount: '49,99');

    await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
    await tester.pumpAndSettle();

    expect(
      provider.prices[FakeProviderRepository.offeringId(testFlatCleaning.id)],
      isEmpty,
    );
  });

  testWidgets('a quoted service is not asked for a fixed price', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      provider: _provider(),
    );
    await _openServices(tester);

    // The second offering is the quoted one.
    await tester.tap(find.widgetWithText(TextButton, 'Bearbeiten').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('brauchst du keinen Fixpreis'), findsOneWidget);
  });
}
