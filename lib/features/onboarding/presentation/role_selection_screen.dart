import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/config/brand_config.dart';
import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/features/auth/presentation/sign_out_button.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/domain/app_role.dart';
import 'package:app/l10n/app_localizations.dart';

/// Lets a signed-in user choose between customer and provider mode.
///
/// Confirming registers the role on the server and saves the mode; the router
/// then moves the user into the matching area (see `route_guard.dart`).
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  AppRole? _selected;
  bool _isBusy = false;

  Future<void> _confirm(AppRole role) async {
    setState(() => _isBusy = true);
    try {
      await ref.read(activeRoleProvider.notifier).activate(role);
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    }
    if (mounted) setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = _selected;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: const [SignOutButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      l10n.roleSelectionTitle(BrandConfig.appName),
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RoleOption(
                      icon: Icons.search,
                      title: l10n.roleCustomerTitle,
                      description: l10n.roleCustomerDescription,
                      selected: selected == AppRole.customer,
                      onTap: () => setState(() => _selected = AppRole.customer),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RoleOption(
                      icon: Icons.handyman_outlined,
                      title: l10n.roleProviderTitle,
                      description: l10n.roleProviderDescription,
                      selected: selected == AppRole.provider,
                      onTap: () => setState(() => _selected = AppRole.provider),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.roleSwitchHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: selected == null || _isBusy
                    ? null
                    : () => _confirm(selected),
                child: _isBusy
                    ? const ButtonProgress()
                    : Text(l10n.roleSelectionContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppIconSize.lg,
                  color: selected ? colors.onPrimaryContainer : colors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: selected ? colors.onPrimaryContainer : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selected
                              ? colors.onPrimaryContainer
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? colors.onPrimaryContainer : colors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
