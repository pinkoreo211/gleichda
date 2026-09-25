import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/core/formatting/app_date_format.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/features/chat/presentation/chat_screen.dart';
import 'package:app/features/jobs/application/my_jobs.dart';
import 'package:app/features/jobs/data/jobs_repository.dart';
import 'package:app/features/jobs/domain/job.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/presentation/widgets/request_status_display.dart';
import 'package:app/features/reviews/presentation/widgets/star_rating.dart';
import 'package:app/l10n/app_localizations.dart';

/// One job, with where it stands and the one thing this side can do next.
///
/// Both people see the same card, and each is offered only their own step:
/// the provider says they are on their way, the customer confirms the work
/// is done. The backend decides the same thing again, independently — the
/// buttons are convenience, not the rule.
class JobCard extends ConsumerStatefulWidget {
  const JobCard({super.key, required this.job});

  final Job job;

  @override
  ConsumerState<JobCard> createState() => _JobCardState();
}

class _JobCardState extends ConsumerState<JobCard> {
  bool _isBusy = false;

  Job get _job => widget.job;

  /// Asks for the day and then the time. Two plain pickers rather than one
  /// clever widget: this is the moment an appointment becomes real, and it
  /// should be hard to get wrong.
  Future<DateTime?> _askForAppointment() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _job.scheduledAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (day == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _job.scheduledAt ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null) return null;
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _advance(RequestContactStatus status) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    DateTime? appointment;
    if (status == RequestContactStatus.scheduled) {
      appointment = await _askForAppointment();
      if (appointment == null || !mounted) return;
    }

    setState(() => _isBusy = true);
    try {
      await ref
          .read(jobsRepositoryProvider)
          .advance(
            contactId: _job.contactId,
            status: status,
            appointmentAt: appointment,
          );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.jobChanged)));
      // Re-read: the status that counts is the one the server stored.
      ref.invalidate(myJobsProvider);
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    }
    if (mounted) setState(() => _isBusy = false);
  }

  void _openChat() {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final path = _job.viewerIsCustomer
        ? AppRoutes.customerMessagesChat(_job.requestId, _job.providerId)
        : AppRoutes.providerMessagesChat(_job.requestId, _job.providerId);

    context.push(
      path,
      extra: ChatArgs(
        otherName: _job.otherName ?? _fallbackName(l10n),
        serviceName: _job.serviceFor(language),
      ),
    );
  }

  String _fallbackName(AppLocalizations l10n) => _job.viewerIsCustomer
      ? l10n.providerUnnamed
      : l10n.providerIncomingCustomerUnknown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final name = _job.otherName ?? _fallbackName(l10n);
    final service = _job.serviceFor(language);
    final next = _job.nextStep;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (service != null && service.isNotEmpty)
              Text(service, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Headline(job: _job, name: name),
            const SizedBox(height: AppSpacing.md),
            if (!_job.status.isFinished) ...[
              _Steps(status: _job.status),
              const SizedBox(height: AppSpacing.md),
            ],
            // A finished job asks the customer what they thought, once.
            if (_job.status.isFinished && _job.viewerIsCustomer)
              if (_job.isRated)
                _GivenRating(rating: _job.myRating!)
              else
                FilledButton(
                  onPressed: () =>
                      context.push(AppRoutes.customerReview(_job.contactId)),
                  child: Text(l10n.reviewRate),
                )
            else if (_job.status.isFinished && _job.isRated)
              // The provider sees the verdict about them, and cannot give
              // one of their own.
              _GivenRating(rating: _job.myRating!)
            else if (next != null)
              FilledButton(
                onPressed: _isBusy ? null : () => _advance(next),
                child: _isBusy
                    ? const ButtonProgress()
                    : Text(_labelFor(next, l10n)),
              )
            else if (!_job.status.isFinished)
              Text(
                // Nothing for this side to do: say whose turn it is rather
                // than leaving a card that looks unfinished.
                _job.viewerIsCustomer
                    ? l10n.jobWaitingForProvider
                    : l10n.jobCompletedWaiting,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(l10n.jobOpenChat),
            ),
          ],
        ),
      ),
    );
  }

  static String _labelFor(RequestContactStatus next, AppLocalizations l10n) =>
      switch (next) {
        RequestContactStatus.scheduled => l10n.jobSetAppointment,
        RequestContactStatus.onTheWay => l10n.jobOnMyWay,
        RequestContactStatus.inProgress => l10n.jobStartWork,
        RequestContactStatus.completed => l10n.jobReportDone,
        RequestContactStatus.customerConfirmed => l10n.jobConfirm,
        _ => l10n.jobChanged,
      };
}

/// The rating this job already has, shown the same to both of them.
class _GivenRating extends StatelessWidget {
  const _GivenRating({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StarRating(rating: rating, size: AppIconSize.sm),
        const SizedBox(width: AppSpacing.sm),
        Text(
          starWord(l10n, rating),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Where the job stands, in one line big enough to read at a glance, with
/// the one detail that matters underneath.
class _Headline extends StatelessWidget {
  const _Headline({required this.job, required this.name});

  final Job job;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = job.status;
    final color = status.color(theme.colorScheme);

    final headline = switch (status) {
      // Only the customer is waiting for somebody: naming the other person
      // on the provider's own screen would tell them the customer is
      // driving to themselves.
      RequestContactStatus.onTheWay when job.viewerIsCustomer =>
        l10n.jobOnTheWayNamed(name),
      RequestContactStatus.onTheWay => l10n.jobOnTheWaySelf,
      RequestContactStatus.customerConfirmed => l10n.jobFinished,
      _ => status.label(l10n),
    };

    final detail = switch (status) {
      RequestContactStatus.accepted => l10n.jobNoAppointment,
      // Only the customer is asked for something here. The provider's "now
      // we wait" line lives below the steps, where every other "nothing for
      // you to do" message is — saying it in both places read as a stutter.
      RequestContactStatus.completed when job.viewerIsCustomer =>
        l10n.jobCompletedAsk,
      RequestContactStatus.completed => null,
      _ =>
        job.scheduledAt == null
            ? null
            : l10n.jobAppointment(formatDateTime(job.scheduledAt!)),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(status.icon, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                headline,
                style: theme.textTheme.titleMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
        if (detail != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// The four steps of a job, with what is done, what is happening and what
/// is still ahead. Deliberately a short list and not a drawn timeline: it
/// answers "how far along is this" without becoming the subject of the
/// screen.
class _Steps extends StatelessWidget {
  const _Steps({required this.status});

  final RequestContactStatus status;

  static const _order = [
    RequestContactStatus.scheduled,
    RequestContactStatus.onTheWay,
    RequestContactStatus.inProgress,
    RequestContactStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final step in _order)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  switch (status.step.compareTo(step.step)) {
                    > 0 => Icons.check,
                    0 => Icons.radio_button_checked,
                    _ => Icons.radio_button_unchecked,
                  },
                  size: AppIconSize.sm,
                  color: status.step >= step.step
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  step.label(l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: status.step >= step.step
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
