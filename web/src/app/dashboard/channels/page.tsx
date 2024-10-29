import * as React from 'react';
import type { Metadata } from 'next';
import { Container } from '@mui/material';
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import { config } from '@/config';
import AddChanelDialog from '@/components/dashboard/channels/AddChanelDialog';
import ChannelList from '@/components/dashboard/channels/ChannelList';

export const metadata = { title: `Channels | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page(): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
      <Stack spacing={3}>
        <Stack direction="row" spacing={3}>
          <Stack spacing={1} sx={{ flex: '1 1 auto' }}>
            <Typography variant="h4">Channels</Typography>
          </Stack>

          <div>
            <AddChanelDialog />
          </div>
        </Stack>
        <ChannelList />
      </Stack>
    </Container>
  );
}
