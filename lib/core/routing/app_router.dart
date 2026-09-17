import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/onboarding/presentation/welcome_screen.dart';

/// All route paths in one place, so links never contain typos.
abstract final class AppRoutes {
  static const String welcome = '/';
}

/// The app's navigation.
///
/// Customer and provider areas (and the redirects that keep each role in
/// its own area) are added here in the onboarding step.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
