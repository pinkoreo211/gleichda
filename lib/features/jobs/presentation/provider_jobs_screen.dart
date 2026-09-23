import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/jobs/application/incoming_requests.dart';
import 'package:app/features/jobs/presentation/widgets/incoming_request_list.dart';
import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/provider/presentation/widgets/verification_badge.dart';
import 'package:app/l10n/app_localizations.dart';

/// The provider's home: who they are, what is waiting for them, and the
/// things they maintain themselves.
///
/// The requests customers sent them are the main content. When there are
/// none, this says so plainly rather than inventing any.
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
        // Pull to refresh: while this screen stays open, only the provider
        // can know they want to look again.
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myIncomingRequestsProvider);
            await ref.read(myIncomingRequestsProvider.future);
          },
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
              const IncomingRequestList(),
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
      ),
    );
  }
}
