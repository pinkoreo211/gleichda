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
  };

  IconData get icon => switch (this) {
    RequestContactStatus.sent => Icons.schedule_send_outlined,
    RequestContactStatus.accepted => Icons.check_circle_outline,
    RequestContactStatus.declined => Icons.cancel_outlined,
  };

  /// An accepted request is the good news on the screen and is the only one
  /// worth the accent colour; the others stay quiet.
  Color color(ColorScheme colors) => switch (this) {
    RequestContactStatus.accepted => colors.primary,
    RequestContactStatus.sent ||
    RequestContactStatus.declined => colors.onSurfaceVariant,
  };
}
