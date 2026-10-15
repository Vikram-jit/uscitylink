import * as React from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import { ChatsCircle } from '@phosphor-icons/react/dist/ssr/ChatsCircle';

// Shown in the right-hand pane until a conversation is picked
export default function EmptyChat(): React.JSX.Element {
  return (
    <Box
      sx={{
        display: { xs: 'none', sm: 'flex' },
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 1.5,
        textAlign: 'center',
        p: 4,
        height: { sm: 'calc(100vh - 5vh)', md: '92vh' },
        backgroundColor: 'var(--mui-palette-background-level1)',
      }}
    >
      <Box
        sx={{
          width: 64,
          height: 64,
          borderRadius: '16px',
          display: 'grid',
          placeItems: 'center',
          backgroundColor: 'rgba(var(--mui-palette-primary-mainChannel) / 0.08)',
          color: 'var(--mui-palette-primary-main)',
        }}
      >
        <ChatsCircle size={32} weight="duotone" />
      </Box>
      <Typography variant="h6">Select a conversation</Typography>
      <Typography color="text.secondary" sx={{ maxWidth: 320 }} variant="body2">
        Pick a driver from the list to read their messages, photos and documents, and reply right here.
      </Typography>
    </Box>
  );
}
