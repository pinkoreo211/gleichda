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
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
}

/// Icon sizes beyond the default 24.
abstract final class AppIconSize {
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 56;
}

/// Minimum height of primary buttons: large, easy thumb targets.
const double kPrimaryButtonHeight = 52;
