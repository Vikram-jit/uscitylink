import * as React from 'react';
import type { Metadata } from 'next';
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import { Plus as PlusIcon } from '@phosphor-icons/react/dist/ssr/Plus';

import { config } from '@/config';
import UserList from '@/components/dashboard/users/UserList';
import { Container } from '@mui/material';

export const metadata = { title: `Users | Dashboard | ${config.site.name}` } satisfies Metadata;



export default function Page(): React.JSX.Element {


  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
    <Stack spacing={3}>
      <Stack direction="row" spacing={3}>
        <Stack spacing={1} sx={{ flex: '1 1 auto' }}>
          <Typography variant="h4">Users</Typography>
        </Stack>
        <div>
          <Button startIcon={<PlusIcon fontSize="var(--icon-fontSize-md)" />} variant="contained">
            Add
          </Button>
        </div>
      </Stack>
      <UserList/>
    </Stack>
    </Container>
  );
}

