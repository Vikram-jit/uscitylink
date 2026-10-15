import type { ColorSystemOptions } from '@mui/material/styles';

import { amber, blue, green, red, sky, slate } from './colors';
import type { ColorScheme } from './types';

export const colorSchemes = {
  dark: {
    palette: {
      action: { disabledBackground: 'rgba(148, 163, 184, 0.12)' },
      background: {
        default: '#0b1120',
        defaultChannel: '11 17 32',
        paper: '#0f172a',
        paperChannel: '15 23 42',
        level1: '#131c31',
        level2: '#1e293b',
        level3: '#334155',
      },
      common: { black: '#000000', white: '#ffffff' },
      divider: '#1e293b',
      dividerChannel: '30 41 59',
      error: { ...red, light: red[300], main: red[400], dark: red[500], contrastText: '#0f172a' },
      info: { ...sky, light: sky[300], main: sky[400], dark: sky[500], contrastText: '#0f172a' },
      neutral: { ...slate },
      primary: { ...blue, light: blue[400], main: blue[500], dark: blue[600], contrastText: '#ffffff' },
      secondary: { ...slate, light: slate[200], main: slate[300], dark: slate[400], contrastText: '#0f172a' },
      success: { ...green, light: green[300], main: green[400], dark: green[500], contrastText: '#0f172a' },
      text: {
        primary: '#f1f5f9',
        primaryChannel: '241 245 249',
        secondary: '#94a3b8',
        secondaryChannel: '148 163 184',
        disabled: '#475569',
      },
      warning: { ...amber, light: amber[300], main: amber[400], dark: amber[500], contrastText: '#0f172a' },
    },
  },
  light: {
    palette: {
      action: { disabledBackground: 'rgba(15, 23, 42, 0.06)' },
      background: {
        default: '#f8fafc',
        defaultChannel: '248 250 252',
        paper: '#ffffff',
        paperChannel: '255 255 255',
        level1: '#f8fafc',
        level2: '#f1f5f9',
        level3: '#e2e8f0',
      },
      common: { black: '#000000', white: '#ffffff' },
      divider: '#e2e8f0',
      dividerChannel: '226 232 240',
      error: { ...red, light: red[500], main: red[600], dark: red[700], contrastText: '#ffffff' },
      info: { ...sky, light: sky[500], main: sky[600], dark: sky[700], contrastText: '#ffffff' },
      neutral: { ...slate },
      primary: { ...blue, light: blue[500], main: blue[600], dark: blue[700], contrastText: '#ffffff' },
      secondary: { ...slate, light: slate[500], main: slate[600], dark: slate[700], contrastText: '#ffffff' },
      success: { ...green, light: green[500], main: green[600], dark: green[700], contrastText: '#ffffff' },
      text: {
        primary: '#0f172a',
        primaryChannel: '15 23 42',
        secondary: '#64748b',
        secondaryChannel: '100 116 139',
        disabled: '#94a3b8',
      },
      warning: { ...amber, light: amber[500], main: amber[600], dark: amber[700], contrastText: '#ffffff' },
    },
  },
} satisfies Partial<Record<ColorScheme, ColorSystemOptions>>;
