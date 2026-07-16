/// LillithApp - the visual theme.
///
/// A soft, gentle purple palette with rounded, airy shapes. Everything is
/// derived from a single lilac/amethyst seed so light and dark modes stay in
/// harmony, then nudged towards a kind, feminine feel: pill-shaped buttons,
/// generously rounded cards and inputs, and low, calm elevation.

library;

import 'package:flutter/material.dart';

/// The lilac/amethyst seed the whole palette grows from. A gentle, warm purple
/// rather than a harsh violet, so containers land on soft lavender tints.

const Color lillithSeed = Color(0xFF9B72CF);

/// A softly rounded corner used across cards, dialogs and inputs.

const double _radius = 20.0;

/// Builds the LillithApp theme for the given [brightness].
///
/// Shared between light and dark so the two modes differ only in their derived
/// [ColorScheme]; every shape, edge and density stays identical and calm.

ThemeData buildLillithTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: lillithSeed,
    brightness: brightness,
  );

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    // A touch more breathing room than the compact default reads as gentler.
    visualDensity: VisualDensity.comfortable,
    scaffoldBackgroundColor: scheme.surface,
  );

  final roundedShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_radius),
  );

  return base.copyWith(
    // Cards: soft corners, a whisper of elevation, tinted with the lilac
    // surface so the whole page feels like one warm sheet of paper.
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius + 4),
      ),
    ),

    // Buttons: fully rounded "pill" shapes feel softer than square corners.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: const StadiumBorder()),
    ),

    // Inputs: rounded, filled and borderless-at-rest for a soft data-entry
    // feel that firms up in the primary lilac when focused.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),

    // Chips, dialogs and snackbars all pick up the same soft radius.
    chipTheme: ChipThemeData(
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    dialogTheme: DialogThemeData(shape: roundedShape),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius - 4),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
  );
}

/// The light theme: airy lilac on near-white.

ThemeData get lillithLightTheme => buildLillithTheme(Brightness.light);

/// The dark theme: muted amethyst on a warm charcoal.

ThemeData get lillithDarkTheme => buildLillithTheme(Brightness.dark);
