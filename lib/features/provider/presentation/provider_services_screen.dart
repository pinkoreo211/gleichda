import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/features/provider/application/provider_onboarding_controller.dart';
import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/provider/presentation/widgets/provider_service_picker.dart';
import 'package:app/l10n/app_localizations.dart';

/// Lets a provider change what they offer after onboarding.
///
/// Same picker as in onboarding, so the two can never drift apart. Prices
/// per service are prepared in the backend but not editable yet.
class ProviderServicesScreen extends ConsumerStatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  ConsumerState<ProviderServicesScreen> createState() =>
      _ProviderServicesScreenState();
}

class _ProviderServicesScreenState
    extends ConsumerState<ProviderServicesScreen> {
  Set<String>? _selected;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stored = ref.watch(myProviderServiceIdsProvider);
    final isSaving = ref.watch(providerOnboardingControllerProvider);

    final selected =
        _selected ??
        switch (stored) {
          AsyncData(:final value) => value,
          _ => null,
        };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.providerHomeMyServices)),
      body: SafeArea(
        child: selected == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ProviderServicePicker(
                        selected: selected,
                        onChanged: (ids) => setState(() {
                          _selected = ids;
                          _error = null;
                        }),
                      ),
                    ),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    FilledButton(
                      onPressed: isSaving ? null : () => _save(selected),
                      child: isSaving
                          ? const ButtonProgress()
                          : Text(l10n.customerHomeContinue),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _save(Set<String> selected) async {
    final l10n = AppLocalizations.of(context);
    if (selected.isEmpty) {
      setState(() => _error = l10n.errorServicesRequired);
      return;
    }
    try {
      await ref
          .read(providerOnboardingControllerProvider.notifier)
          .saveServices(selected);
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
      return;
    }
    if (mounted) context.pop();
  }
}
