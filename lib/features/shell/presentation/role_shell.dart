import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/features/session/domain/app_role.dart';
import 'package:app/features/shell/presentation/shell_tab.dart';
import 'package:app/l10n/app_localizations.dart';

/// Frame around a role's area: the current tab plus the bottom navigation.
/// Each tab keeps its own navigation history while switching tabs.
class RoleShell extends StatelessWidget {
  const RoleShell({
    super.key,
    required this.role,
    required this.navigationShell,
  });

  final AppRole role;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // Tapping the active tab again returns to its first screen.
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final tab in ShellTab.forRole(role))
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label(l10n),
            ),
        ],
      ),
    );
  }
}
