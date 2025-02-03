import * as React from 'react';
import type { Metadata } from 'next';

import { config } from '@/config';

import Training from '@/components/training/training';
import { Button, Container, Typography } from '@mui/material';
import { Stack } from '@mui/system';
import { paths } from '@/paths';

export const metadata = { title: `Trainings | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page(): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
      <Stack spacing={3}>
        <Stack direction="row" spacing={3}>
          <Stack spacing={1} sx={{ flex: '1 1 auto' }}>
            <Typography variant="h4">Training Videos</Typography>
          </Stack>

          <div
            style={{
              display: 'flex',
            }}
          >
          <Button LinkComponent={"a"} href={`${paths.dashboard.trainings}/add`} variant="contained">Add Training Video</Button>
          </div>
        </Stack>
            <Training/>
      </Stack>
    </Container>
  );
}
