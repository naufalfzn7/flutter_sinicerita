import 'package:flutter/material.dart';

/// Design tokens warna SiniCerita — Dark Mode Only.
abstract final class AppColors {
  // ─── Surface ───────────────────────────────────────────────
  static const Color surface = Color(0xFF07111F);
  static const Color surfaceDim = Color(0xFF050B14);
  static const Color surfaceBright = Color(0xFF22334A);
  static const Color surfaceContainerLowest = Color(0xFF030812);
  static const Color surfaceContainerLow = Color(0xFF0B1626);
  static const Color surfaceContainer = Color(0xFF101D2F);
  static const Color surfaceContainerHigh = Color(0xFF17263B);
  static const Color surfaceContainerHighest = Color(0xFF21334C);
  static const Color surfaceVariant = Color(0xFF283B55);

  // ─── On Surface ────────────────────────────────────────────
  static const Color onSurface = Color(0xFFF2F6FF);
  static const Color onSurfaceVariant = Color(0xFFB6C2D6);
  static const Color inverseSurface = Color(0xFFF2F6FF);
  static const Color inverseOnSurface = Color(0xFF142033);

  // ─── Outline ───────────────────────────────────────────────
  static const Color outline = Color(0xFF788AA5);
  static const Color outlineVariant = Color(0xFF2E405A);

  // ─── Primary ───────────────────────────────────────────────
  static const Color primary = Color(0xFF4EE3D3);
  static const Color onPrimary = Color(0xFF00201D);
  static const Color primaryContainer = Color(0xFF7C63F4);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color inversePrimary = Color(0xFF007A70);
  static const Color surfaceTint = Color(0xFF4EE3D3);

  // ─── Secondary ─────────────────────────────────────────────
  static const Color secondary = Color(0xFFA892FF);
  static const Color onSecondary = Color(0xFF180C4E);
  static const Color secondaryContainer = Color(0xFF35266C);
  static const Color onSecondaryContainer = Color(0xFFE3DCFF);

  // ─── Tertiary ──────────────────────────────────────────────
  static const Color tertiary = Color(0xFFFFC857);
  static const Color onTertiary = Color(0xFF2E2100);
  static const Color tertiaryContainer = Color(0xFF6E5000);
  static const Color onTertiaryContainer = Color(0xFFFFDEA2);

  // ─── Error ─────────────────────────────────────────────────
  static const Color error = Color(0xFFFF6B5F);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // ─── Fixed Colors ──────────────────────────────────────────
  static const Color primaryFixed = Color(0xFFBFFAF4);
  static const Color primaryFixedDim = Color(0xFF4EE3D3);
  static const Color onPrimaryFixed = Color(0xFF00201D);
  static const Color onPrimaryFixedVariant = Color(0xFF005047);
  static const Color secondaryFixed = Color(0xFFE5DEFF);
  static const Color secondaryFixedDim = Color(0xFFC8BFFF);
  static const Color onSecondaryFixed = Color(0xFF1A065C);
  static const Color onSecondaryFixedVariant = Color(0xFF473B89);
  static const Color tertiaryFixed = Color(0xFFFFDDB5);
  static const Color tertiaryFixedDim = Color(0xFFFFB956);
  static const Color onTertiaryFixed = Color(0xFF2A1800);
  static const Color onTertiaryFixedVariant = Color(0xFF643F00);

  // ─── Background (alias surface) ───────────────────────────
  static const Color background = Color(0xFF07111F);
  static const Color onBackground = Color(0xFFF2F6FF);

  // ─── Semantic / Convenience ────────────────────────────────
  static const Color success = Color(0xFF55D56B);
  static const Color onSuccess = Color(0xFF001F08);
  static const Color coral = Color(0xFFFF6B5F);
  static const Color lavender = Color(0xFFA892FF);
  static const Color glass = Color(0x6617263B);
}
