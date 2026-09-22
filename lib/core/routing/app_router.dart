import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/core/routing/route_guard.dart';
import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/auth/presentation/login_screen.dart';
import 'package:app/features/availability/presentation/availability_screen.dart';
import 'package:app/features/catalog/presentation/category_screen.dart';
import 'package:app/features/catalog/presentation/service_detail_screen.dart';
import 'package:app/features/chat/presentation/conversations_screen.dart';
import 'package:app/features/discovery/presentation/customer_home_screen.dart';
import 'package:app/features/earnings/presentation/earnings_screen.dart';
import 'package:app/features/jobs/presentation/customer_bookings_screen.dart';
import 'package:app/features/jobs/presentation/provider_jobs_screen.dart';
import 'package:app/features/onboarding/presentation/role_selection_screen.dart';
import 'package:app/features/onboarding/presentation/welcome_screen.dart';
import 'package:app/features/profile/presentation/profile_screen.dart';
import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/provider/presentation/provider_onboarding_screen.dart';
import 'package:app/features/provider/presentation/provider_service_picker_screen.dart';
import 'package:app/features/provider/presentation/provider_service_prices_screen.dart';
import 'package:app/features/provider/presentation/provider_services_screen.dart';
import 'package:app/features/requests/presentation/service_request_screen.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/domain/app_role.dart';
import 'package:app/features/shell/presentation/role_shell.dart';
import 'package:app/features/shell/presentation/shell_tab.dart';

/// The app's navigation.
///
/// The router is created once. When the user signs in or out or changes
/// mode, it re-runs the route guard instead of being rebuilt, so the user is
/// moved to the right screen without losing the router's state.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(currentUserIdProvider, (_, _) => refresh.notify());
  ref.listen(activeRoleProvider, (_, _) => refresh.notify());
  // Re-runs the guard once the provider's onboarding state is known.
  ref.listen(providerOnboardingCompletedProvider, (_, _) => refresh.notify());

  final router = GoRouter(
    initialLocation: AppRoutes.welcome,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      isSignedIn: ref.read(currentUserIdProvider) != null,
      activeRole: ref.read(activeRoleProvider),
      location: state.matchedLocation,
      providerOnboardingCompleted: ref.read(
        providerOnboardingCompletedProvider,
      ),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          // Nested so the back button returns to the welcome screen.
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      ),
      // Not nested: after sign-in there is no way "back" to the welcome screen.
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      // Outside the tab shell: onboarding is one thing at a time, with no
      // navigation bar to wander off into.
      GoRoute(
        path: AppRoutes.providerOnboarding,
        builder: (context, state) => const ProviderOnboardingScreen(),
      ),
      for (final role in AppRole.values) _roleArea(role),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

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
              routes: _tabSubRoutes(tab),
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

/// Screens that open on top of a tab. They stay inside the tab's branch, so
/// the bottom navigation remains visible and the tab keeps its history.
List<RouteBase> _tabSubRoutes(ShellTab tab) => switch (tab) {
  ShellTab.customerHome => [
    GoRoute(
      path: 'request',
      builder: (context, state) => const ServiceRequestScreen(),
    ),
    GoRoute(
      path: 'category/:categorySlug',
      builder: (context, state) =>
          CategoryScreen(slug: state.pathParameters['categorySlug']!),
      routes: [
        // Nested, so "back" from a service returns to its category.
        GoRoute(
          path: 'service/:serviceId',
          builder: (context, state) => ServiceDetailScreen(
            categorySlug: state.pathParameters['categorySlug']!,
            serviceId: state.pathParameters['serviceId']!,
          ),
        ),
      ],
    ),
  ],
  ShellTab.providerJobs => [
    GoRoute(
      path: 'services',
      builder: (context, state) => const ProviderServicesScreen(),
      routes: [
        // Listed before the id route so 'add' is not read as an id.
        GoRoute(
          path: 'add',
          builder: (context, state) => const ProviderServicePickerScreen(),
        ),
        GoRoute(
          path: ':offeringId',
          builder: (context, state) => ProviderServicePricesScreen(
            offeringId: state.pathParameters['offeringId']!,
          ),
        ),
      ],
    ),
  ],
  _ => const [],
};
