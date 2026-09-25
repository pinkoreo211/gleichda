import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/app_dimensions.dart';
import 'package:app/l10n/app_localizations.dart';

/// Five stars, either to read or to tap.
///
/// [onChanged] null makes it a read-only display. The same widget both ways
/// so a rating never looks like two different things depending on who is
/// looking at it.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = AppIconSize.md,
  });

  /// Whole stars, 0 meaning nothing chosen yet.
  final int rating;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isInteractive = onChanged != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          Semantics(
            button: isInteractive,
            label: isInteractive ? starWord(l10n, star) : null,
            child: IconButton(
              onPressed: isInteractive ? () => onChanged!(star) : null,
              // A star that is not chosen is an outline, not a grey star:
              // the difference has to be obvious at a glance.
              icon: Icon(
                star <= rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: size,
                color: star <= rating
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.all(isInteractive ? AppSpacing.xs : 0),
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}

/// What a number of stars means in words.
String starWord(AppLocalizations l10n, int rating) => switch (rating) {
  1 => l10n.reviewStars1,
  2 => l10n.reviewStars2,
  3 => l10n.reviewStars3,
  4 => l10n.reviewStars4,
  _ => l10n.reviewStars5,
};
