import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/app.dart';
import 'package:app/core/config/env.dart';
import 'package:app/features/notifications/data/firebase_push_service.dart';
import 'package:app/features/notifications/data/push_service.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/data/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const _MissingConfigurationApp());
    return;
  }

  // Phone-first app: portrait only.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Date names for the market's locale (Austrian German), independent of the
  // interface language. See MarketConfig.
  await initializeDateFormatting();

  // Restores a saved sign-in before the first frame, so returning users open
  // directly in their area.
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
    authOptions: const FlutterAuthClientOptions(
      // Sign-in uses codes typed into the app, not links opening the app.
      detectSessionInUri: false,
    ),
  );

  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );

  runApp(
    ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(
          SharedPreferencesSessionStore(preferences),
        ),
        pushServiceProvider.overrideWithValue(await _pushService()),
      ],
      child: const App(),
    ),
  );
}

/// Firebase, or nothing.
///
/// A build without the Firebase configuration files, a device without
/// Google Play services, or any other reason this fails: the app runs
/// exactly as before, minus the notifications. Nobody should be kept out
/// of a working app because a messaging service would not start.
Future<PushService> _pushService() async {
  try {
    await Firebase.initializeApp();
    return FirebasePushService(FirebaseMessaging.instance);
  } catch (error) {
    debugPrint('Push notifications unavailable: $error');
    return const NoPushService();
  }
}

/// Developer-facing hint when the app was started without the environment
/// file. Never reached in correctly configured builds.
class _MissingConfigurationApp extends StatelessWidget {
  const _MissingConfigurationApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Missing configuration.\n\n'
                'Start the app with:\n'
                'flutter run --dart-define-from-file=env/dev.json\n\n'
                'See README.md → "Backend configuration".',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
