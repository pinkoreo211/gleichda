import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_money_format.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/reviews/application/my_reviews.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/reviews/presentation/widgets/star_rating.dart';
import 'package:app/l10n/app_localizations.dart';

/// What this provider's customers have said, added up.
///
/// A provider nobody has rated reads "no reviews yet" — not five stars, and
/// not zero. Both would be a claim, and only one kind of claim is allowed
/// here: the one the reviews actually support.
class ProviderRatingCard extends ConsumerWidget {
  const ProviderRatingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rating = switch (ref.watch(myProviderRatingProvider)) {
      AsyncData(:final value) => value,
      // Unknown yet, or the read failed: show the honest end, not a
      // hopeful one.
      _ => const ProviderRating(),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.star_rounded,
              color: rating.hasReviews
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reviewYourRatingTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (rating.hasReviews)
                    Row(
                      children: [
                        Text(
                          formatRating(rating.average!),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StarRating(
                          rating: rating.average!.round(),
                          size: AppIconSize.sm,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          l10n.reviewCount(rating.count),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      l10n.reviewNone,
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
