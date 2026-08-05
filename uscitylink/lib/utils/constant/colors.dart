import 'package:flutter/material.dart';

class TColors {
  // App theme colors
  static const Color primary = Color(0xFF1e1650);
  static const Color primaryStaff = Color(0xFF034078);

  // Premium gradient header (driver dashboard, profile, etc.) — recalibrated to
  // the actual U.S. CityLink brand navy (from the logo's globe mark) instead of
  // the previous violet-tinted navy, so the app's chrome reads as "this company"
  // rather than a generic purple dashboard theme.
  static const Color navyHeader = Color(0xFF0A1330);
  static const Color navyHeaderDeep = Color(0xFF1B3B8C);
  static const Color secondary = Color(0xFFdde7ee);
  static const Color accent = Color(0xFFb0c7ff);

  // Brand accents pulled directly from the U.S. CityLink logo (flag red,
  // swoosh green) — used purposefully (not decoratively) so each color still
  // carries meaning: red for alerts/urgency, green for positive/active status.
  static const Color brandRed = Color(0xFFD32330);
  static const Color brandGreen = Color(0xFF1DA64A);
  static const Color brandGold = Color(0xFFC98A11);

  // Surfaces — the neutral ramp new screens are built on.
  static const Color surfaceCanvas = Color(0xFFF4F6FB); // page background
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color hairline = Color(0xFFEDF0F5); // dividers, card borders

  // Text ramp. These replace `Colors.grey.shade500` / `shade900`, which were
  // reached for inline all over the app. shade500 (#9E9E9E) is only 2.8:1 on
  // white — under the WCAG AA 4.5:1 floor for body text, and this app gets read
  // in direct sunlight through a windshield. textMuted below is 4.9:1.
  static const Color textStrong = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  // Dashboard accent pairs (gradient stops). Each pair is deep -> bright.
  static const Color violetDeep = Color(0xFF2E1B6B);
  static const Color violet = Color(0xFF5B34C4);
  static const Color tealDeep = Color(0xFF0B5D53);
  static const Color teal = Color(0xFF14A88F);
  static const Color alertInk = Color(0xFF0E1834); // inspection banner ground
  static const Color alertOrange = Color(0xFFF97316);

  // Text colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textWhite = Colors.white;

  // Background colors
  static const Color light = Color(0xFFF6F6F6);
  static const Color dark = Color(0xFF272727);
  static const Color primaryBackground = Color(0xFFF3F5FF);

  // Background Container colors
  static const Color lightContainer = Color(0xFFF6F6F6);
  static Color darkContainer = TColors.white.withOpacity(0.1);

  // Button colors
  static const Color buttonPrimary = Color(0xFF1e1650);
  static const Color buttonSecondary = Color(0xFF6C757D);
  static const Color buttonDisabled = Color(0xFFC4C4C4);

  // Border colors
  static const Color borderPrimary = Color(0xFFD9D9D9);
  static const Color borderSecondary = Color(0xFFE6E6E6);

  // Error and validation colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // Neutral Shades
  static const Color black = Color(0xFF232323);
  static const Color darkerGrey = Color(0xFF4F4F4F);
  static const Color darkGrey = Color(0xFF939393);
  static const Color grey = Color(0xFFE0E0E0);
  static const Color softGrey = Color(0xFFF4F4F4);
  static const Color lightGrey = Color(0xFFF9F9F9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFFF0EFF0);
}
