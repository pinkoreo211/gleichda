import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_money_format.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/avatar.dart';
import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/design_system/widgets/error_state.dart';
import 'package:app/features/booking/application/booking_controller.dart';
import 'package:app/features/booking/domain/provider_offer.dart';
import 'package:app/features/provider/presentation/widgets/verification_badge.dart';
import 'package:app/l10n/app_localizations.dart';

/// Step four: one provider, and what they charge for this service.
///
/// Every price on this screen is a row the provider wrote. The app adds
/// nothing, rounds nothing and estimates nothing — if a provider listed no
/// price, they are not in this flow at all.
class ProviderDetailScreen extends ConsumerWidget {
  const ProviderDetailScreen({super.key, required this.providerId});

  final String providerId;

  void _choose(
    BuildContext context,
    WidgetRef ref,
    ProviderOffer offer,
    ProviderPrice price,
  ) {
    final controller = ref.read(bookingProvider.notifier);
    controller.chooseProvider(offer);
    controller.choosePrice(price);
    context.push(AppRoutes.bookingSchedule);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final offer = ref.watch(providerOfferProvider(providerId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingProviderTitle)),
      body: switch (offer) {
        AsyncData(:final value?) => _Offer(
          offer: value,
          onChoose: (price) => _choose(context, ref, value, price),
        ),
        // The provider stopped offering this service, or stopped being
        // verified, between the list and this tap.
        AsyncData() => EmptyState(
          icon: Icons.person_off_outlined,
          title: l10n.bookingProviderGoneTitle,
          message: l10n.bookingProviderGone,
        ),
        AsyncError() => ErrorState(
          message: l10n.bookingProviderFailed,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(providerOfferProvider(providerId)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Offer extends ConsumerWidget {
  const _Offer({required this.offer, required this.onChoose});

  final ProviderOffer offer;
  final ValueChanged<ProviderPrice> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final service = ref.watch(bookingProvider).service;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Avatar(
              imageUrl: offer.profileImageUrl,
              name: offer.displayName,
              size: AppAvatarSize.lg,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                offer.displayName ?? l10n.providerUnnamed,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            if (offer.verificationStatus.isVerified) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                offer.verificationStatus.icon,
                size: AppIconSize.sm,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                offer.verificationStatus.label(l10n),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        if (offer.city case final String city when city.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            city,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Nothing at all when nobody has rated them. An unrated provider is
        // unrated, not five stars.
        if (offer.hasRating)
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                size: AppIconSize.sm,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                formatRating(offer.ratingAverage!),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.reviewCount(offer.ratingCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        if (offer.description case final String text when text.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          service?.nameFor(language) ?? l10n.bookingPricesTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.bookingPricesHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final price in offer.prices) ...[
          _PriceCard(price: price, onChoose: () => onChoose(price)),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price, required this.onChoose});

  final ProviderPrice price;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(price.name, style: theme.textTheme.titleSmall),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formatCents(price.priceCents, currency: price.currency),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (price.description case final String text
                when text.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            // Only what the provider actually wrote down.
            if (price.unit != null || price.durationMinutes != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  ?price.unit,
                  if (price.durationMinutes case final int minutes)
                    l10n.bookingApproxMinutes(minutes),
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onChoose,
                child: Text(l10n.bookingChoosePrice),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
