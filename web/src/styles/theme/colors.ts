import type { PaletteRange } from '@mui/material/styles/createPalette';

export const california = {
  50: '#fffaea',
  100: '#fff3c6',
  200: '#ffe587',
  300: '#ffd049',
  400: '#ffbb1f',
  500: '#fb9c0c',
  600: '#de7101',
  700: '#b84d05',
  800: '#953b0b',
  900: '#7b310c',
  950: '#471701',
} satisfies PaletteRange;

export const kepple = {
  50: '#f0fdfa',
  100: '#ccfbef',
  200: '#9af5e1',
  300: '#5fe9ce',
  400: '#2ed3b8',
  500: '#15b79f',
  600: '#0e9382',
  700: '#107569',
  800: '#115e56',
  900: '#134e48',
  950: '#042f2c',
} satisfies PaletteRange;

export const neonBlue = {
  50: '#ecf0ff',
  100: '#dde3ff',
  200: '#c2cbff',
  300: '#9ca7ff',
  400: '#7578ff',
  500: '#635bff',
  600: '#4e36f5',
  700: '#432ad8',
  800: '#3725ae',
  900: '#302689',
  950: '#1e1650',
} satisfies PaletteRange;

export const nevada = {
  50: '#fbfcfe',
  100: '#f0f4f8',
  200: '#dde7ee',
  300: '#cdd7e1',
  400: '#9fa6ad',
  500: '#636b74',
  600: '#555e68',
  700: '#32383e',
  800: '#202427',
  900: '#121517',
  950: '#090a0b',
} satisfies PaletteRange;

export const redOrange = {
  50: '#fef3f2',
  100: '#fee4e2',
  200: '#ffcdc9',
  300: '#fdaaa4',
  400: '#f97970',
  500: '#f04438',
  600: '#de3024',
  700: '#bb241a',
  800: '#9a221a',
  900: '#80231c',
  950: '#460d09',
} satisfies PaletteRange;

export const shakespeare = {
  50: '#ecfdff',
  100: '#cff7fe',
  200: '#a4eefd',
  300: '#66e0fa',
  400: '#10bee8',
  500: '#04aad6',
  600: '#0787b3',
  700: '#0d6d91',
  800: '#145876',
  900: '#154964',
  950: '#082f44',
} satisfies PaletteRange;

export const stormGrey = {
  50: '#f9fafb',
  100: '#f1f1f4',
  200: '#dcdfe4',
  300: '#b3b9c6',
  400: '#8a94a6',
  500: '#667085',
  600: '#565e73',
  700: '#434a60',
  800: '#313749',
  900: '#212636',
  950: '#121621',
} satisfies PaletteRange;

// ---------------------------------------------------------------------------
// USCityLink design system: "Clean enterprise"
// Slate neutrals + one blue accent. Status colors are used only for meaning.
// ---------------------------------------------------------------------------

export const slate = {
  50: '#f8fafc',
  100: '#f1f5f9',
  200: '#e2e8f0',
  300: '#cbd5e1',
  400: '#94a3b8',
  500: '#64748b',
  600: '#475569',
  700: '#334155',
  800: '#1e293b',
  900: '#0f172a',
  950: '#020617',
} satisfies PaletteRange;

export const blue = {
  50: '#eff6ff',
  100: '#dbeafe',
  200: '#bfdbfe',
  300: '#93c5fd',
  400: '#60a5fa',
  500: '#3b82f6',
  600: '#2563eb',
  700: '#1d4ed8',
  800: '#1e40af',
  900: '#1e3a8a',
  950: '#172554',
} satisfies PaletteRange;

export const green = {
  50: '#f0fdf4',
  100: '#dcfce7',
  200: '#bbf7d0',
  300: '#86efac',
  400: '#4ade80',
  500: '#22c55e',
  600: '#16a34a',
  700: '#15803d',
  800: '#166534',
  900: '#14532d',
  950: '#052e16',
} satisfies PaletteRange;

export const amber = {
  50: '#fffbeb',
  100: '#fef3c7',
  200: '#fde68a',
  300: '#fcd34d',
  400: '#fbbf24',
  500: '#f59e0b',
  600: '#d97706',
  700: '#b45309',
  800: '#92400e',
  900: '#78350f',
  950: '#451a03',
} satisfies PaletteRange;

export const red = {
  50: '#fef2f2',
  100: '#fee2e2',
  200: '#fecaca',
  300: '#fca5a5',
  400: '#f87171',
  500: '#ef4444',
  600: '#dc2626',
  700: '#b91c1c',
  800: '#991b1b',
  900: '#7f1d1d',
  950: '#450a0a',
} satisfies PaletteRange;

export const sky = {
  50: '#f0f9ff',
  100: '#e0f2fe',
  200: '#bae6fd',
  300: '#7dd3fc',
  400: '#38bdf8',
  500: '#0ea5e9',
  600: '#0284c7',
  700: '#0369a1',
  800: '#075985',
  900: '#0c4a6e',
  950: '#082f49',
} satisfies PaletteRange;

// Kept for components that import it; enterprise style uses flat colors, not gradients
export const gradients = {
  brand: '#2563eb',
  nav: 'var(--mui-palette-background-paper)',
  hero: 'linear-gradient(135deg, #1d4ed8 0%, #2563eb 55%, #3b82f6 100%)',
  glow: '0 1px 2px rgba(15, 23, 42, 0.08)',
} as const;
