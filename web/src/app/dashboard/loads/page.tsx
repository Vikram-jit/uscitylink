'use client';

import * as React from 'react';
import { Container, Stack, Typography } from '@mui/material';

import { StaffGuard } from '@/components/dashboard/automation/AdminGuard';
import { LoadsBoard } from '@/components/dashboard/trips/LoadsBoard';

export default function Page(): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '48px' }}>
      <StaffGuard>
        <Stack spacing={3}>
          <Stack spacing={0.5}>
            <Typography variant="h4">Loads</Typography>
            <Typography color="text.secondary" variant="body2">
              Line up and send loads to drivers. Each load is a trip the driver runs from the app (Got it → Rolling → Delivered).
              When you mark it completed, its entry is created in the yard's Route List for pay.
            </Typography>
          </Stack>
          <LoadsBoard />
        </Stack>
      </StaffGuard>
    </Container>
  );
}
