import type { Components } from '@mui/material/styles';

import type { Theme } from '../types';

export const MuiTab = {
  styleOverrides: {
    root: {
      fontSize: '0.875rem',
      fontWeight: 600,
      lineHeight: 1.5,
      minHeight: 44,
      minWidth: 'auto',
      paddingLeft: 0,
      paddingRight: 0,
      textTransform: 'none',
      color: 'var(--mui-palette-text-secondary)',
      '&:hover': { color: 'var(--mui-palette-text-primary)' },
      '&.Mui-selected': { color: 'var(--mui-palette-primary-main)' },
      '& + &': { marginLeft: '24px' },
    },
  },
} satisfies Components<Theme>['MuiTab'];
