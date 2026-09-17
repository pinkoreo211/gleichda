import 'package:app/core/routing/app_routes.dart';
import 'package:app/features/session/domain/app_role.dart';

/// Decides where the user may go. Returns the path to redirect to, or
/// `null` if [location] is allowed.
///
/// - Without a role, only onboarding is reachable.
/// - With a role, only that role's area is reachable (deny by default), so a
///   customer can never open a provider screen, even through a link.
///
/// This protects the app's navigation only. Access to real data is enforced
/// by the backend's security rules.
String? resolveRedirect({
  required AppRole? activeRole,
  required String location,
}) {
  if (activeRole == null) {
    final inOnboarding =
        location == AppRoutes.welcome ||
        AppRoutes.isInside(location, AppRoutes.welcome);
    return inOnboarding ? null : AppRoutes.welcome;
  }
  return AppRoutes.isInside(location, AppRoutes.areaFor(activeRole))
      ? null
      : AppRoutes.homeFor(activeRole);
}
