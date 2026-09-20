import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/catalog/domain/service_category.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Home → tap a category card, which is how browsing starts.
Future<void> _openCleaningCategory(WidgetTester tester) async {
  await scrollTo(tester, find.text('Reinigung'));
  await tester.tap(find.text('Reinigung'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the home screen shows the categories the backend returned', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);

    await scrollTo(tester, find.text('Reinigung'));
    expect(find.text('Reinigung'), findsOneWidget);
    expect(find.text('Handwerker'), findsOneWidget);
  });

  testWidgets('the home screen adapts to however many categories exist', (
    tester,
  ) async {
    // The old version drew a fixed set of eight tiles; this one must follow
    // the data, so a category added in the database simply appears.
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      catalog: FakeCatalogRepository(
        categories: const [
          ServiceCategory(
            id: 'cat-garden',
            slug: 'garden',
            name: 'Garten',
            iconKey: 'garden',
          ),
        ],
        services: const [],
      ),
    );

    await scrollTo(tester, find.text('Garten'));
    expect(find.text('Garten'), findsOneWidget);
    expect(find.text('Reinigung'), findsNothing);
  });

  testWidgets('a category opens its services with prices', (tester) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _openCleaningCategory(tester);

    expect(find.text('Wohnungsreinigung'), findsOneWidget);
    expect(find.text('Umzugsreinigung'), findsOneWidget);
    // Handwerker belongs to another category and must not leak in.
    expect(find.text('Möbelmontage'), findsNothing);

    // Cheapest option, formatted for Austria.
    expect(find.textContaining('59,00'), findsOneWidget);
    // A quoted service says so instead of showing an invented price.
    expect(find.text('Angebot'), findsOneWidget);

    // Browsing stays inside the tab.
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a service shows its price options', (tester) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _openCleaningCategory(tester);

    await tester.tap(find.text('Wohnungsreinigung'));
    await tester.pumpAndSettle();

    expect(find.text('Preisoptionen'), findsOneWidget);
    expect(find.text('bis 50 m²'), findsOneWidget);
    expect(find.text('51–80 m²'), findsOneWidget);
    expect(find.textContaining('89,00'), findsOneWidget);
    // Prices must never read as binding.
    expect(find.textContaining('Beispielpreise'), findsOneWidget);
  });

  testWidgets('a quoted service explains that there is no fixed price', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _openCleaningCategory(tester);

    await tester.tap(find.text('Umzugsreinigung'));
    await tester.pumpAndSettle();

    expect(find.text('Preisoptionen'), findsNothing);
    expect(find.textContaining('Angebote'), findsOneWidget);
  });

  testWidgets('continuing from a service prefills the request form', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _openCleaningCategory(tester);

    await tester.tap(find.text('Wohnungsreinigung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bis 50 m²'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pumpAndSettle();

    // The catalog choice becomes an editable starting point, not a cage.
    expect(find.text('Erzähl uns kurz, was du brauchst'), findsOneWidget);
    expect(find.text('Wohnungsreinigung – bis 50 m²'), findsOneWidget);
  });

  testWidgets('a failing catalog offers a retry instead of a dead end', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      catalog: FakeCatalogRepository(failure: AppFailure.unknown),
    );

    await scrollTo(tester, find.text('Erneut versuchen'));
    expect(find.textContaining('konnten nicht geladen werden'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Erneut versuchen'),
      findsOneWidget,
    );
  });

  testWidgets('an empty catalog says so rather than showing nothing', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      catalog: FakeCatalogRepository(categories: const [], services: const []),
    );

    await scrollTo(tester, find.textContaining('Momentan sind keine Services'));
    expect(find.textContaining('Momentan sind keine Services'), findsOneWidget);
  });

  testWidgets('the bookings tab stays reachable while browsing', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _openCleaningCategory(tester);

    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Buchungen'), findsOneWidget);
  });
}
