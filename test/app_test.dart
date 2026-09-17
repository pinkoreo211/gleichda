import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/app.dart';
import 'package:app/core/config/brand_config.dart';

void main() {
  testWidgets('starts on the welcome screen in German on an Austrian device', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'AT')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text(BrandConfig.appName), findsOneWidget);
    expect(find.text('Du brauchst wen? Gleich da.'), findsOneWidget);
  });

  testWidgets('uses English on an English device', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('Need someone? Right there.'), findsOneWidget);
  });

  testWidgets('falls back to German for unsupported device languages', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('Du brauchst wen? Gleich da.'), findsOneWidget);
  });
}
