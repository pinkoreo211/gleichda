import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/domain/app_role.dart';
import 'package:app/l10n/app_localizations.dart';

/// Profile, shared by customers and providers. For now it shows the active
/// mode and lets the user switch; account details follow with sign-in.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final role = ref.watch(activeRoleProvider);
    // Briefly null while leaving the area after "restart onboarding".
    if (role == null) return const SizedBox.shrink();

    final roleController = ref.read(activeRoleProvider.notifier);
    final (modeName, switchLabel, otherRole) = switch (role) {
      AppRole.customer => (
        l10n.roleCustomerModeName,
        l10n.profileSwitchToProvider,
        AppRole.provider,
      ),
      AppRole.provider => (
        l10n.roleProviderModeName,
        l10n.profileSwitchToCustomer,
        AppRole.customer,
      ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(l10n.profileCurrentMode),
              subtitle: Text(modeName),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => roleController.select(otherRole),
            icon: const Icon(Icons.swap_horiz),
            label: Text(switchLabel),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.profileAccountComingSoon,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              onPressed: roleController.clear,
              child: Text(l10n.profileRestartOnboarding),
            ),
          ],
        ],
      ),
    );
  }
}
