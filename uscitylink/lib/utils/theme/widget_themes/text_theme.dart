import 'package:flutter/material.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/theme/app_text.dart';

/// Maps the [AppText] scale onto Material 3's `TextTheme` slots.
///
/// Widgets that read `Theme.of(context).textTheme.*` pick the scale up for
/// free. Previously every body slot here was 14.0 with only the weight varying,
/// so the theme carried no hierarchy at all and screens hardcoded their own.
class TTextTheme {
  TTextTheme._(); // To avoid creating instances

  static TextTheme _scale({
    required Color strong,
    required Color body,
    required Color muted,
  }) =>
      TextTheme(
        displaySmall: AppText.displayLg.copyWith(color: strong),
        headlineLarge: AppText.displayLg.copyWith(color: strong),
        headlineMedium: AppText.displaySm.copyWith(color: strong),
        headlineSmall: AppText.headline.copyWith(color: strong),
        titleLarge: AppText.titleLg.copyWith(color: strong),
        titleMedium: AppText.titleMd.copyWith(color: strong),
        titleSmall: AppText.bodyMd.copyWith(
          color: strong,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: AppText.bodyLg.copyWith(color: body),
        bodyMedium: AppText.bodyMd.copyWith(color: body),
        bodySmall: AppText.bodySm.copyWith(color: muted),
        labelLarge: AppText.labelLg.copyWith(color: strong),
        labelMedium: AppText.labelMd.copyWith(color: muted),
        labelSmall: AppText.labelSm.copyWith(color: muted),
      );

  /// Customizable Light Text Theme
  static TextTheme lightTextTheme = _scale(
    strong: TColors.textStrong,
    body: TColors.textBody,
    muted: TColors.textMuted,
  );

  /// Customizable Dark Text Theme
  static TextTheme darkTextTheme = _scale(
    strong: TColors.white,
    body: const Color(0xFFCBD5E1),
    muted: const Color(0xFF94A3B8),
  );
}
