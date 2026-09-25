import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/reviews/data/reviews_repository.dart';
import 'package:app/features/reviews/domain/review.dart';

/// What the signed-in provider's own reviews add up to.
///
/// Empty — not five stars — while nobody has rated them, and empty as well
/// when there is no provider profile at all.
///
/// `autoDispose` so returning to the screen asks again: a customer may have
/// rated the last job in the meantime.
final myProviderRatingProvider = FutureProvider.autoDispose<ProviderRating>((
  ref,
) async {
  final profile = await ref.watch(myProviderProfileProvider.future);
  if (profile == null) return const ProviderRating();
  final reviews = await ref
      .watch(reviewsRepositoryProvider)
      .reviewsAbout(profile.id);
  return ProviderRating.from(reviews);
});
