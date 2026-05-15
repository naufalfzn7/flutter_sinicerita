import 'package:flutter/material.dart';

/// Design tokens warna dari DESIGN.md — Dark Mode Only.
///
/// Palette berbasis Material 3 color roles dengan nuansa
/// nocturnal purple untuk kesan privasi dan ketenangan.
abstract final class AppColors {
  // ─── Surface ───────────────────────────────────────────────
  static const Color surface = Color(0xFF13121A);
  static const Color surfaceDim = Color(0xFF13121A);
  static const Color surfaceBright = Color(0xFF3A3840);
  static const Color surfaceContainerLowest = Color(0xFF0E0D14);
  static const Color surfaceContainerLow = Color(0xFF1C1B22);
  static const Color surfaceContainer = Color(0xFF201F26);
  static const Color surfaceContainerHigh = Color(0xFF2A2931);
  static const Color surfaceContainerHighest = Color(0xFF35343C);
  static const Color surfaceVariant = Color(0xFF35343C);

  // ─── On Surface ────────────────────────────────────────────
  static const Color onSurface = Color(0xFFE5E1EB);
  static const Color onSurfaceVariant = Color(0xFFC8C4D5);
  static const Color inverseSurface = Color(0xFFE5E1EB);
  static const Color inverseOnSurface = Color(0xFF312F37);

  // ─── Outline ───────────────────────────────────────────────
  static const Color outline = Color(0xFF928F9F);
  static const Color outlineVariant = Color(0xFF474553);

  // ─── Primary ───────────────────────────────────────────────
  static const Color primary = Color(0xFFC6BFFF);
  static const Color onPrimary = Color(0xFF2A0E95);
  static const Color primaryContainer = Color(0xFF8D80FB);
  static const Color onPrimaryContainer = Color(0xFF23008D);
  static const Color inversePrimary = Color(0xFF5A4BC4);
  static const Color surfaceTint = Color(0xFFC6BFFF);

  // ─── Secondary ─────────────────────────────────────────────
  static const Color secondary = Color(0xFFC8BFFF);
  static const Color onSecondary = Color(0xFF302371);
  static const Color secondaryContainer = Color(0xFF473B89);
  static const Color onSecondaryContainer = Color(0xFFB7ABFF);

  // ─── Tertiary ──────────────────────────────────────────────
  static const Color tertiary = Color(0xFFFFB956);
  static const Color onTertiary = Color(0xFF462B00);
  static const Color tertiaryContainer = Color(0xFFC4831A);
  static const Color onTertiaryContainer = Color(0xFF3D2500);

  // ─── Error ─────────────────────────────────────────────────
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // ─── Fixed Colors ──────────────────────────────────────────
  static const Color primaryFixed = Color(0xFFE4DFFF);
  static const Color primaryFixedDim = Color(0xFFC6BFFF);
  static const Color onPrimaryFixed = Color(0xFF160066);
  static const Color onPrimaryFixedVariant = Color(0xFF4130AB);
  static const Color secondaryFixed = Color(0xFFE5DEFF);
  static const Color secondaryFixedDim = Color(0xFFC8BFFF);
  static const Color onSecondaryFixed = Color(0xFF1A065C);
  static const Color onSecondaryFixedVariant = Color(0xFF473B89);
  static const Color tertiaryFixed = Color(0xFFFFDDB5);
  static const Color tertiaryFixedDim = Color(0xFFFFB956);
  static const Color onTertiaryFixed = Color(0xFF2A1800);
  static const Color onTertiaryFixedVariant = Color(0xFF643F00);

  // ─── Background (alias surface) ───────────────────────────
  static const Color background = Color(0xFF13121A);
  static const Color onBackground = Color(0xFFE5E1EB);

  // ─── Semantic / Convenience ────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color onSuccess = Color(0xFF003300);
}
