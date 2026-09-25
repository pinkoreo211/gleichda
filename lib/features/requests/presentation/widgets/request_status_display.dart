import 'package:material_ui/material_ui.dart';

import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/l10n/app_localizations.dart';

/// What a request's status looks like on screen.
///
/// The wording is deliberately the same for both sides: a customer reading
/// "Angenommen" and a provider reading it mean the same thing, so nobody
/// has to work out whose point of view a screen is written from.
extension RequestContactStatusDisplay on RequestContactStatus {
  String label(AppLocalizations l10n) => switch (this) {
    RequestContactStatus.sent => l10n.requestStatusOpen,
    RequestContactStatus.accepted => l10n.requestStatusAccepted,
    RequestContactStatus.declined => l10n.requestStatusDeclined,
    RequestContactStatus.scheduled => l10n.jobStatusScheduled,
    RequestContactStatus.onTheWay => l10n.jobStatusOnTheWay,
    RequestContactStatus.inProgress => l10n.jobStatusInProgress,
    RequestContactStatus.completed => l10n.jobStatusCompleted,
    RequestContactStatus.customerConfirmed => l10n.jobStatusConfirmed,
    RequestContactStatus.cancelled => l10n.jobStatusCancelled,
  };

  IconData get icon => switch (this) {
    RequestContactStatus.sent => Icons.schedule_send_outlined,
    RequestContactStatus.accepted => Icons.check_circle_outline,
    RequestContactStatus.declined => Icons.cancel_outlined,
    RequestContactStatus.scheduled => Icons.event_available_outlined,
    RequestContactStatus.onTheWay => Icons.directions_car_outlined,
    RequestContactStatus.inProgress => Icons.handyman_outlined,
    RequestContactStatus.completed => Icons.task_alt,
    RequestContactStatus.customerConfirmed => Icons.verified_outlined,
    RequestContactStatus.cancelled => Icons.cancel_outlined,
  };

  /// Progress is the good news on the screen and gets the accent colour;
  /// waiting and refusal stay quiet.
  Color color(ColorScheme colors) => switch (this) {
    RequestContactStatus.sent ||
    RequestContactStatus.declined ||
    RequestContactStatus.cancelled => colors.onSurfaceVariant,
    _ => colors.primary,
  };
}
