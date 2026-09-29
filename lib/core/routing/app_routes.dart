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

  /// The booking flow, one screen per decision, all inside the home tab so
  /// the whole thing sits on one back stack: service → place → provider →
  /// price → time → summary.
  static const String booking = '/customer/home/book';
  static const String bookingLocation = '/customer/home/book/where';
  static const String bookingProviders = '/customer/home/book/providers';
  static const String bookingSchedule = '/customer/home/book/when';
  static const String bookingSummary = '/customer/home/book/summary';

  static String bookingProvider(String providerId) =>
      '/customer/home/book/providers/$providerId';

  /// Carries the request id so "write a message" opens the conversation
  /// that belongs to the booking just made.
  static String bookingDone(String requestId) =>
      '/customer/home/book/done/$requestId';

  /// Catalog screens, also inside the home tab. The slug and the id come
  /// from the backend, so a link keeps working when names change.
  static String customerCategory(String categorySlug) =>
      '/customer/home/category/$categorySlug';

  static String customerService(String categorySlug, String serviceId) =>
      '/customer/home/category/$categorySlug/service/$serviceId';

  /// Providers who offer one service, browsed straight from the catalog.
  static String customerProviders(String serviceId) =>
      '/customer/home/providers/$serviceId';

  /// Providers for one saved request. The same screen is reachable from two
  /// tabs — right after writing the request, and later from the booking
  /// list — so each tab keeps its own history and its own back button.
  static String customerRequestProviders(String requestId) =>
      '/customer/home/requests/$requestId/providers';

  static String customerBookingProviders(String requestId) =>
      '/customer/bookings/$requestId/providers';

  /// The chat sits under the provider list the customer opened it from, so
  /// "back" returns there and the tab keeps its history. Built from the
  /// current location rather than a fixed prefix, because that list exists
  /// in two tabs.
  static String chatUnder(String providerListLocation, String providerId) =>
      '$providerListLocation/$providerId/chat';

  /// The provider's side. They have one job per request, so no provider id
  /// is needed — the backend uses their own profile.
  static String providerChat(String requestId) =>
      '/provider/jobs/chat/$requestId';

  /// A chat opened from the chat list. The provider is always named here,
  /// because the list shows both sides of an account that is customer for
  /// one job and provider for another.
  static String customerMessagesChat(String requestId, String providerId) =>
      '/customer/messages/$requestId/$providerId/chat';

  static String providerMessagesChat(String requestId, String providerId) =>
      '/provider/messages/$requestId/$providerId/chat';

  /// Rating one finished job. Only the customer ever reaches it, so it
  /// lives under their bookings.
  static String customerReview(String contactId) =>
      '/customer/bookings/review/$contactId';

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

  /// Handing in documents for verification. Reachable from two tabs — the
  /// card on the provider's home and the profile list — so, like the
  /// provider list on the customer side, each tab has its own path and
  /// keeps its own back button.
  static const String providerVerification = '/provider/jobs/verification';

  /// Editing the account's own name and picture. Reachable from either
  /// area's profile tab, so each keeps its own back button.
  static const String customerEditProfile = '/customer/profile/edit';
  static const String providerEditProfile = '/provider/profile/edit';

  static const String providerProfileVerification =
      '/provider/profile/verification';

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
