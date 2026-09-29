import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/config/brand_config.dart';
import 'package:app/core/routing/app_router.dart';
import 'package:app/design_system/app_theme.dart';
import 'package:app/features/notifications/application/push_controller.dart';
import 'package:app/l10n/app_localizations.dart';

/// Root widget: connects theme, languages and navigation.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kept alive for as long as the app is, so this device is registered
    // and a tapped notification is acted on whatever screen is open.
    // Listening rather than watching: it must exist, but a change in it is
    // no reason to rebuild the whole app.
    ref.listen(pushProvider, (_, _) {});

    return MaterialApp.router(
      title: BrandConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // The phone decides: cream in light mode, near-black in dark mode.
      // A manual override follows with the settings screen.
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // Built-in texts of Material and Cupertino widgets (from material_ui,
        // not flutter_localizations, so the types match our widgets).
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
