import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/core/routing/route_guard.dart';
import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/auth/presentation/login_screen.dart';
import 'package:app/features/availability/presentation/availability_screen.dart';
import 'package:app/features/booking/presentation/booking_done_screen.dart';
import 'package:app/features/booking/presentation/booking_location_screen.dart';
import 'package:app/features/booking/presentation/booking_providers_screen.dart';
import 'package:app/features/booking/presentation/booking_schedule_screen.dart';
import 'package:app/features/booking/presentation/booking_summary_screen.dart';
import 'package:app/features/booking/presentation/provider_detail_screen.dart';
import 'package:app/features/booking/presentation/service_suggestion_screen.dart';
import 'package:app/features/catalog/presentation/category_screen.dart';
import 'package:app/features/catalog/presentation/service_detail_screen.dart';
import 'package:app/features/chat/presentation/chat_screen.dart';
import 'package:app/features/chat/presentation/conversations_screen.dart';
import 'package:app/features/discovery/presentation/customer_home_screen.dart';
import 'package:app/features/earnings/presentation/earnings_screen.dart';
import 'package:app/features/jobs/presentation/customer_bookings_screen.dart';
import 'package:app/features/matching/presentation/provider_matches_screen.dart';
import 'package:app/features/matching/presentation/request_matches_screen.dart';
import 'package:app/features/jobs/presentation/provider_jobs_screen.dart';
import 'package:app/features/onboarding/presentation/role_selection_screen.dart';
import 'package:app/features/onboarding/presentation/welcome_screen.dart';
import 'package:app/features/profile/presentation/profile_screen.dart';
import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/provider/presentation/provider_onboarding_screen.dart';
import 'package:app/features/provider/presentation/provider_service_picker_screen.dart';
import 'package:app/features/provider/presentation/provider_service_prices_screen.dart';
import 'package:app/features/provider/presentation/provider_services_screen.dart';
import 'package:app/features/profile/presentation/edit_profile_screen.dart';
import 'package:app/features/requests/presentation/service_request_screen.dart';
import 'package:app/features/reviews/presentation/review_screen.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/domain/app_role.dart';
import 'package:app/features/shell/presentation/role_shell.dart';
import 'package:app/features/shell/presentation/shell_tab.dart';
import 'package:app/features/verification/presentation/verification_screen.dart';

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

/// The customer's chat, opened from a provider they picked. Registered as a
/// child of the provider list in both tabs that show it, so the back button
/// returns to the list the customer came from.
final GoRoute _customerChatRoute = GoRoute(
  path: ':providerId/chat',
  builder: (context, state) => ChatScreen(
    requestId: state.pathParameters['requestId']!,
    providerId: state.pathParameters['providerId']!,
    args: state.extra as ChatArgs? ?? const ChatArgs(),
  ),
);

/// The same screen under the chat list, in either role's messages tab.
final GoRoute _messagesChatRoute = GoRoute(
  path: ':requestId/:providerId/chat',
  builder: (context, state) => ChatScreen(
    requestId: state.pathParameters['requestId']!,
    providerId: state.pathParameters['providerId']!,
    args: state.extra as ChatArgs? ?? const ChatArgs(),
  ),
);

/// Handing in documents. Registered in two tabs, so it opens wherever the
/// provider tapped rather than throwing them into another tab.
final GoRoute _verificationRoute = GoRoute(
  path: 'verification',
  builder: (context, state) => const VerificationScreen(),
);

/// Editing the account's own name and picture. Registered in both profile
/// tabs, so it opens where the person tapped.
final GoRoute _editProfileRoute = GoRoute(
  path: 'edit',
  builder: (context, state) => const EditProfileScreen(),
);

/// Screens that open on top of a tab. They stay inside the tab's branch, so
/// the bottom navigation remains visible and the tab keeps its history.
List<RouteBase> _tabSubRoutes(ShellTab tab) => switch (tab) {
  ShellTab.customerHome => [
    GoRoute(
      path: 'request',
      builder: (context, state) => const ServiceRequestScreen(),
    ),
    GoRoute(
      path: 'providers/:serviceId',
      builder: (context, state) =>
          ProviderMatchesScreen(serviceId: state.pathParameters['serviceId']!),
    ),
    // The booking flow. Nested, so every step keeps the one before it on
    // the stack and "back" walks the decisions in reverse.
    GoRoute(
      path: 'book',
      builder: (context, state) => const ServiceSuggestionScreen(),
      routes: [
        GoRoute(
          path: 'where',
          builder: (context, state) => const BookingLocationScreen(),
        ),
        GoRoute(
          path: 'providers',
          builder: (context, state) => const BookingProvidersScreen(),
          routes: [
            GoRoute(
              path: ':providerId',
              builder: (context, state) => ProviderDetailScreen(
                providerId: state.pathParameters['providerId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'when',
          builder: (context, state) => const BookingScheduleScreen(),
        ),
        GoRoute(
          path: 'summary',
          builder: (context, state) => const BookingSummaryScreen(),
        ),
        GoRoute(
          path: 'done/:requestId',
          builder: (context, state) =>
              BookingDoneScreen(requestId: state.pathParameters['requestId']!),
        ),
      ],
    ),
    GoRoute(
      path: 'requests/:requestId/providers',
      builder: (context, state) =>
          RequestMatchesScreen(requestId: state.pathParameters['requestId']!),
      routes: [_customerChatRoute],
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
  // The same screen as in the home tab, under the bookings tab's own path:
  // opening it from a saved request should leave the customer in bookings.
  ShellTab.customerBookings => [
    // Listed before the id route so 'review' is not read as a request id.
    GoRoute(
      path: 'review/:contactId',
      builder: (context, state) =>
          ReviewScreen(contactId: state.pathParameters['contactId']!),
    ),
    GoRoute(
      path: ':requestId/providers',
      builder: (context, state) =>
          RequestMatchesScreen(requestId: state.pathParameters['requestId']!),
      routes: [_customerChatRoute],
    ),
  ],
  ShellTab.customerMessages ||
  ShellTab.providerMessages => [_messagesChatRoute],
  // The same screen as in the jobs tab, under the profile tab's own path:
  // opening it from the profile list should leave the provider there.
  ShellTab.providerProfile => [_verificationRoute, _editProfileRoute],
  ShellTab.customerProfile => [_editProfileRoute],
  ShellTab.providerJobs => [
    GoRoute(
      path: 'chat/:requestId',
      builder: (context, state) => ChatScreen(
        requestId: state.pathParameters['requestId']!,
        // No provider id: the backend uses the signed-in provider's own
        // profile, so this cannot be pointed at someone else's job.
        args: state.extra as ChatArgs? ?? const ChatArgs(),
      ),
    ),
    _verificationRoute,
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
