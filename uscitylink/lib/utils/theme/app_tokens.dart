import 'package:flutter/material.dart';
import 'package:uscitylink/utils/constant/colors.dart';

/// Spacing scale — an 8pt grid with 4pt half-steps.
///
/// Prefer these over raw numbers so vertical rhythm stays consistent between
/// screens. `TSizes` is the older constant set; it is still referenced in ~30
/// places but its names drifted from their meaning (`buttonHeight = 18.0` is
/// actually vertical padding), so new work builds on these instead.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii. Larger surfaces get larger radii so curvature reads as
/// consistent across different card sizes.
class AppRadii {
  AppRadii._();

  static const double sm = 12; // chips, small tiles
  static const double md = 16; // inner elements
  static const double lg = 20; // standard card
  static const double xl = 24; // emphasis card
  static const double header = 32; // gradient header's bottom sweep
  static const double pill = 999;
}

/// Elevation. Three levels only — the app previously copy-pasted a dozen
/// slightly different `BoxShadow`s across views, which read as noise.
class AppShadows {
  AppShadows._();

  /// Resting card on the canvas.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];

  /// Card that floats above another surface (e.g. the KPI row over the header).
  static List<BoxShadow> get raised => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  /// Colored glow under a saturated gradient card, tinted to its own hue so the
  /// shadow reads as light spilling from the card rather than generic grey.
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Brand gradients. Each runs deep -> bright along the diagonal so the light
/// source stays consistent (top-left) across every card on a screen.
class AppGradients {
  AppGradients._();

  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [TColors.navyHeader, TColors.navyHeaderDeep],
  );

  static const LinearGradient messages = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [TColors.violetDeep, TColors.violet],
  );

  static const LinearGradient pay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [TColors.tealDeep, TColors.teal],
  );

  static const LinearGradient alertIcon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [TColors.alertOrange, Color(0xFFFBA94C)],
  );
}
