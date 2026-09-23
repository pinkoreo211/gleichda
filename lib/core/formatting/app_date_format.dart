import 'package:intl/intl.dart';

import 'package:app/core/config/market_config.dart';

/// Dates are formatted for the market the app operates in, not for the
/// user's interface language: an English-speaking user in Vienna still sees
/// Austrian date conventions.
String _marketLocale() =>
    MarketConfig.launchMarket.formattingLocale.toLanguageTag();

/// e.g. "19. September 2026".
String formatLongDate(DateTime date) =>
    DateFormat.yMMMMd(_marketLocale()).format(date);

/// e.g. "19.09.2026".
String formatShortDate(DateTime date) =>
    DateFormat.yMd(_marketLocale()).format(date);

/// e.g. "14:05" — the market's clock, so no 12-hour times in Vienna.
String formatShortTime(DateTime time) =>
    DateFormat.Hm(_marketLocale()).format(time.toLocal());
