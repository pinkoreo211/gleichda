import 'package:app/core/formatting/app_date_format.dart';
import 'package:app/features/requests/domain/request_timing.dart';
import 'package:app/l10n/app_localizations.dart';

/// How a [RequestTiming] reads. Shared by the request form and the list of
/// saved requests so both always word it the same way.
extension RequestTimingDisplay on RequestTiming {
  /// [date] is only used by [RequestTiming.onDate]; without it that option
  /// reads as the invitation to pick one.
  String label(AppLocalizations l10n, {DateTime? date}) => switch (this) {
    RequestTiming.asap => l10n.requestTimingAsap,
    RequestTiming.today => l10n.requestTimingToday,
    RequestTiming.tomorrow => l10n.requestTimingTomorrow,
    RequestTiming.onDate =>
      date == null ? l10n.requestTimingPickDate : formatLongDate(date),
  };
}
