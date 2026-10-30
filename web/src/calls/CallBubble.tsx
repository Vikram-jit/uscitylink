'use client';

import * as React from 'react';
import { Box, Stack, Typography } from '@mui/material';
import { PhoneIncoming, PhoneOutgoing, PhoneX } from '@phosphor-icons/react';

import { formatUtcTime } from '@/components/messages/utils';

/**
 * The call-log message ("Voice call · 3:42", "Missed voice call") shown in place of a chat bubble.
 * `sent` = dispatch placed the call (message direction "S").
 */
export function CallBubble({ body, sent, time }: { body: string; sent: boolean; time?: string | Date }): React.JSX.Element {
  const missed = /^(Missed|Declined)|failed/i.test(body);
  const Icon = missed ? PhoneX : sent ? PhoneOutgoing : PhoneIncoming;
  return (
    <Stack alignItems={sent ? 'flex-end' : 'flex-start'} sx={{ width: '100%', my: 0.5 }}>
      <Box
        sx={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: 1.25,
          px: 1.75,
          py: 1,
          borderRadius: 3,
          border: 1,
          borderColor: missed ? 'error.light' : 'divider',
          bgcolor: missed ? 'rgba(240, 68, 56, 0.06)' : 'background.paper',
        }}
      >
        <Box
          sx={{
            width: 32,
            height: 32,
            borderRadius: '50%',
            display: 'grid',
            placeItems: 'center',
            bgcolor: missed ? 'error.main' : 'success.main',
            color: '#fff',
            flexShrink: 0,
          }}
        >
          <Icon size={16} weight="bold" />
        </Box>
        <Box>
          <Typography sx={{ fontWeight: 600 }} variant="body2">
            {body}
          </Typography>
          <Typography color="text.secondary" variant="caption">
            {sent ? 'Dispatch called' : 'Driver called'}
            {time ? ` · ${formatUtcTime(time as any)}` : ''}
          </Typography>
        </Box>
      </Box>
    </Stack>
  );
}
