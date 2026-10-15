import type { Components } from '@mui/material/styles';

import type { Theme } from '../types';

export const MuiAvatar = {
  styleOverrides: {
    root: { fontSize: '0.875rem', fontWeight: 600, letterSpacing: 0 },
    // Initials / fallback icon on a soft blue tile
    colorDefault: { backgroundColor: 'var(--mui-palette-primary-100)', color: 'var(--mui-palette-primary-700)' },
  },
} satisfies Components<Theme>['MuiAvatar'];
