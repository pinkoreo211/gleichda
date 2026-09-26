import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/config/brand_config.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/booking/application/booking_controller.dart';
import 'package:app/features/catalog/application/catalog_providers.dart';
import 'package:app/features/catalog/domain/service_category.dart';
import 'package:app/features/catalog/presentation/widgets/catalog_async.dart';
import 'package:app/features/catalog/presentation/widgets/category_icon.dart';
import 'package:app/features/requests/application/service_request_draft_controller.dart';
import 'package:app/l10n/app_localizations.dart';

/// Customer start screen, offering the two ways into the marketplace:
/// describe the problem in your own words, or browse the catalog.
///
/// Both end up at the same catalog — the free text via the AI step later,
/// the categories directly. The categories come from the backend, so the
/// app shows however many exist without a new release.
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

  /// Starts the booking flow: the backend reads what they wrote and
  /// suggests services, and from there the customer picks a place, a
  /// provider, a price and a time.
  ///
  /// The older "describe it and ask around" route is still there — the
  /// suggestion screen offers it when nothing fits, and it stays the way
  /// in for services nobody has priced yet.
  Future<void> _openBooking() async {
    final text = _controller.text.trim();
    ref.read(bookingProvider.notifier).start(text);
    // Kept in step so switching to the older route further on still has
    // the sentence the customer typed.
    ref.read(serviceRequestDraftProvider.notifier).start(description: text);
    await context.push(AppRoutes.booking);
    if (!mounted) return;
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
                onPressed: value.text.trim().isEmpty ? null : _openBooking,
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
            const _CategoryGrid(),
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

/// The catalog's categories, however many the backend holds.
class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return CatalogAsync<List<ServiceCategory>>(
      value: ref.watch(serviceCategoriesProvider),
      onRetry: () => ref.invalidate(serviceCategoriesProvider),
      builder: (categories) {
        if (categories.isEmpty) {
          return Text(
            l10n.catalogEmptyMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          // Wide, short tiles: two fit next to each other even on a 320pt
          // screen, with room for a two-line label.
          childAspectRatio: 2.0,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final category in categories)
              _CategoryCard(category: category),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.customerCategory(category.slug)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                iconForCategory(category.iconKey),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category.nameFor(language),
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
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
