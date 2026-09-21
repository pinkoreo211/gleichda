import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/l10n/app_localizations.dart';

/// The verification status in words.
///
/// It only ever reports what the backend stored. Nothing in the app can set
/// it, and nothing may imply a check that has not happened — a customer
/// letting a stranger into their home deserves that honesty.
extension ProviderVerificationDisplay on ProviderVerificationStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ProviderVerificationStatus.unverified =>
      l10n.providerVerificationUnverified,
    ProviderVerificationStatus.pending => l10n.providerVerificationPending,
    ProviderVerificationStatus.verified => l10n.providerVerificationVerified,
    ProviderVerificationStatus.rejected => l10n.providerVerificationRejected,
  };

  IconData get icon => switch (this) {
    ProviderVerificationStatus.verified => Icons.verified_outlined,
    ProviderVerificationStatus.pending => Icons.hourglass_empty,
    ProviderVerificationStatus.rejected => Icons.cancel_outlined,
    ProviderVerificationStatus.unverified => Icons.shield_outlined,
  };
}

/// Shows where the provider stands and says plainly that nothing has been
/// checked yet.
class VerificationCard extends ConsumerWidget {
  const VerificationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = switch (ref.watch(myProviderProfileProvider)) {
      AsyncData(:final value) => value?.verificationStatus,
      _ => null,
    };
    // While unknown, show the cautious end rather than a hopeful one.
    final shown = status ?? ProviderVerificationStatus.unverified;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  shown.icon,
                  color: shown.isVerified
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.providerVerificationTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  shown.label(l10n),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.providerVerificationExplanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
