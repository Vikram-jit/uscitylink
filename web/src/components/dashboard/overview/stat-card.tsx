import * as React from 'react';
import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import Chip from '@mui/material/Chip';
import Stack from '@mui/material/Stack';
import type { SxProps } from '@mui/material/styles';
import Typography from '@mui/material/Typography';
import type { Icon } from '@phosphor-icons/react/dist/lib/types';

export interface StatCardProps {
  label: string;
  value: React.ReactNode;
  icon: Icon;
  tone?: 'light' | 'dark';
  caption?: string;
  captionColor?: 'success' | 'warning' | 'default' | 'primary';
  progress?: number;
  sx?: SxProps;
}

export function StatCard({ label, value, icon: IconComponent, caption, captionColor = 'default', sx }: StatCardProps): React.JSX.Element {
  return (
    <Card sx={{ height: '100%', ...sx }}>
      <Stack spacing={2} sx={{ p: 2.5 }}>
        <Stack alignItems="center" direction="row" justifyContent="space-between">
          <Typography sx={{ color: 'text.secondary', fontSize: 13.5, fontWeight: 500 }}>{label}</Typography>
          <Box
            sx={{
              alignItems: 'center',
              backgroundColor: 'rgba(var(--mui-palette-primary-mainChannel) / 0.08)',
              borderRadius: '8px',
              color: 'primary.main',
              display: 'flex',
              height: 34,
              justifyContent: 'center',
              width: 34,
            }}
          >
            <IconComponent size={19} />
          </Box>
        </Stack>
        <Stack alignItems="flex-end" direction="row" justifyContent="space-between" spacing={1}>
          <Typography sx={{ color: 'text.primary', fontSize: 30, fontWeight: 700, letterSpacing: '-0.025em', lineHeight: 1 }}>{value}</Typography>
          {caption ? <Chip color={captionColor} label={caption} size="small" /> : null}
        </Stack>
      </Stack>
    </Card>
  );
}
