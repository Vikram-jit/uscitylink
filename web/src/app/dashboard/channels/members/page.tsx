import * as React from 'react';
import type { Metadata } from 'next';
import { Search } from '@mui/icons-material';
import { Container, InputAdornment, TextField } from '@mui/material';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import { config } from '@/config';
import AddChanelMemberDialog from '@/components/dashboard/channels/members/AddMemberDialog';
import MemberList from '@/components/dashboard/channels/members/MemberList';
import SearchComponent from '@/components/SearchComponent';

export const metadata = { title: `Channels | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page(): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
      <Stack spacing={3}>
        <Stack direction="row" spacing={3}>
          <Stack spacing={1} sx={{ flex: '1 1 auto' }}>
            <Typography variant="h4">Channel Members</Typography>
          </Stack>

          <div
            style={{
              display: 'flex',
            }}
          >
           <SearchComponent/>
            <AddChanelMemberDialog />
          </div>
        </Stack>
        <MemberList />
      </Stack>
    </Container>
  );
}
