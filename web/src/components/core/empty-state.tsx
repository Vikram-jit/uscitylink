import * as React from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import type { Icon } from '@phosphor-icons/react/dist/lib/types';
import { ChatsCircle } from '@phosphor-icons/react/dist/ssr/ChatsCircle';

export interface EmptyStateProps {
  title: string;
  description?: string;
  icon?: Icon;
  action?: React.ReactNode;
}

// The one empty state used across the app: soft blue icon tile, title, one line of help
export function EmptyState({ title, description, icon: IconComponent = ChatsCircle, action }: EmptyStateProps): React.JSX.Element {
  return (
    <Box
      sx={{
        alignItems: 'center',
        display: 'flex',
        flex: 1,
        flexDirection: 'column',
        gap: 1.25,
        justifyContent: 'center',
        minHeight: 320,
        p: 4,
        textAlign: 'center',
        width: '100%',
      }}
    >
      <Box
        sx={{
          alignItems: 'center',
          backgroundColor: 'rgba(var(--mui-palette-primary-mainChannel) / 0.08)',
          borderRadius: '16px',
          color: 'primary.main',
          display: 'flex',
          height: 64,
          justifyContent: 'center',
          mb: 0.5,
          width: 64,
        }}
      >
        <IconComponent size={32} weight="duotone" />
      </Box>
      <Typography variant="h6">{title}</Typography>
      {description ? (
        <Typography color="text.secondary" sx={{ maxWidth: 340 }} variant="body2">
          {description}
        </Typography>
      ) : null}
      {action ? <Box sx={{ mt: 1 }}>{action}</Box> : null}
    </Box>
  );
}
