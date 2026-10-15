import type { TypographyOptions } from '@mui/material/styles/createTypography';

// Inter everywhere: one family, a tight scale, weight does the hierarchy
export const typography = {
  fontFamily:
    '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji"',
  body1: { fontSize: '0.9375rem', fontWeight: 400, lineHeight: 1.6 },
  body2: { fontSize: '0.875rem', fontWeight: 400, lineHeight: 1.55 },
  button: { fontSize: '0.875rem', fontWeight: 600, letterSpacing: 0 },
  caption: { fontSize: '0.75rem', fontWeight: 400, lineHeight: 1.5 },
  subtitle1: { fontSize: '0.9375rem', fontWeight: 600, lineHeight: 1.5 },
  subtitle2: { fontSize: '0.875rem', fontWeight: 600, lineHeight: 1.5 },
  overline: { fontSize: '0.6875rem', fontWeight: 600, letterSpacing: '0.06em', lineHeight: 2, textTransform: 'uppercase' },
  h1: { fontSize: '2.5rem', fontWeight: 700, lineHeight: 1.2, letterSpacing: '-0.025em' },
  h2: { fontSize: '2rem', fontWeight: 700, lineHeight: 1.2, letterSpacing: '-0.02em' },
  h3: { fontSize: '1.75rem', fontWeight: 700, lineHeight: 1.25, letterSpacing: '-0.02em' },
  h4: { fontSize: '1.5rem', fontWeight: 700, lineHeight: 1.3, letterSpacing: '-0.015em' },
  h5: { fontSize: '1.25rem', fontWeight: 600, lineHeight: 1.35, letterSpacing: '-0.01em' },
  h6: { fontSize: '1rem', fontWeight: 600, lineHeight: 1.4, letterSpacing: '-0.005em' },
} satisfies TypographyOptions;
