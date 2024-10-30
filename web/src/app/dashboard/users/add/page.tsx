import * as React from 'react';
import type { Metadata } from 'next';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import { config } from '@/config';

import { Container, IconButton } from '@mui/material';
import { ArrowBack } from '@mui/icons-material';
import { paths } from '@/paths';
import { UserAddForm } from '@/components/dashboard/users/UserAddForm';

export const metadata = { title: `User Create | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page(): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
    <Stack spacing={3}>
      <div>
        <IconButton LinkComponent="a" href={paths.dashboard.users}>
        <ArrowBack/>
       <Typography variant="h6"> Users</Typography>
        </IconButton>

      </div>
      <div>
        <Typography variant="h4">Create user</Typography>
      </div>

      <UserAddForm />
    </Stack>
    </Container>
  );
}
