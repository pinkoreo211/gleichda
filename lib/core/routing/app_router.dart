import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/core/routing/route_guard.dart';
import 'package:app/features/availability/presentation/availability_screen.dart';
import 'package:app/features/chat/presentation/conversations_screen.dart';
import 'package:app/features/discovery/presentation/customer_home_screen.dart';
import 'package:app/features/earnings/presentation/earnings_screen.dart';
import 'package:app/features/jobs/presentation/customer_bookings_screen.dart';
import 'package:app/features/jobs/presentation/provider_jobs_screen.dart';
import 'package:app/features/onboarding/presentation/role_selection_screen.dart';
import 'package:app/features/onboarding/presentation/welcome_screen.dart';
import 'package:app/features/profile/presentation/profile_screen.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/domain/app_role.dart';
import 'package:app/features/shell/presentation/role_shell.dart';
import 'package:app/features/shell/presentation/shell_tab.dart';

/// The app's navigation.
///
/// The router is created once. When the active role changes, it re-runs the
/// route guard instead of being rebuilt, so the user is moved to the right
/// area without losing the router's state.
final appRouterProvider = Provider<GoRouter>((ref) {
  final activeRole = ValueNotifier<AppRole?>(ref.read(activeRoleProvider));
  ref.listen(activeRoleProvider, (_, role) => activeRole.value = role);

  final router = GoRouter(
    initialLocation: AppRoutes.welcome,
    refreshListenable: activeRole,
    redirect: (context, state) => resolveRedirect(
      activeRole: activeRole.value,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          // Nested so the back button returns to the welcome screen.
          GoRoute(
            path: 'role',
            builder: (context, state) => const RoleSelectionScreen(),
          ),
        ],
      ),
      for (final role in AppRole.values) _roleArea(role),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    activeRole.dispose();
  });
  return router;
});

/// One role's area: a shell with a navigation branch per tab.
StatefulShellRoute _roleArea(AppRole role) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        RoleShell(role: role, navigationShell: navigationShell),
    branches: [
      for (final tab in ShellTab.forRole(role))
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: tab.path,
              builder: (context, state) => _tabScreen(tab),
            ),
          ],
        ),
    ],
  );
}

Widget _tabScreen(ShellTab tab) => switch (tab) {
  ShellTab.customerHome => const CustomerHomeScreen(),
  ShellTab.customerBookings => const CustomerBookingsScreen(),
  ShellTab.customerMessages ||
  ShellTab.providerMessages => const ConversationsScreen(),
  ShellTab.customerProfile || ShellTab.providerProfile => const ProfileScreen(),
  ShellTab.providerJobs => const ProviderJobsScreen(),
  ShellTab.providerCalendar => const AvailabilityScreen(),
  ShellTab.providerEarnings => const EarningsScreen(),
};
