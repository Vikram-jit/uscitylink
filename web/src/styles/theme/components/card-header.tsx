import type { Components } from '@mui/material/styles';

import type { Theme } from '../types';

export const MuiCardHeader = {
  defaultProps: { titleTypographyProps: { variant: 'h6' }, subheaderTypographyProps: { variant: 'body2' } },
  styleOverrides: {
    root: { padding: '20px 24px 12px' },
    subheader: { marginTop: '2px', color: 'var(--mui-palette-text-secondary)' },
    action: { marginTop: 0, marginRight: 0, alignSelf: 'center' },
  },
} satisfies Components<Theme>['MuiCardHeader'];
