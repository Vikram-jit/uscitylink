'use client';

import * as React from 'react';
import { Container, Stack, Typography } from '@mui/material';

import { StaffGuard } from '@/components/dashboard/automation/AdminGuard';
import { LoadsHome } from '@/components/dashboard/trips/LoadsHome';

export default function Page(): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '48px' }}>
      <StaffGuard>
        <Stack spacing={3}>
          <Stack spacing={0.5}>
            <Typography variant="h4">Loads</Typography>
            <Typography color="text.secondary" variant="body2">
              Every load is tracked by its invoice #. A load goes direct, through our yard, or by relay — each leg is run by one
              driver from the app (Got it → Rolling → Delivered). See which trucks, trailers and drivers are free on the second tab.
            </Typography>
          </Stack>
          <LoadsHome />
        </Stack>
      </StaffGuard>
    </Container>
  );
}
