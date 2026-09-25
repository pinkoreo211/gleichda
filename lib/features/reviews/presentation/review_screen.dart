import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/features/jobs/application/my_jobs.dart';
import 'package:app/features/jobs/domain/job.dart';
import 'package:app/features/matching/application/provider_matches.dart';
import 'package:app/features/reviews/data/reviews_repository.dart';
import 'package:app/features/reviews/presentation/widgets/star_rating.dart';
import 'package:app/l10n/app_localizations.dart';

/// Rating one finished job.
///
/// Deliberately a page of its own and nearly empty: five stars, who it is
/// about, and somewhere to say more if there is more to say. A verdict on
/// somebody's work deserves a moment's attention, not a row squeezed onto a
/// card between two other things.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.contactId});

  final String contactId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _isSending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _isSending) return;
    setState(() => _isSending = true);
    try {
      await ref
          .read(reviewsRepositoryProvider)
          .submit(
            contactId: widget.contactId,
            rating: _rating,
            comment: _comment.text,
          );
      if (!mounted) return;
      // Re-read rather than remember: the review that counts is the one the
      // server stored, and the provider's average has just moved.
      ref.invalidate(myJobsProvider);
      ref.invalidate(requestMatchesProvider);
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(myJobsProvider);
    final job = switch (jobs) {
      AsyncData(:final value) =>
        value.where((item) => item.contactId == widget.contactId).firstOrNull,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: switch ((jobs, job)) {
          (AsyncLoading(), _) => const Center(
            child: CircularProgressIndicator(),
          ),
          (_, final Job value) when value.isRated => _Done(job: value),
          (_, final Job value) => _Form(
            job: value,
            rating: _rating,
            comment: _comment,
            isSending: _isSending,
            onRating: (rating) => setState(() => _rating = rating),
            onSubmit: _submit,
          ),
          // The job is gone, or was never the caller's. Nothing to rate.
          _ => const _Missing(),
        },
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.job,
    required this.rating,
    required this.comment,
    required this.isSending,
    required this.onRating,
    required this.onSubmit,
  });

  final Job job;
  final int rating;
  final TextEditingController comment;
  final bool isSending;
  final ValueChanged<int> onRating;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final service = job.serviceFor(language);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.reviewTitle,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: StarRating(
                    rating: rating,
                    onChanged: onRating,
                    size: AppIconSize.xl,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // The word only appears once something was chosen: an empty
                // form should not suggest a verdict.
                SizedBox(
                  height: 28,
                  child: rating < 1
                      ? null
                      : Text(
                          starWord(l10n, rating),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  job.otherName ?? l10n.providerUnnamed,
                  style: theme.textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                if (service != null && service.isNotEmpty)
                  Text(
                    service,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.reviewCommentLabel,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: comment,
                  minLines: 3,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    filled: true,
                    hintText: l10n.reviewCommentHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          FilledButton(
            // Nothing to send without stars; a comment alone is not a
            // rating.
            onPressed: rating < 1 || isSending ? null : onSubmit,
            child: isSending ? const ButtonProgress() : Text(l10n.reviewSubmit),
          ),
        ],
      ),
    );
  }
}

/// After sending, and whenever the job was rated before: the verdict as it
/// stands, and no way to give a second one.
class _Done extends StatelessWidget {
  const _Done({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rating = job.myRating ?? 0;
    final comment = job.myComment;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(
            Icons.check_circle_outline,
            size: AppIconSize.xl,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.reviewThanks,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.reviewYours,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: StarRating(rating: rating, size: AppIconSize.lg),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            starWord(l10n, rating),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              comment,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: Text(l10n.reviewBackToJobs),
          ),
        ],
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.errorUnknown, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text(l10n.reviewBackToJobs),
            ),
          ],
        ),
      ),
    );
  }
}
