import * as React from 'react';
import type { Metadata } from 'next';
import { Container } from '@mui/material';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import { config } from '@/config';
import GroupList from '@/components/dashboard/groups/GroupList';
import AddGroupDialog from '@/components/dashboard/groups/AddGroupDialog';

export const metadata = { title: `Groups | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page(): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
      <Stack spacing={3}>
        <Stack direction="row" spacing={3}>
          <Stack spacing={1} sx={{ flex: '1 1 auto' }}>
            <Typography variant="h4">Groups</Typography>
          </Stack>

          <div>
            <AddGroupDialog />
          </div>
        </Stack>
        <GroupList />
      </Stack>
    </Container>
  );
}
