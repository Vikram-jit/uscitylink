import * as React from 'react';
import type { Metadata } from 'next';
import { Container } from '@mui/material';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import { config } from '@/config';
import MessageForm from '@/components/dashboard/broadcastMessage/message-form';
import MessageList from '@/components/dashboard/broadcastMessage/message-list';

export const metadata = { title: `Broadcast Messages | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page(): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
      <Stack spacing={3}>
        <Stack direction="row" spacing={3}>
          <Stack spacing={1} sx={{ flex: '1 1 auto' }}>
            <Typography variant="h5">Broadcast Messages</Typography>
          </Stack>
        
           
     
         
        </Stack>
      </Stack>
      <MessageForm/>
      <MessageList/>
    </Container>
  );
}
