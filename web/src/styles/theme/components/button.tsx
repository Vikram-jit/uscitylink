import type { Components } from '@mui/material/styles';

import type { Theme } from '../types';

const focusRing = '0 0 0 3px rgba(var(--mui-palette-primary-mainChannel) / 0.25)';

export const MuiButton = {
  defaultProps: { disableElevation: true },
  styleOverrides: {
    root: {
      borderRadius: '8px',
      textTransform: 'none',
      fontWeight: 600,
      whiteSpace: 'nowrap',
      transition: 'background-color 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease, color 0.15s ease',
      '&.Mui-focusVisible': { boxShadow: focusRing },
    },
    sizeSmall: { padding: '5px 12px', fontSize: '0.8125rem' },
    sizeMedium: { padding: '8px 16px' },
    sizeLarge: { padding: '11px 22px', fontSize: '0.9375rem' },
    textSizeSmall: { padding: '5px 10px' },
    textSizeMedium: { padding: '8px 12px' },
    textSizeLarge: { padding: '11px 16px' },
    contained: {
      boxShadow: '0 1px 2px rgba(15, 23, 42, 0.08)',
      '&:hover': { boxShadow: '0 1px 2px rgba(15, 23, 42, 0.12)' },
      '&.Mui-disabled': { backgroundColor: 'var(--mui-palette-action-disabledBackground)', color: 'var(--mui-palette-text-disabled)', boxShadow: 'none' },
    },
    containedPrimary: { '&:hover': { backgroundColor: 'var(--mui-palette-primary-dark)' } },
    // Outlined = the standard secondary button: white, slate border, slate text
    outlined: {
      backgroundColor: 'var(--mui-palette-background-paper)',
      borderColor: 'var(--mui-palette-neutral-300)',
      color: 'var(--mui-palette-text-primary)',
      boxShadow: '0 1px 2px rgba(15, 23, 42, 0.05)',
      '&:hover': { backgroundColor: 'var(--mui-palette-background-level2)', borderColor: 'var(--mui-palette-neutral-300)' },
    },
    outlinedError: { color: 'var(--mui-palette-error-main)', borderColor: 'rgba(var(--mui-palette-error-mainChannel) / 0.4)' },
    text: { color: 'var(--mui-palette-text-secondary)', '&:hover': { backgroundColor: 'var(--mui-palette-background-level2)', color: 'var(--mui-palette-text-primary)' } },
    textPrimary: { color: 'var(--mui-palette-primary-main)', '&:hover': { backgroundColor: 'rgba(var(--mui-palette-primary-mainChannel) / 0.08)', color: 'var(--mui-palette-primary-dark)' } },
    textError: { color: 'var(--mui-palette-error-main)' },
  },
} satisfies Components<Theme>['MuiButton'];
