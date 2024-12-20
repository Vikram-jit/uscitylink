import * as React from 'react';
import type { Metadata } from 'next';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import { config } from '@/config';

import { Container, IconButton } from '@mui/material';
import { ArrowBack } from '@mui/icons-material';
import { paths } from '@/paths';
import { UserAddForm } from '@/components/dashboard/users/UserAddForm';
import { UserEditForm } from '@/components/dashboard/users/UserEditForm';

export const metadata = { title: `User Edit | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page({params}:{params:{role:string,id:string}}): React.JSX.Element {
  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
    <Stack spacing={3}>
      <div>
        <IconButton LinkComponent="a" href={`${paths.dashboard.users}/${params.role}`}>
        <ArrowBack/>
       <Typography variant="h6"> User</Typography>
        </IconButton>

      </div>
      {/* <div>
        <Typography variant="h4">Update {params.role?.[0]?.toUpperCase() + params.role?.substring(1)}</Typography>
      </div> */}

      <UserEditForm  role={params.role} id={params.id}/>
    </Stack>
    </Container>
  );
}
