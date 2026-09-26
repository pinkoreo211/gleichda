import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/error_state.dart';
import 'package:app/features/booking/application/booking_controller.dart';
import 'package:app/features/booking/domain/service_suggestion.dart';
import 'package:app/l10n/app_localizations.dart';

/// Step one: turning what the customer wrote into a service from the
/// catalog.
///
/// The backend decides which services might fit. When it finds none, this
/// says so and sends the customer to the catalog rather than picking
/// something for them — a wrong guess here would follow them through the
/// whole booking.
class ServiceSuggestionScreen extends ConsumerWidget {
  const ServiceSuggestionScreen({super.key});

  void _choose(BuildContext context, WidgetRef ref, ServiceSuggestion service) {
    ref.read(bookingProvider.notifier).chooseService(service);
    context.push(AppRoutes.bookingLocation);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final description = ref.watch(bookingProvider).description;
    final suggestions = ref.watch(serviceSuggestionsProvider(description));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingTitle)),
      body: switch (suggestions) {
        AsyncData(:final value) => _Suggestions(
          description: description,
          suggestions: value,
          onChoose: (service) => _choose(context, ref, service),
        ),
        AsyncError() => ErrorState(
          message: l10n.bookingSuggestFailed,
          retryLabel: l10n.actionRetry,
          onRetry: () =>
              ref.invalidate(serviceSuggestionsProvider(description)),
        ),
        _ => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.bookingSuggestLoading,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      },
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.description,
    required this.suggestions,
    required this.onChoose,
  });

  final String description;
  final List<ServiceSuggestion> suggestions;
  final ValueChanged<ServiceSuggestion> onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final found = suggestions.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(
          found ? l10n.bookingSuggestTitle : l10n.bookingSuggestNoneTitle,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        // What they wrote, quoted back, so it is obvious what the
        // suggestions are a reading of.
        Text(
          '"${description.trim()}"',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final service in suggestions) ...[
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              title: Text(
                service.nameFor(language),
                style: theme.textTheme.titleSmall,
              ),
              subtitle: switch (service.descriptionFor(language)) {
                final String text when text.isNotEmpty => Text(text),
                _ => null,
              },
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onChoose(service),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          found ? l10n.bookingSuggestOtherHint : l10n.bookingSuggestNoneHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.customerHome),
          icon: const Icon(Icons.grid_view_outlined),
          label: Text(l10n.bookingSuggestBrowse),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
