import * as React from 'react';
import type { Metadata } from 'next';
import { ArrowBack } from '@mui/icons-material';
import { Container, IconButton } from '@mui/material';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import { config } from '@/config';
import { paths } from '@/paths';
import EditTraining from '@/components/training/EditTraining';

export const metadata = { title: `Training Edit | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page({ params }: { params: { id: string } }): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
      <Stack spacing={3}>
        <div>
          <IconButton LinkComponent="a" href={`${paths.dashboard.trainings}`}>
            <ArrowBack />
            <Typography variant="h6"> Training</Typography>
          </IconButton>
        </div>
      </Stack>
      <EditTraining id={params.id} />
    </Container>
  );
}
