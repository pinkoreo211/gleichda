import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/jobs/domain/job.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';

/// The accepted jobs the signed-in person is part of, from either side.
///
/// No id is passed in: the backend works out whether the caller is the
/// customer or the provider. Throws [AppFailure] on errors.
abstract interface class JobsRepository {
  /// Whatever moved most recently, first.
  Future<List<Job>> myJobs();

  /// Moves one job to [status].
  ///
  /// The backend checks who the caller is and that the step follows the one
  /// before it, so an answer of "yes, done" cannot arrive before the work
  /// has started. [appointmentAt] is required for
  /// [RequestContactStatus.scheduled] and ignored otherwise.
  Future<void> advance({
    required String contactId,
    required RequestContactStatus status,
    DateTime? appointmentAt,
  });
}

final jobsRepositoryProvider = Provider<JobsRepository>(
  (ref) => SupabaseJobsRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseJobsRepository implements JobsRepository {
  SupabaseJobsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Job>> myJobs() async {
    try {
      final rows = await _client.rpc<List<dynamic>>('my_jobs');
      return [
        for (final row in rows.whereType<Map<String, dynamic>>())
          Job.fromJson(row),
      ];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> advance({
    required String contactId,
    required RequestContactStatus status,
    DateTime? appointmentAt,
  }) async {
    try {
      await _client.rpc<dynamic>(
        'advance_job_status',
        params: {
          'target_contact_id': contactId,
          'new_status': status.dbValue,
          // Sent as UTC so an appointment means the same moment wherever
          // the two of them happen to be.
          'appointment_at': appointmentAt?.toUtc().toIso8601String(),
        },
      );
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
