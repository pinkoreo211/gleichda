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

/// Changes which catalog services a provider offers.
///
/// Same picker as in onboarding, so the two can never drift apart. Prices
/// live one screen deeper, per service.
class ProviderServicePickerScreen extends ConsumerStatefulWidget {
  const ProviderServicePickerScreen({super.key});

  @override
  ConsumerState<ProviderServicePickerScreen> createState() =>
      _ProviderServicePickerScreenState();
}

class _ProviderServicePickerScreenState
    extends ConsumerState<ProviderServicePickerScreen> {
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
                          : Text(l10n.providerPriceSave),
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
      ref.invalidate(myOfferingsProvider);
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
      return;
    }
    if (mounted) context.pop();
  }
}
