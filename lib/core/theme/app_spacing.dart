import 'package:flutter/material.dart';

/// Spacing & shape tokens dari DESIGN.md.
///
/// Semua spacing kelipatan 4px base unit.
abstract final class AppSpacing {
  // ─── Spacing Values ────────────────────────────────────────
  static const double base = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Gutter antar kolom grid.
  static const double gutter = 16;

  /// Side margin mobile.
  static const double marginMobile = 20;

  /// Side margin desktop/tablet.
  static const double marginDesktop = 40;

  // ─── Common EdgeInsets ─────────────────────────────────────

  /// Padding standar dalam card (16px all).
  static const EdgeInsets paddingCard = EdgeInsets.all(md);

  /// Padding horizontal screen mobile (20px).
  static const EdgeInsets paddingScreenH = EdgeInsets.symmetric(
    horizontal: marginMobile,
  );

  /// Padding section (24px vertical).
  static const EdgeInsets paddingSectionV = EdgeInsets.symmetric(vertical: lg);

  // ─── Border Radius ─────────────────────────────────────────

  /// 4px — small badges, tags.
  static const double radiusSm = 4;

  /// 8px — badges, mood tags.
  static const double radiusDefault = 8;

  /// 12px — buttons, inputs.
  static const double radiusMd = 12;

  /// 16px — cards, containers.
  static const double radiusLg = 16;

  /// 20px — large layout containers, hero areas.
  static const double radiusXl = 20;

  /// Full round (pill shape).
  static const double radiusFull = 9999;

  // ─── BorderRadius Presets ──────────────────────────────────
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusDefault =
      BorderRadius.circular(radiusDefault);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);

  // ─── Minimum Touch Target ──────────────────────────────────
  /// Minimum height for interactive elements (accessibility).
  static const double minTouchTarget = 48;
}
