import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/app_colors.dart';
import 'package:app/design_system/app_dimensions.dart';

/// Light and dark themes.
///
/// Everything visual is decided here: screens only ask
/// `Theme.of(context)`. Changing the look of the whole app — colors,
/// roundness, button shape, typography — means changing this file, not the
/// screens.
///
/// Light mode is cream paper, dark mode warm near-black, and the same warm
/// orange carries every action in both. Labels on orange are always dark,
/// which is what lets one orange serve both modes.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  /// The generated scheme only fills the tones we do not care about; every
  /// color the user actually sees is set explicitly, so neither mode can
  /// drift into something unreadable.
  static ColorScheme _colorScheme(Brightness brightness) {
    final generated = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    if (brightness == Brightness.light) {
      return generated.copyWith(
        primary: AppColors.orange,
        onPrimary: AppColors.espresso,
        surface: AppColors.cream,
        onSurface: AppColors.espresso,
        onSurfaceVariant: AppColors.warmGrey,
        surfaceContainer: AppColors.creamContainer,
        surfaceContainerHigh: AppColors.creamContainerHigh,
        surfaceContainerHighest: AppColors.creamContainerHighest,
        secondaryContainer: AppColors.peach,
        onSecondaryContainer: AppColors.espresso,
        outlineVariant: AppColors.creamOutline,
      );
    }
    return generated.copyWith(
      primary: AppColors.orange,
      onPrimary: AppColors.espresso,
      surface: AppColors.night,
      onSurface: AppColors.creamText,
      onSurfaceVariant: AppColors.nightMuted,
      surfaceContainer: AppColors.nightContainer,
      surfaceContainerHigh: AppColors.nightContainerHigh,
      surfaceContainerHighest: AppColors.nightContainerHighest,
      secondaryContainer: AppColors.emberBrown,
      onSecondaryContainer: AppColors.orange,
      outlineVariant: AppColors.nightOutline,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final colorScheme = _colorScheme(brightness);
    final base = ThemeData(colorScheme: colorScheme);
    final textTheme = _textTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,

      // Plain header: the screen's own heading carries the weight.
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // Cards are separated by a slightly different surface, not by shadows.
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(kPrimaryButtonHeight),
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(kPrimaryButtonHeight),
          shape: const StadiumBorder(),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.titleMedium),
      ),

      // Borderless input: the filled surface alone marks the field, which
      // keeps large text areas calm.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Pill-shaped chips without a checkmark: the icon and the filled
      // background already show what is selected.
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: colorScheme.outlineVariant),
        backgroundColor: colorScheme.surfaceContainer,
        showCheckmark: false,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        iconColor: colorScheme.onSurfaceVariant,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 0,
        height: 76,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
    );
  }

  /// Larger and heavier than Material's defaults, with more line spacing.
  ///
  /// Two reasons: the app is used one-handed, often outdoors, and the people
  /// using it are not only twenty-year-olds. Bigger, bolder text with room
  /// to breathe is the cheapest readability win there is — and the strong
  /// contrast between headings and body text is most of what makes a screen
  /// look designed rather than typed out.
  static TextTheme _textTheme(TextTheme base) => base.copyWith(
    headlineLarge: base.headlineLarge?.copyWith(
      fontSize: 38,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      height: 1.15,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      height: 1.18,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      height: 1.22,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.35,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );
}
