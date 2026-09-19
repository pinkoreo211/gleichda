import 'package:material_ui/material_ui.dart';

/// Brand colors. PLACEHOLDER palette until the final branding is decided.
///
/// Screens never use these directly; they use `Theme.of(context)`. The theme
/// picks the right set for light or dark mode.
///
/// The idea behind the palette: a warm orange accent on a neutral warm
/// ground. Light mode is cream paper, dark mode a near-black with a brown
/// cast; the orange carries every action in both. Nothing is pure white or
/// pure black, which is what keeps it from looking cheap.
///
/// It is deliberately the *same* orange in both modes, so the brand reads
/// identically whichever mode someone uses. That only works because the
/// label on an orange surface is always the dark [espresso], never white:
/// light text on this orange would not be readable.
abstract final class AppColors {
  /// Seed for the tones the theme does not set explicitly.
  static const Color brandPrimary = orange;

  /// The accent: buttons, icons, focus rings and highlights, in both modes.
  static const Color orange = Color(0xFFF08C4B);

  /// Selected chips and the navigation indicator on cream.
  static const Color peach = Color(0xFFF7E0CE);

  /// Selected chips and the navigation indicator on dark.
  static const Color emberBrown = Color(0xFF43301F);

  // --- Light mode: cream paper ---

  /// Page background.
  static const Color cream = Color(0xFFF7F2E8);
  static const Color creamContainer = Color(0xFFF1EADC);

  /// Cards sit slightly deeper than the page.
  static const Color creamContainerHigh = Color(0xFFEBE2D0);
  static const Color creamContainerHighest = Color(0xFFE4DAC5);
  static const Color creamOutline = Color(0xFFD8CDB8);

  /// Near-black with a warm cast: text on cream, and the label on orange
  /// buttons in dark mode.
  static const Color espresso = Color(0xFF262019);

  /// Secondary text on cream.
  static const Color warmGrey = Color(0xFF6A6055);

  // --- Dark mode: warm near-black ---

  /// Page background.
  static const Color night = Color(0xFF14120F);
  static const Color nightContainer = Color(0xFF1E1B17);

  /// Cards sit slightly above the page.
  static const Color nightContainerHigh = Color(0xFF26221D);
  static const Color nightContainerHighest = Color(0xFF2F2A24);
  static const Color nightOutline = Color(0xFF3D372F);

  /// Body text on the dark background.
  static const Color creamText = Color(0xFFEDE5D8);

  /// Secondary text on the dark background.
  static const Color nightMuted = Color(0xFFB3A996);
}
