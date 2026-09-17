import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/config/brand_config.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/l10n/app_localizations.dart';

/// First screen for new users.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          BrandConfig.appName,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.appTagline,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.welcomeSubtitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => context.go(AppRoutes.roleSelection),
                child: Text(l10n.welcomeGetStarted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
