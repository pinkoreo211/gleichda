import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/reviews/domain/review.dart';

/// Reviews of finished jobs.
///
/// Writing goes through one backend function: whether the caller is that
/// job's customer, whether the job was confirmed, and whether it has been
/// rated before are all decided there. Throws [AppFailure] on errors.
abstract interface class ReviewsRepository {
  /// Rates one finished job. [rating] is one to five.
  Future<void> submit({
    required String contactId,
    required int rating,
    String? comment,
  });

  /// The reviews written about [providerId], newest first.
  ///
  /// The provider id is passed because the caller may also have written
  /// reviews as a customer, and those are about somebody else. The backend
  /// still refuses any profile that is not the caller's.
  Future<List<Review>> reviewsAbout(String providerId);
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => SupabaseReviewsRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseReviewsRepository implements ReviewsRepository {
  SupabaseReviewsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> submit({
    required String contactId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _client.rpc<dynamic>(
        'submit_review',
        params: {
          'target_contact_id': contactId,
          'new_rating': rating,
          'new_comment': comment,
        },
      );
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<List<Review>> reviewsAbout(String providerId) async {
    try {
      // The policy still decides what comes back: asking for somebody
      // else's profile returns nothing rather than their reviews.
      final rows = await _client
          .from('reviews')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      return [for (final row in rows) Review.fromJson(row)];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
