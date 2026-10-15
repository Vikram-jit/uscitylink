import type { Components } from '@mui/material/styles';

import type { Theme } from '../types';

export const MuiTableCell = {
  styleOverrides: {
    root: {
      borderBottom: '1px solid var(--mui-palette-divider)',
      fontSize: '0.875rem',
      paddingTop: '12px',
      paddingBottom: '12px',
    },
    paddingCheckbox: { padding: '0 0 0 24px' },
  },
} satisfies Components<Theme>['MuiTableCell'];
