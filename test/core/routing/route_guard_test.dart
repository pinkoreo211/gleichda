import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/core/routing/route_guard.dart';
import 'package:app/features/session/domain/app_role.dart';

void main() {
  group('signed out', () {
    String? redirect(String location) => resolveRedirect(
      isSignedIn: false,
      activeRole: null,
      location: location,
    );

    test('allows welcome and login', () {
      expect(redirect(AppRoutes.welcome), isNull);
      expect(redirect(AppRoutes.login), isNull);
    });

    test('sends everything else to the welcome screen', () {
      expect(redirect(AppRoutes.roleSelection), AppRoutes.welcome);
      expect(redirect(AppRoutes.customerHome), AppRoutes.welcome);
      expect(redirect(AppRoutes.providerJobs), AppRoutes.welcome);
      expect(redirect('/'), AppRoutes.welcome);
      expect(redirect('/welcome/unknown'), AppRoutes.welcome);
    });

    test('ignores a leftover mode', () {
      expect(
        resolveRedirect(
          isSignedIn: false,
          activeRole: AppRole.customer,
          location: AppRoutes.customerHome,
        ),
        AppRoutes.welcome,
      );
    });
  });

  group('signed in without a mode', () {
    String? redirect(String location) =>
        resolveRedirect(isSignedIn: true, activeRole: null, location: location);

    test('allows only mode selection', () {
      expect(redirect(AppRoutes.roleSelection), isNull);
      expect(redirect(AppRoutes.welcome), AppRoutes.roleSelection);
      expect(redirect(AppRoutes.login), AppRoutes.roleSelection);
      expect(redirect(AppRoutes.customerHome), AppRoutes.roleSelection);
      expect(redirect(AppRoutes.providerJobs), AppRoutes.roleSelection);
    });
  });

  group('signed in as customer', () {
    String? redirect(String location) => resolveRedirect(
      isSignedIn: true,
      activeRole: AppRole.customer,
      location: location,
    );

    test('allows customer screens', () {
      expect(redirect(AppRoutes.customerHome), isNull);
      expect(redirect(AppRoutes.customerProfile), isNull);
    });

    test('blocks provider screens', () {
      expect(redirect(AppRoutes.providerJobs), AppRoutes.customerHome);
      expect(redirect(AppRoutes.providerEarnings), AppRoutes.customerHome);
    });

    test('skips onboarding and unknown areas', () {
      expect(redirect(AppRoutes.welcome), AppRoutes.customerHome);
      expect(redirect(AppRoutes.login), AppRoutes.customerHome);
      expect(redirect(AppRoutes.roleSelection), AppRoutes.customerHome);
      expect(redirect(AppRoutes.customerArea), AppRoutes.customerHome);
      expect(redirect('/'), AppRoutes.customerHome);
      expect(redirect('/customerx/home'), AppRoutes.customerHome);
    });
  });

  group('signed in as provider', () {
    String? redirect(String location) => resolveRedirect(
      isSignedIn: true,
      activeRole: AppRole.provider,
      location: location,
    );

    test('allows provider screens', () {
      expect(redirect(AppRoutes.providerJobs), isNull);
      expect(redirect(AppRoutes.providerProfile), isNull);
    });

    test('blocks customer screens and onboarding', () {
      expect(redirect(AppRoutes.customerHome), AppRoutes.providerJobs);
      expect(redirect(AppRoutes.customerBookings), AppRoutes.providerJobs);
      expect(redirect(AppRoutes.welcome), AppRoutes.providerJobs);
    });
  });

  group('provider onboarding', () {
    String? redirect(String location, {bool? completed}) => resolveRedirect(
      isSignedIn: true,
      activeRole: AppRole.provider,
      location: location,
      providerOnboardingCompleted: completed,
    );

    test('keeps an unfinished provider in onboarding', () {
      expect(
        redirect(AppRoutes.providerJobs, completed: false),
        AppRoutes.providerOnboarding,
      );
      expect(
        redirect(AppRoutes.providerProfile, completed: false),
        AppRoutes.providerOnboarding,
      );
      expect(redirect(AppRoutes.providerOnboarding, completed: false), isNull);
    });

    test('does not send a finished provider back into onboarding', () {
      expect(
        redirect(AppRoutes.providerOnboarding, completed: true),
        AppRoutes.providerJobs,
      );
      expect(redirect(AppRoutes.providerJobs, completed: true), isNull);
    });

    test('stays put while the onboarding state is still unknown', () {
      // A slow connection must not bounce someone out of their screen.
      expect(redirect(AppRoutes.providerJobs), isNull);
      expect(redirect(AppRoutes.providerOnboarding), isNull);
    });

    test('never applies to customers', () {
      expect(
        resolveRedirect(
          isSignedIn: true,
          activeRole: AppRole.customer,
          location: AppRoutes.customerHome,
          providerOnboardingCompleted: false,
        ),
        isNull,
      );
    });
  });
}
