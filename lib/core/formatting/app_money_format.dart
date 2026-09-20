import 'package:intl/intl.dart';

import 'package:app/core/config/market_config.dart';

/// Formats money for the market the app operates in (Austria: "€ 49,99"),
/// not for the user's interface language.
///
/// Money is stored and passed around as whole cents; the division happens
/// here, at the very last moment before display, so no rounding error can
/// creep into a stored amount.
String formatCents(int cents, {String currency = 'EUR'}) {
  final format = NumberFormat.simpleCurrency(
    locale: MarketConfig.launchMarket.formattingLocale.toLanguageTag(),
    name: currency,
  );
  return format.format(cents / 100);
}
