import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/config/brand_config.dart';
import 'package:app/features/session/domain/app_role.dart';

import 'helpers/pump_app.dart';

void main() {
  group('language', () {
    testWidgets('German on an Austrian device', (tester) async {
      await pumpApp(tester);

      expect(find.text(BrandConfig.appName), findsOneWidget);
      expect(find.text('Du brauchst wen? Gleich da.'), findsOneWidget);
    });

    testWidgets('English on an English device', (tester) async {
      await pumpApp(tester, locale: const Locale('en', 'GB'));

      expect(find.text('Need someone? Right there.'), findsOneWidget);
    });

    testWidgets('German fallback for unsupported languages', (tester) async {
      await pumpApp(tester, locale: const Locale('tr', 'TR'));

      expect(find.text('Du brauchst wen? Gleich da.'), findsOneWidget);
    });
  });

  group('app start', () {
    testWidgets('new users see the welcome screen', (tester) async {
      await pumpApp(tester);

      expect(find.text("Los geht's"), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('a remembered customer opens directly in the customer area', (
      tester,
    ) async {
      await pumpApp(tester, store: InMemorySessionStore(AppRole.customer));

      expect(find.text('Was brauchst du?'), findsOneWidget);
    });

    testWidgets('a remembered provider opens directly in the provider area', (
      tester,
    ) async {
      await pumpApp(tester, store: InMemorySessionStore(AppRole.provider));

      expect(find.text('Noch keine Aufträge'), findsOneWidget);
    });
  });
}
