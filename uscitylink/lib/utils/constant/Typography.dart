class TypographyOptions {
  final String fontFamily;
  final Map<String, TypographyStyle> styles;

  TypographyOptions({
    required this.fontFamily,
    required this.styles,
  });
}

class TypographyStyle {
  final String fontSize;
  final int? fontWeight;
  final double? lineHeight;
  final String? letterSpacing;
  final String? textTransform;

  TypographyStyle({
    required this.fontSize,
    this.fontWeight,
    this.lineHeight,
    this.letterSpacing,
    this.textTransform,
  });
}

class AppTypography {
  static final TypographyOptions typography = TypographyOptions(
    fontFamily:
        '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji"',
    styles: {
      'body1':
          TypographyStyle(fontSize: '1rem', fontWeight: 400, lineHeight: 1.5),
      'body2': TypographyStyle(
          fontSize: '0.875rem', fontWeight: 400, lineHeight: 1.57),
      'caption': TypographyStyle(
          fontSize: '0.75rem', fontWeight: 400, lineHeight: 1.66),
      'subtitle1':
          TypographyStyle(fontSize: '1rem', fontWeight: 500, lineHeight: 1.57),
      'subtitle2': TypographyStyle(
          fontSize: '0.875rem', fontWeight: 500, lineHeight: 1.57),
      'overline': TypographyStyle(
        fontSize: '0.75rem',
        fontWeight: 500,
        letterSpacing: '0.5px',
        lineHeight: 2.5,
        textTransform: 'uppercase',
      ),
      'h1':
          TypographyStyle(fontSize: '3.5rem', fontWeight: 500, lineHeight: 1.2),
      'h2': TypographyStyle(fontSize: '3rem', fontWeight: 500, lineHeight: 1.2),
      'h3': TypographyStyle(
          fontSize: '2.25rem', fontWeight: 500, lineHeight: 1.2),
      'h4': TypographyStyle(fontSize: '2rem', fontWeight: 500, lineHeight: 1.2),
      'h5':
          TypographyStyle(fontSize: '1.5rem', fontWeight: 500, lineHeight: 1.2),
      'h6': TypographyStyle(
          fontSize: '1.125rem', fontWeight: 500, lineHeight: 1.2),
    },
  );
}
