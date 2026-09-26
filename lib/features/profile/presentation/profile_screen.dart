import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/presentation/sign_out_button.dart';
import 'package:app/features/profile/application/my_display_name.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/domain/app_role.dart';
import 'package:app/l10n/app_localizations.dart';

/// Profile, shared by customers and providers: account, mode switch and
/// sign-out. Profile editing follows later.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSwitching = false;

  void _showComingSoon() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  Future<void> _switchTo(AppRole role) async {
    setState(() => _isSwitching = true);
    try {
      await ref.read(activeRoleProvider.notifier).activate(role);
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    }
    if (mounted) setState(() => _isSwitching = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Watched so the screen updates when the account changes.
    ref.watch(currentUserIdProvider);
    final email = ref.read(authRepositoryProvider).currentEmail;
    // While loading, or if reading it failed, the name simply reads as
    // "not set" instead of blocking the whole profile.
    final displayName = switch (ref.watch(myDisplayNameProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final role = ref.watch(activeRoleProvider);
    // Briefly null while leaving the area after sign-out.
    if (role == null) return const SizedBox.shrink();

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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n.profileName),
                  subtitle: Text(displayName ?? l10n.profileNameMissing),
                ),
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: Text(l10n.profileSignedInAs),
                  subtitle: Text(email ?? ''),
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(l10n.profileCurrentMode),
                  subtitle: Text(modeName),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _isSwitching ? null : () => _switchTo(otherRole),
            icon: _isSwitching
                ? const ButtonProgress()
                : const Icon(Icons.swap_horiz),
            label: Text(switchLabel),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                // Verification belongs to the provider side only: a
                // customer has nothing to prove.
                if (role == AppRole.provider)
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(l10n.providerVerificationTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push(AppRoutes.providerProfileVerification),
                  ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.profileEdit),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showComingSoon,
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l10n.profileSettings),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showComingSoon,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SignOutButton(),
        ],
      ),
    );
  }
}
