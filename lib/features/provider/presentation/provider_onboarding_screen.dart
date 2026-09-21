import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/features/auth/presentation/sign_out_button.dart';
import 'package:app/features/provider/application/provider_onboarding_controller.dart';
import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/provider/presentation/widgets/provider_service_picker.dart';
import 'package:app/features/provider/presentation/widgets/verification_badge.dart';
import 'package:app/l10n/app_localizations.dart';

/// Guides a new provider through their profile, one step at a time.
///
/// Every step saves to the server before moving on, so closing the app never
/// loses what was entered — and reopening resumes at the step the server
/// says they reached, not at the beginning.
class ProviderOnboardingScreen extends ConsumerStatefulWidget {
  const ProviderOnboardingScreen({super.key});

  @override
  ConsumerState<ProviderOnboardingScreen> createState() =>
      _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState
    extends ConsumerState<ProviderOnboardingScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _businessName = TextEditingController();
  final _city = TextEditingController();
  final _postalCode = TextEditingController();

  ProviderOnboardingStep? _step;
  ProviderKind? _kind;
  Set<String> _serviceIds = {};
  int _radiusKm = 15;
  String? _error;
  bool _prefilled = false;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _businessName,
      _city,
      _postalCode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Fills the form from what the server already knows, once.
  void _prefill(ProviderProfile? profile, Set<String> serviceIds) {
    if (_prefilled) return;
    _prefilled = true;
    _step = ProviderOnboardingStep.resumeFor(profile);
    _serviceIds = {...serviceIds};
    if (profile == null) return;
    _firstName.text = profile.firstName ?? '';
    _lastName.text = profile.lastName ?? '';
    _businessName.text = profile.businessName ?? '';
    _city.text = profile.city ?? '';
    _postalCode.text = profile.postalCode ?? '';
    _kind = profile.kind;
    _radiusKm = profile.serviceRadiusKm ?? 15;
  }

  void _goTo(ProviderOnboardingStep step) =>
      setState(() => (_step = step, _error = null));

  void _back() {
    final step = _step;
    if (step == null || step.index == 0) return;
    _goTo(ProviderOnboardingStep.values[step.index - 1]);
  }

  /// Runs one step's save, showing its validation error or the server's.
  Future<void> _submit({
    required String? Function(AppLocalizations l10n) validate,
    required Future<void> Function() save,
    required ProviderOnboardingStep? next,
  }) async {
    final l10n = AppLocalizations.of(context);
    final problem = validate(l10n);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _error = null);
    try {
      await save();
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
      return;
    }
    if (!mounted || next == null) return;
    _goTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(myProviderProfileProvider);
    final serviceIds = ref.watch(myProviderServiceIdsProvider);
    final isSaving = ref.watch(providerOnboardingControllerProvider);

    // Both are needed before the form can be filled in sensibly.
    if (profile.isLoading || serviceIds.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _prefill(
      switch (profile) {
        AsyncData(:final value) => value,
        _ => null,
      },
      switch (serviceIds) {
        AsyncData(:final value) => value,
        _ => const <String>{},
      },
    );

    final step = _step ?? ProviderOnboardingStep.personal;

    return Scaffold(
      appBar: AppBar(
        leading: step.index == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: isSaving ? null : _back,
                tooltip: l10n.providerBack,
              ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: SignOutButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Progress(step: step),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _content(step, l10n, theme)),
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
                onPressed: isSaving ? null : () => _onPrimary(step),
                child: isSaving
                    ? const ButtonProgress()
                    : Text(
                        step == ProviderOnboardingStep.finish
                            ? l10n.providerFinishButton
                            : l10n.customerHomeContinue,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(
    ProviderOnboardingStep step,
    AppLocalizations l10n,
    ThemeData theme,
  ) => switch (step) {
    ProviderOnboardingStep.personal => _StepBody(
      title: l10n.providerPersonalTitle,
      children: [
        TextField(
          controller: _firstName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.providerFirstNameLabel),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _lastName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.providerLastNameLabel),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () =>
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l10n.comingSoon))),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(l10n.providerPhotoAdd),
        ),
      ],
    ),
    ProviderOnboardingStep.business => _StepBody(
      title: l10n.providerBusinessTitle,
      children: [
        SegmentedButton<ProviderKind>(
          segments: [
            ButtonSegment(
              value: ProviderKind.selfEmployed,
              label: Text(l10n.providerKindSelfEmployed),
            ),
            ButtonSegment(
              value: ProviderKind.company,
              label: Text(l10n.providerKindCompany),
            ),
          ],
          selected: {?_kind},
          emptySelectionAllowed: true,
          onSelectionChanged: (selection) =>
              setState(() => _kind = selection.firstOrNull),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _businessName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: _kind == ProviderKind.company
                ? l10n.providerCompanyNameLabel
                : l10n.providerTradingNameLabel,
          ),
        ),
      ],
    ),
    ProviderOnboardingStep.services => _StepBody(
      title: l10n.providerServicesTitle,
      subtitle: l10n.providerServicesHint,
      fillsHeight: true,
      children: [
        Expanded(
          child: ProviderServicePicker(
            selected: _serviceIds,
            onChanged: (ids) => setState(() => _serviceIds = ids),
          ),
        ),
      ],
    ),
    ProviderOnboardingStep.area => _StepBody(
      title: l10n.providerAreaTitle,
      children: [
        TextField(
          controller: _city,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.providerCityLabel),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _postalCode,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.providerPostalCodeLabel),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.providerRadiusLabel(_radiusKm),
          style: theme.textTheme.titleSmall,
        ),
        Slider(
          value: _radiusKm.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          label: '$_radiusKm km',
          onChanged: (value) => setState(() => _radiusKm = value.round()),
        ),
      ],
    ),
    ProviderOnboardingStep.finish => _StepBody(
      title: l10n.providerFinishTitle,
      subtitle: l10n.providerFinishMessage,
      children: const [
        SizedBox(height: AppSpacing.lg),
        VerificationCard(),
      ],
    ),
  };

  void _onPrimary(ProviderOnboardingStep step) {
    final controller = ref.read(providerOnboardingControllerProvider.notifier);
    switch (step) {
      case ProviderOnboardingStep.personal:
        _submit(
          validate: (l10n) {
            if (_firstName.text.trim().isEmpty) {
              return l10n.errorFirstNameRequired;
            }
            if (_lastName.text.trim().isEmpty) {
              return l10n.errorLastNameRequired;
            }
            return null;
          },
          save: () => controller.savePersonal(
            firstName: _firstName.text,
            lastName: _lastName.text,
          ),
          next: ProviderOnboardingStep.business,
        );
      case ProviderOnboardingStep.business:
        _submit(
          validate: (l10n) => _businessName.text.trim().isEmpty
              ? l10n.errorBusinessNameRequired
              : null,
          save: () => controller.saveBusiness(
            // Defaults to self-employed, which is the common case in Vienna
            // and keeps the step to one decision.
            kind: _kind ?? ProviderKind.selfEmployed,
            name: _businessName.text,
          ),
          next: ProviderOnboardingStep.services,
        );
      case ProviderOnboardingStep.services:
        _submit(
          validate: (l10n) =>
              _serviceIds.isEmpty ? l10n.errorServicesRequired : null,
          save: () => controller.saveServices(_serviceIds),
          next: ProviderOnboardingStep.area,
        );
      case ProviderOnboardingStep.area:
        _submit(
          validate: (l10n) =>
              _city.text.trim().isEmpty ? l10n.errorCityRequired : null,
          save: () => controller.saveArea(
            city: _city.text,
            postalCode: _postalCode.text,
            radiusKm: _radiusKm,
          ),
          next: ProviderOnboardingStep.finish,
        );
      case ProviderOnboardingStep.finish:
        // Finishing opens the provider's own area. It does not verify
        // anyone: the status stays "not verified" until the team checks.
        _submit(validate: (_) => null, save: controller.complete, next: null);
    }
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final ProviderOnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.providerOnboardingStep(
            step.number,
            ProviderOnboardingStep.count,
          ),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: step.number / ProviderOnboardingStep.count,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// One step: a big heading, a short explanation, few fields.
class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.title,
    required this.children,
    this.subtitle,
    this.fillsHeight = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// The service picker scrolls by itself, so that step must not sit inside
  /// another scroll view.
  final bool fillsHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = [
      Text(title, style: theme.textTheme.headlineSmall),
      if (subtitle != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      ...children,
    ];

    if (fillsHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      );
    }
    return ListView(children: content);
  }
}
