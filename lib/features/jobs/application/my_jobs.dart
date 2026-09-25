import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/jobs/data/jobs_repository.dart';
import 'package:app/features/jobs/domain/job.dart';

/// The jobs the signed-in person is part of, from either side. Empty when
/// signed out, so no other account's work can ever appear.
///
/// `autoDispose` so returning to the screen asks the server again: the
/// other side moves the job along while this one is not looking.
final myJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(jobsRepositoryProvider).myJobs();
});
