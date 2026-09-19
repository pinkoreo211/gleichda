import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/config/brand_config.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/requests/application/service_request_draft_controller.dart';
import 'package:app/features/requests/domain/service_category.dart';
import 'package:app/features/requests/presentation/widgets/service_category_display.dart';
import 'package:app/l10n/app_localizations.dart';

/// Customer start screen: describe the problem in your own words, or start
/// from a category.
///
/// The text is deliberately not interpreted here. Whatever the customer
/// writes is carried over unchanged; recognising the actual service from it
/// happens in a later AI step.
class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Keeps a half-written request visible when returning to this screen.
    _controller.text = ref.read(serviceRequestDraftProvider).description;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openRequest({ServiceCategory? category}) async {
    ref
        .read(serviceRequestDraftProvider.notifier)
        .start(description: _controller.text, category: category);
    await context.push(AppRoutes.customerRequest);
    if (!mounted) return;
    // The request screen may have changed or cleared the text.
    _controller.text = ref.read(serviceRequestDraftProvider).description;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.customerHomeTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.appTagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _RequestField(controller: _controller),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => FilledButton(
                onPressed: value.text.trim().isEmpty
                    ? null
                    : () => _openRequest(),
                child: Text(l10n.customerHomeContinue),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Examples(onSelected: (text) => _controller.text = text),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.customerHomePopularServices,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _CategoryGrid(
              onSelected: (category) => _openRequest(category: category),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.customerHomeUpcomingBookings,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            const _NoBookingsCard(),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

/// The large free-text field: the heart of the screen.
class _RequestField extends StatelessWidget {
  const _RequestField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: l10n.customerHomeInputHint,
        filled: true,
        alignLabelWithHint: true,
      ),
    );
  }
}

/// Tappable sample sentences. They show the kind of everyday wording the app
/// expects, instead of forcing the customer into a category first.
class _Examples extends StatelessWidget {
  const _Examples({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final examples = [
      l10n.customerHomeExampleWashingMachine,
      l10n.customerHomeExampleCleaning,
      l10n.customerHomeExampleTv,
      l10n.customerHomeExampleGarden,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customerHomeExamplesLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final example in examples)
              ActionChip(
                label: Text(example),
                onPressed: () => onSelected(example),
              ),
          ],
        ),
      ],
    );
  }
}

/// The eight service areas as compact cards.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onSelected});

  final ValueChanged<ServiceCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      // Wide, short tiles: two fit next to each other even on a 320pt screen,
      // with room for a two-line label at the larger body text size.
      childAspectRatio: 2.0,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final category in ServiceCategory.values)
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelected(category),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(category.icon, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        category.label(l10n),
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Honest empty state: there are no bookings yet, and none are invented.
class _NoBookingsCard extends StatelessWidget {
  const _NoBookingsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.event_note_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.customerBookingsEmptyTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.customerHomeNoBookingsMessage(BrandConfig.appName),
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
    );
  }
}
