import { paperClasses } from '@mui/material/Paper';
import type { Components } from '@mui/material/styles';

import type { Theme } from '../types';

export const MuiCard = {
  styleOverrides: {
    root: {
      borderRadius: '12px',
      [`&.${paperClasses.elevation1}`]: {
        border: '1px solid var(--mui-palette-divider)',
        boxShadow: '0 1px 2px rgba(15, 23, 42, 0.04)',
      },
    },
  },
} satisfies Components<Theme>['MuiCard'];
