import type { Components } from '@mui/material/styles';
import { tableCellClasses } from '@mui/material/TableCell';

import type { Theme } from '../types';

export const MuiTableHead = {
  styleOverrides: {
    root: {
      [`& .${tableCellClasses.root}`]: {
        backgroundColor: 'var(--mui-palette-background-level1)',
        borderBottom: '1px solid var(--mui-palette-divider)',
        color: 'var(--mui-palette-text-secondary)',
        fontSize: '0.75rem',
        fontWeight: 600,
        letterSpacing: '0.04em',
        lineHeight: 1,
        paddingBottom: '12px',
        paddingTop: '12px',
        textTransform: 'uppercase',
        whiteSpace: 'nowrap',
      },
    },
  },
} satisfies Components<Theme>['MuiTableHead'];
