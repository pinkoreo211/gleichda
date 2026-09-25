import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/jobs/application/my_jobs.dart';
import 'package:app/features/jobs/domain/job.dart';
import 'package:app/features/jobs/presentation/widgets/job_card.dart';
import 'package:app/l10n/app_localizations.dart';

/// The running jobs, shown the same way to both sides.
///
/// Nothing at all when there are none: an empty "your jobs" heading on a
/// screen that has other things to say is just noise. The screens below it
/// already explain what to do first.
class JobsSection extends ConsumerWidget {
  const JobsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jobs = ref.watch(myJobsProvider);

    final list = switch (jobs) {
      AsyncData(:final value) => value,
      // A failed read is not worth its own error screen here; the list
      // stays empty until the next refresh.
      _ => const <Job>[],
    };
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.jobsTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final job in list) ...[
          JobCard(job: job),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
