import 'package:flutter/material.dart';

/// The app's type scale.
///
/// Every style here inherits `fontFamily: 'Inter'` from [TAppTheme], so none of
/// them name a family. Apply color at the call site with `.copyWith(color:)`.
///
/// Rules the scale encodes — keep new styles on it rather than inventing sizes:
///
///  * **Nothing below 11sp.** Anything a driver reads as content is >= 13sp.
///    (This is what retires the 11.5 / 12.5 / 14.5 half-sizes the dashboard
///    used to carry — half-points don't land on the pixel grid and blur.)
///  * **Three weights per screen, max:** 400 / 600 / 700. 500 exists for the
///    rare meta row that needs to sit between body and title.
///  * **Negative tracking only at >= 20sp; positive tracking only at <= 12sp.**
///    Tight tracking on small text is what makes a dense screen feel cramped;
///    loose tracking on a headline makes it feel unset.
///  * **Line height 1.2–1.3 for headings, 1.4–1.5 for body.**
///
/// Numbers on a screen that refreshes in place should use [numeric] so digits
/// keep a constant width and values don't jitter when they update.
class AppText {
  AppText._();

  // Display — hero headline and the large values on KPI/stat cards.
  static const TextStyle displayLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.21,
    letterSpacing: -0.6,
  );

  static const TextStyle displaySm = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );

  /// Fleet counts and other standalone numerals.
  static const TextStyle headline = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.30,
    letterSpacing: -0.3,
  );

  /// Section titles — "Fleet Overview", "Quick Access".
  static const TextStyle titleLg = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.2,
  );

  /// Card and tile titles.
  static const TextStyle titleMd = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.40,
    letterSpacing: -0.1,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  /// Subtitles and captions — the smallest size still used for real content.
  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.46,
  );

  /// Buttons.
  static const TextStyle labelLg = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.38,
  );

  /// Meta rows — "2 in use · 2 available".
  static const TextStyle labelMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.1,
  );

  /// Badges and pills — "Expired", "Soon". Never used for sentences.
  static const TextStyle labelSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.30,
    letterSpacing: 0.4,
  );

  /// Switches [base] to tabular (fixed-width) figures.
  ///
  /// Use on every number that can change while on screen — counts, currency,
  /// durations. With proportional figures a `1` is narrower than a `4`, so a
  /// value re-rendering after a refresh visibly shifts its neighbours.
  static TextStyle numeric(TextStyle base) =>
      base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
