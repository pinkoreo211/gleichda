import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/core/routing/route_guard.dart';
import 'package:app/features/session/domain/app_role.dart';

void main() {
  group('without a role', () {
    String? redirect(String location) =>
        resolveRedirect(activeRole: null, location: location);

    test('allows onboarding screens', () {
      expect(redirect(AppRoutes.welcome), isNull);
      expect(redirect(AppRoutes.roleSelection), isNull);
    });

    test('sends every other screen to the welcome screen', () {
      expect(redirect(AppRoutes.customerHome), AppRoutes.welcome);
      expect(redirect(AppRoutes.providerJobs), AppRoutes.welcome);
      expect(redirect('/'), AppRoutes.welcome);
      expect(redirect('/welcomeback'), AppRoutes.welcome);
    });
  });

  group('as customer', () {
    String? redirect(String location) =>
        resolveRedirect(activeRole: AppRole.customer, location: location);

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
      expect(redirect(AppRoutes.roleSelection), AppRoutes.customerHome);
      expect(redirect(AppRoutes.customerArea), AppRoutes.customerHome);
      expect(redirect('/'), AppRoutes.customerHome);
      expect(redirect('/customerx/home'), AppRoutes.customerHome);
    });
  });

  group('as provider', () {
    String? redirect(String location) =>
        resolveRedirect(activeRole: AppRole.provider, location: location);

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
}
