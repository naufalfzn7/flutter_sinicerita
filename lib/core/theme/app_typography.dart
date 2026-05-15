import 'package:flutter/material.dart';

/// Typography tokens dari DESIGN.md — font Inter exclusively.
///
/// Gunakan langsung: `AppTypography.h1` atau via theme `Theme.of(context).textTheme`.
abstract final class AppTypography {
  static const String _fontFamily = 'Inter';

  /// Display — onboarding, mood check-in screens.
  static const TextStyle display = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28, // lineHeight 36px
    letterSpacing: -0.56, // -0.02em * 28
    color: AppTypography._defaultColor,
  );

  /// H1 — page titles.
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 28 / 22,
    letterSpacing: -0.22, // -0.01em * 22
    color: AppTypography._defaultColor,
  );

  /// H2 — section headers.
  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: AppTypography._defaultColor,
  );

  /// H3 — sub-section headers, card titles.
  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
    color: AppTypography._defaultColor,
  );

  /// Body — chat messages, articles, general content.
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    color: AppTypography._defaultColor,
  );

  /// Small — secondary text, timestamps.
  static const TextStyle small = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: AppTypography._defaultColor,
  );

  /// Caption — labels, badges, metadata.
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 16 / 11,
    letterSpacing: 0.22, // 0.02em * 11
    color: AppTypography._defaultColor,
  );

  // Default text color (on-surface)
  static const Color _defaultColor = Color(0xFFE5E1EB);
}
