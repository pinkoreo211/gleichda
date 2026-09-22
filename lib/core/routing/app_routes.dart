import 'package:app/features/session/domain/app_role.dart';

/// All route paths in one place, so links never contain typos.
///
/// Every screen belongs to exactly one area: onboarding, customer or
/// provider. `route_guard.dart` keeps each role inside its own area.
abstract final class AppRoutes {
  // Onboarding
  static const String welcome = '/welcome';
  static const String login = '/welcome/login';
  static const String roleSelection = '/welcome/role';

  // Customer area
  static const String customerArea = '/customer';
  static const String customerHome = '/customer/home';
  static const String customerBookings = '/customer/bookings';
  static const String customerMessages = '/customer/messages';
  static const String customerProfile = '/customer/profile';

  /// Second step of a request, inside the customer home tab so the bottom
  /// navigation stays visible.
  static const String customerRequest = '/customer/home/request';

  /// Catalog screens, also inside the home tab. The slug and the id come
  /// from the backend, so a link keeps working when names change.
  static String customerCategory(String categorySlug) =>
      '/customer/home/category/$categorySlug';

  static String customerService(String categorySlug, String serviceId) =>
      '/customer/home/category/$categorySlug/service/$serviceId';

  // Provider area
  static const String providerArea = '/provider';

  /// Full-screen onboarding, outside the tab shell: one thing at a time.
  /// It lives inside the provider area so the guard treats it as allowed.
  static const String providerOnboarding = '/provider/onboarding';

  /// The provider's own services, opened from their home.
  static const String providerServices = '/provider/jobs/services';

  /// Picking which catalog services the provider offers.
  static const String providerServicesAdd = '/provider/jobs/services/add';

  /// The provider's prices for one offering.
  static String providerServicePrices(String offeringId) =>
      '/provider/jobs/services/$offeringId';

  static const String providerJobs = '/provider/jobs';
  static const String providerCalendar = '/provider/calendar';
  static const String providerMessages = '/provider/messages';
  static const String providerEarnings = '/provider/earnings';
  static const String providerProfile = '/provider/profile';

  static String areaFor(AppRole role) => switch (role) {
    AppRole.customer => customerArea,
    AppRole.provider => providerArea,
  };

  /// The first screen a role sees after onboarding or a mode switch.
  static String homeFor(AppRole role) => switch (role) {
    AppRole.customer => customerHome,
    AppRole.provider => providerJobs,
  };

  /// Whether [location] is a screen inside [area].
  static bool isInside(String location, String area) =>
      location.startsWith('$area/');
}
