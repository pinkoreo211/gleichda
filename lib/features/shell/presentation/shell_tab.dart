import 'package:material_ui/material_ui.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/features/session/domain/app_role.dart';
import 'package:app/l10n/app_localizations.dart';

/// A bottom navigation tab. The router and the navigation bar are both built
/// from [forRole], so their order always matches.
enum ShellTab {
  customerHome(AppRoutes.customerHome, Icons.home_outlined, Icons.home),
  customerBookings(
    AppRoutes.customerBookings,
    Icons.event_note_outlined,
    Icons.event_note,
  ),
  customerMessages(
    AppRoutes.customerMessages,
    Icons.chat_bubble_outline,
    Icons.chat_bubble,
  ),
  customerProfile(
    AppRoutes.customerProfile,
    Icons.person_outline,
    Icons.person,
  ),
  providerJobs(AppRoutes.providerJobs, Icons.work_outline, Icons.work),
  providerCalendar(
    AppRoutes.providerCalendar,
    Icons.calendar_month_outlined,
    Icons.calendar_month,
  ),
  providerMessages(
    AppRoutes.providerMessages,
    Icons.chat_bubble_outline,
    Icons.chat_bubble,
  ),
  providerEarnings(
    AppRoutes.providerEarnings,
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet,
  ),
  providerProfile(
    AppRoutes.providerProfile,
    Icons.person_outline,
    Icons.person,
  );

  const ShellTab(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  static List<ShellTab> forRole(AppRole role) => switch (role) {
    AppRole.customer => const [
      customerHome,
      customerBookings,
      customerMessages,
      customerProfile,
    ],
    AppRole.provider => const [
      providerJobs,
      providerCalendar,
      providerMessages,
      providerEarnings,
      providerProfile,
    ],
  };

  String label(AppLocalizations l10n) => switch (this) {
    customerHome => l10n.tabHome,
    customerBookings => l10n.tabBookings,
    customerMessages || providerMessages => l10n.tabMessages,
    customerProfile || providerProfile => l10n.tabProfile,
    providerJobs => l10n.tabJobs,
    providerCalendar => l10n.tabCalendar,
    providerEarnings => l10n.tabEarnings,
  };
}
