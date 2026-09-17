import 'package:material_ui/material_ui.dart';

/// Brand colors. PLACEHOLDER palette until the final branding is decided.
///
/// Screens should not use these directly; they use `Theme.of(context)`,
/// which derives a full, accessible color scheme from [brandPrimary].
abstract final class AppColors {
  /// Main brand color (buttons, highlights).
  static const Color brandPrimary = Color(0xFF00875A);
}
