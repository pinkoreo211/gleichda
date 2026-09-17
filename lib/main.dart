import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/app.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/data/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phone-first app: portrait only.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Loaded before the first frame, so the app opens directly in the right
  // area instead of flashing the welcome screen.
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );

  runApp(
    ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(
          SharedPreferencesSessionStore(preferences),
        ),
      ],
      child: const App(),
    ),
  );
}
