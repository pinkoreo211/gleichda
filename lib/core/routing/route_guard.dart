import 'package:app/core/routing/app_routes.dart';
import 'package:app/features/session/domain/app_role.dart';

/// Decides where the user may go. Returns the path to redirect to, or
/// `null` if [location] is allowed.
///
/// - Signed out: only the welcome and login screens.
/// - Signed in without a mode: only mode selection.
/// - Signed in with a mode: only that mode's area (deny by default), so a
///   customer can never open a provider screen, even through a link.
/// - A provider who has not finished onboarding is kept in it, and one who
///   has finished cannot return to it.
///
/// This protects the app's navigation only. Access to real data is enforced
/// by the backend's security rules.
String? resolveRedirect({
  required bool isSignedIn,
  required AppRole? activeRole,
  required String location,
  bool? providerOnboardingCompleted,
}) {
  if (!isSignedIn) {
    const allowed = {AppRoutes.welcome, AppRoutes.login};
    return allowed.contains(location) ? null : AppRoutes.welcome;
  }
  if (activeRole == null) {
    return location == AppRoutes.roleSelection ? null : AppRoutes.roleSelection;
  }
  if (!AppRoutes.isInside(location, AppRoutes.areaFor(activeRole))) {
    return AppRoutes.homeFor(activeRole);
  }
  if (activeRole == AppRole.provider) {
    final isOnboarding = location == AppRoutes.providerOnboarding;
    // Null means the profile has not loaded yet. Staying put beats bouncing
    // someone out of the screen they are on because of a slow connection.
    if (providerOnboardingCompleted == false && !isOnboarding) {
      return AppRoutes.providerOnboarding;
    }
    if (providerOnboardingCompleted == true && isOnboarding) {
      return AppRoutes.homeFor(activeRole);
    }
  }
  return null;
}
