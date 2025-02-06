import * as React from 'react';
import type { Metadata } from 'next';

import { config } from '@/config';

import Training from '@/components/training/training';
import { Button, Container, IconButton, Typography } from '@mui/material';
import { Stack } from '@mui/system';
import { paths } from '@/paths';
import AssginDriver from '@/components/training/assginDriver';
import { ArrowBack } from '@mui/icons-material';

export const metadata = { title: `Trainings | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page({ params }: { params: { id: string } }): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
      <Stack spacing={3}>
        <Stack direction="row" spacing={3}>
          <Stack spacing={1} sx={{ flex: '1 1 auto' }}>
            <Typography variant="h4">Assgined Drivers</Typography>
          </Stack>

          <div
            style={{
              display: 'flex',
            }}
          >
 <IconButton LinkComponent="a" href={`${paths.dashboard.trainings}`}>
            <ArrowBack />
            <Typography variant="h6"> Training</Typography>
          </IconButton>
          </div>
        </Stack>
            <AssginDriver  id={params.id}/>
      </Stack>
    </Container>
  );
}
