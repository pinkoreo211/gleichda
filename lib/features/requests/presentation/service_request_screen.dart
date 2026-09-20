import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/features/catalog/application/catalog_providers.dart';
import 'package:app/features/catalog/presentation/widgets/catalog_async.dart';
import 'package:app/features/catalog/presentation/widgets/category_icon.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/features/requests/application/service_request_draft_controller.dart';
import 'package:app/features/requests/domain/request_timing.dart';
import 'package:app/features/catalog/domain/service_category.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/requests/presentation/widgets/request_timing_display.dart';
import 'package:app/l10n/app_localizations.dart';

/// Second step of a request: review and enrich what the customer wrote.
///
/// Only the description is required. Category, location, timing and photos
/// are optional on purpose, so a customer in a hurry can send a request with
/// one sentence; the AI step fills the gaps later.
class ServiceRequestScreen extends ConsumerStatefulWidget {
  const ServiceRequestScreen({super.key});

  @override
  ConsumerState<ServiceRequestScreen> createState() =>
      _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends ConsumerState<ServiceRequestScreen> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  ServiceRequestDraftController get _draft =>
      ref.read(serviceRequestDraftProvider.notifier);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(serviceRequestDraftProvider).description,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showComingSoon() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: ref.read(serviceRequestDraftProvider).preferredDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (selected == null) return;
    _draft.setTiming(RequestTiming.onDate, date: selected);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      final saved = await _draft.submit();
      if (!mounted) return;
      if (saved) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.requestSaved)));
        context.pop();
        return;
      }
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = ref.watch(serviceRequestDraftProvider);

    return Scaffold(
      appBar: AppBar(),
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
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      l10n.requestTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionLabel(l10n.requestDescriptionLabel),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _controller,
                      minLines: 3,
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: _draft.setDescription,
                      decoration: const InputDecoration(filled: true),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionLabel(l10n.requestCategoryLabel),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.requestCategoryHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CategoryChips(selected: draft.category),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionLabel(l10n.requestLocationLabel),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _showComingSoon,
                      icon: const Icon(Icons.place_outlined),
                      label: Text(l10n.requestLocationChoose),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionLabel(l10n.requestTimingLabel),
                    const SizedBox(height: AppSpacing.sm),
                    _TimingChips(draft: draft, onPickDate: _pickDate),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionLabel(l10n.requestPhotosLabel),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _showComingSoon,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(l10n.requestAddPhoto),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.requestNotSentYet,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _isSaving || !draft.isSubmittable ? null : _submit,
                child: _isSaving
                    ? const ButtonProgress()
                    : Text(l10n.requestSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleSmall);
}

/// Category choice, offering exactly the categories the catalog holds.
/// Tapping the selected chip again clears it, because "no category" stays a
/// valid answer — the AI step can fill it in later.
class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.selected});

  final ServiceCategory? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(serviceRequestDraftProvider.notifier);
    final language = Localizations.localeOf(context).languageCode;

    return CatalogAsync<List<ServiceCategory>>(
      value: ref.watch(serviceCategoriesProvider),
      onRetry: () => ref.invalidate(serviceCategoriesProvider),
      builder: (categories) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final category in categories)
            FilterChip(
              avatar: Icon(iconForCategory(category.iconKey), size: 18),
              label: Text(category.nameFor(language)),
              selected: category.id == selected?.id,
              onSelected: (isSelected) =>
                  controller.setCategory(isSelected ? category : null),
            ),
        ],
      ),
    );
  }
}

/// When the customer needs help. Picking a date also selects its option.
class _TimingChips extends ConsumerWidget {
  const _TimingChips({required this.draft, required this.onPickDate});

  final ServiceRequestDraft draft;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serviceRequestDraftProvider.notifier);
    final date = draft.preferredDate;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final timing in RequestTiming.values)
          ChoiceChip(
            label: Text(timing.label(l10n, date: date)),
            selected: timing == draft.timing,
            onSelected: (_) => timing == RequestTiming.onDate
                ? onPickDate()
                : controller.setTiming(timing),
          ),
      ],
    );
  }
}
