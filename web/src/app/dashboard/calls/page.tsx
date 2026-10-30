'use client';

import * as React from 'react';
import { Container, Stack, Typography } from '@mui/material';

import { StaffGuard } from '@/components/dashboard/automation/AdminGuard';
import { CallHistory } from '@/components/dashboard/calls/CallHistory';

export default function Page(): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '48px' }}>
      <StaffGuard>
        <Stack spacing={3}>
          <Stack spacing={0.5}>
            <Typography variant="h4">Calls</Typography>
            <Typography color="text.secondary" variant="body2">
              Voice calls between dispatch and drivers.
            </Typography>
          </Stack>
          <CallHistory />
        </Stack>
      </StaffGuard>
    </Container>
  );
}
