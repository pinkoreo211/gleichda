import 'dart:ui' show Locale;

/// Country-specific settings for a market GleichDa operates in.
///
/// The user's *language* comes from their device (see l10n), but dates,
/// numbers and prices are always formatted for the market, e.g. Austrian
/// "Jänner" and "€ 89,00". Adding Germany later means adding one more
/// constant here; long term, markets will be loaded from the backend.
class MarketConfig {
  const MarketConfig({
    required this.countryCode,
    required this.formattingLocale,
    required this.currencyCode,
    required this.timeZone,
    required this.phonePrefix,
    required this.defaultCityName,
    required this.defaultLatitude,
    required this.defaultLongitude,
  });

  /// ISO 3166-1 alpha-2 code, e.g. `AT`.
  final String countryCode;

  /// Locale for formatting dates, numbers and currency.
  final Locale formattingLocale;

  /// ISO 4217 code, e.g. `EUR`.
  final String currencyCode;

  /// IANA time zone name, e.g. `Europe/Vienna`.
  final String timeZone;

  final String phonePrefix;

  /// Where maps and searches start when the user's location is unknown.
  final String defaultCityName;
  final double defaultLatitude;
  final double defaultLongitude;

  static const MarketConfig austria = MarketConfig(
    countryCode: 'AT',
    formattingLocale: Locale('de', 'AT'),
    currencyCode: 'EUR',
    timeZone: 'Europe/Vienna',
    phonePrefix: '+43',
    defaultCityName: 'Wien',
    defaultLatitude: 48.2082,
    defaultLongitude: 16.3738,
  );

  /// The market the app currently launches in.
  static const MarketConfig launchMarket = austria;
}
