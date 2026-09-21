import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/provider/presentation/widgets/verification_badge.dart';
import 'package:app/l10n/app_localizations.dart';

/// The provider's home: who they are, what is waiting for them, and the
/// things they maintain themselves.
///
/// Jobs are the main content, but there are none until matching exists — so
/// this says so plainly rather than inventing any.
class ProviderJobsScreen extends ConsumerWidget {
  const ProviderJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = switch (ref.watch(myProviderProfileProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final serviceCount = switch (ref.watch(myProviderServiceIdsProvider)) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };
    final name = profile?.greetingName;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.sm),
            Text(
              name == null
                  ? l10n.providerHomeGreetingPlain
                  : l10n.providerHomeGreeting(name),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.providerHomeSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.providerJobsEmptyTitle,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.providerHomeNoJobs,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.handyman_outlined),
                    title: Text(l10n.providerHomeMyServices),
                    subtitle: Text(l10n.providerServicesCount(serviceCount)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.providerServices),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(l10n.providerHomeAvailability),
                    trailing: const Icon(Icons.chevron_right),
                    // The calendar already has its own tab; this is the
                    // shortcut from here.
                    onTap: () => context.go(AppRoutes.providerCalendar),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const VerificationCard(),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
