import type { Components } from '@mui/material/styles';
import { outlinedInputClasses } from '@mui/material/OutlinedInput';

import type { Theme } from '../types';

const SOFT_TINTS: Record<string, { bg: string; fg: string }> = {
  default: { bg: 'var(--mui-palette-background-level2)', fg: 'var(--mui-palette-text-secondary)' },
  primary: { bg: 'rgba(var(--mui-palette-primary-mainChannel) / 0.1)', fg: 'var(--mui-palette-primary-dark)' },
  secondary: { bg: 'var(--mui-palette-background-level2)', fg: 'var(--mui-palette-text-primary)' },
  success: { bg: 'rgba(var(--mui-palette-success-mainChannel) / 0.12)', fg: 'var(--mui-palette-success-dark)' },
  warning: { bg: 'rgba(var(--mui-palette-warning-mainChannel) / 0.14)', fg: 'var(--mui-palette-warning-dark)' },
  error: { bg: 'rgba(var(--mui-palette-error-mainChannel) / 0.1)', fg: 'var(--mui-palette-error-dark)' },
  info: { bg: 'rgba(var(--mui-palette-info-mainChannel) / 0.12)', fg: 'var(--mui-palette-info-dark)' },
};

export const MuiChip = {
  styleOverrides: {
    // Status chips: small soft tints
    root: ({ ownerState }) => {
      const tint = SOFT_TINTS[ownerState.color || 'default'] ?? SOFT_TINTS.default;
      return {
        borderRadius: '6px',
        fontWeight: 600,
        fontSize: '0.75rem',
        ...(ownerState.variant === 'filled' && { backgroundColor: tint.bg, color: tint.fg, '& .MuiChip-icon': { color: tint.fg } }),
        ...(ownerState.variant === 'outlined' && { borderColor: 'var(--mui-palette-divider)' }),
      };
    },
    sizeSmall: { height: 22 },
  },
} satisfies Components<Theme>['MuiChip'];

export const MuiOutlinedInput = {
  styleOverrides: {
    root: {
      borderRadius: '8px',
      backgroundColor: 'var(--mui-palette-background-paper)',
      transition: 'box-shadow 0.15s ease',
      [`& .${outlinedInputClasses.notchedOutline}`]: { borderColor: 'var(--mui-palette-neutral-300)' },
      [`&:hover .${outlinedInputClasses.notchedOutline}`]: { borderColor: 'var(--mui-palette-neutral-400)' },
      [`&.${outlinedInputClasses.focused}`]: { boxShadow: '0 0 0 3px rgba(var(--mui-palette-primary-mainChannel) / 0.18)' },
      [`&.${outlinedInputClasses.focused} .${outlinedInputClasses.notchedOutline}`]: {
        borderColor: 'var(--mui-palette-primary-main)',
        borderWidth: '1px',
      },
    },
    input: { '&::placeholder': { color: 'var(--mui-palette-text-disabled)', opacity: 1 } },
  },
} satisfies Components<Theme>['MuiOutlinedInput'];

export const MuiInputLabel = {
  styleOverrides: { root: { color: 'var(--mui-palette-text-secondary)', fontWeight: 500 } },
} satisfies Components<Theme>['MuiInputLabel'];

export const MuiTabs = {
  styleOverrides: {
    root: { minHeight: 44, borderBottom: '1px solid var(--mui-palette-divider)' },
    indicator: { height: '2px', backgroundColor: 'var(--mui-palette-primary-main)' },
  },
} satisfies Components<Theme>['MuiTabs'];

export const MuiTableRow = {
  styleOverrides: {
    root: {
      transition: 'background-color 0.12s ease',
      '&.MuiTableRow-hover:hover': { backgroundColor: 'var(--mui-palette-background-level1)' },
      '&:last-of-type td': { borderBottom: 0 },
    },
  },
} satisfies Components<Theme>['MuiTableRow'];

export const MuiPaper = {
  styleOverrides: {
    rounded: { borderRadius: '12px' },
    outlined: { borderColor: 'var(--mui-palette-divider)' },
  },
} satisfies Components<Theme>['MuiPaper'];

export const MuiDialog = {
  styleOverrides: {
    paper: { borderRadius: '12px', boxShadow: '0 24px 48px -12px rgba(15, 23, 42, 0.25)', backgroundImage: 'none' },
  },
} satisfies Components<Theme>['MuiDialog'];

export const MuiDialogTitle = {
  styleOverrides: { root: { fontSize: '1.125rem', fontWeight: 600, letterSpacing: '-0.01em', padding: '20px 24px 8px' } },
} satisfies Components<Theme>['MuiDialogTitle'];

export const MuiDialogActions = {
  styleOverrides: { root: { padding: '12px 24px 20px', gap: '8px' } },
} satisfies Components<Theme>['MuiDialogActions'];

export const MuiTooltip = {
  defaultProps: { arrow: true },
  styleOverrides: {
    tooltip: { backgroundColor: '#0f172a', borderRadius: '6px', fontSize: '0.75rem', fontWeight: 500, padding: '6px 10px' },
    arrow: { color: '#0f172a' },
  },
} satisfies Components<Theme>['MuiTooltip'];

export const MuiAlert = {
  styleOverrides: { root: { borderRadius: '8px', alignItems: 'center' }, standard: { border: '1px solid transparent' } },
} satisfies Components<Theme>['MuiAlert'];

export const MuiLinearProgress = {
  styleOverrides: {
    root: { borderRadius: '99px', height: '6px', backgroundColor: 'var(--mui-palette-background-level2)' },
    bar: { borderRadius: '99px' },
  },
} satisfies Components<Theme>['MuiLinearProgress'];

export const MuiIconButton = {
  styleOverrides: {
    root: {
      borderRadius: '8px',
      color: 'var(--mui-palette-text-secondary)',
      '&:hover': { backgroundColor: 'var(--mui-palette-background-level2)', color: 'var(--mui-palette-text-primary)' },
    },
  },
} satisfies Components<Theme>['MuiIconButton'];

export const MuiToggleButton = {
  styleOverrides: { root: { borderRadius: '8px', textTransform: 'none', fontWeight: 600 } },
} satisfies Components<Theme>['MuiToggleButton'];

export const MuiPopover = {
  styleOverrides: {
    paper: { borderRadius: '10px', border: '1px solid var(--mui-palette-divider)', boxShadow: '0 12px 32px -8px rgba(15, 23, 42, 0.18)', backgroundImage: 'none' },
  },
} satisfies Components<Theme>['MuiPopover'];

export const MuiMenuItem = {
  styleOverrides: { root: { borderRadius: '6px', margin: '2px 6px', fontSize: '0.875rem', fontWeight: 500 } },
} satisfies Components<Theme>['MuiMenuItem'];

export const MuiDivider = {
  styleOverrides: { root: { borderColor: 'var(--mui-palette-divider)' } },
} satisfies Components<Theme>['MuiDivider'];

export const MuiListItemButton = {
  styleOverrides: { root: { '&.Mui-selected': { backgroundColor: 'rgba(var(--mui-palette-primary-mainChannel) / 0.08)' } } },
} satisfies Components<Theme>['MuiListItemButton'];

export const MuiSwitch = {
  styleOverrides: {
    switchBase: { '&.Mui-checked + .MuiSwitch-track': { opacity: 1 } },
    track: { borderRadius: 99, backgroundColor: 'var(--mui-palette-neutral-300)', opacity: 1 },
  },
} satisfies Components<Theme>['MuiSwitch'];
