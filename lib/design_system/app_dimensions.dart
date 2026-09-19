/// Spacing scale. Use these instead of arbitrary numbers so every screen
/// has the same rhythm.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii for cards, buttons and inputs.
///
/// Generous by design: large, soft corners are what makes the app read as a
/// modern product rather than a plain form.
abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;

  /// For large surfaces such as the request field and category cards.
  static const double xl = 28;
}

/// Icon sizes beyond the default 24.
abstract final class AppIconSize {
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 56;
}

/// Minimum height of primary buttons: large, easy thumb targets.
const double kPrimaryButtonHeight = 56;
