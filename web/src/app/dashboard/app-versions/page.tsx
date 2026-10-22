'use client';

import * as React from 'react';
import { Container, Stack, Typography } from '@mui/material';

import { AdminGuard } from '@/components/dashboard/automation/AdminGuard';
import { AppVersions } from '@/components/dashboard/app-versions/AppVersions';

export default function Page(): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '48px' }}>
      <AdminGuard>
        <Stack spacing={3}>
          <Stack spacing={0.5}>
            <Typography variant="h4">App versions</Typography>
            <Typography color="text.secondary" variant="body2">
              Which driver / staff app builds count as up to date on Android and iOS.
            </Typography>
          </Stack>
          <AppVersions />
        </Stack>
      </AdminGuard>
    </Container>
  );
}
