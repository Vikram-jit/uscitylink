import * as React from 'react';
import type { Metadata } from 'next';
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import { Plus as PlusIcon } from '@phosphor-icons/react/dist/ssr/Plus';

import { config } from '@/config';
import { Container, IconButton } from '@mui/material';
import Template from '@/components/dashboard/template/template';
import { ArrowBackIos } from '@mui/icons-material';

export const metadata = { title: `Template | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page({params}:{params:{action:string}}): React.JSX.Element {

  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
    <Stack spacing={3}>
      <Stack direction="row" spacing={3}>
        <Stack display={"flex"} flexDirection={"row"}>
          <IconButton LinkComponent={'a'} href={'/dashboard/templates'}>
            <ArrowBackIos/>
          </IconButton>
          <Typography variant="h4">{`${params.action?.toUpperCase()}`}</Typography>
        </Stack>
      </Stack>
      <Template/>
    </Stack>
    </Container>
  );
}

