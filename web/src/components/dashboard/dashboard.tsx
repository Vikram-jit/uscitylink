"use client"
import * as React from 'react';

import { Box, Button, Container, Stack, Typography } from '@mui/material';
import { ChatCircleText as ChatIcon } from '@phosphor-icons/react/dist/ssr/ChatCircleText';
import Grid from '@mui/material/Unstable_Grid2';

import { config } from '@/config';
import { Budget } from '@/components/dashboard/overview/budget';
import { Sales } from '@/components/dashboard/overview/sales';
import { TasksProgress } from '@/components/dashboard/overview/tasks-progress';
import { TotalCustomers } from '@/components/dashboard/overview/total-customers';
import { TotalProfit } from '@/components/dashboard/overview/total-profit';
import { useDashbaordQuery, useGetProfileQuery } from '@/redux/UserApiSlice';
import { paths } from '@/paths';
import { UnreadMessage } from './overview/unread-messages';
import { LatestOrders } from './overview/latest-orders';


const greeting = (): string => {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
};

function Hero({ name, unread }: { name: string; unread: number }): React.JSX.Element {
  return (
    <Stack
      alignItems={{ xs: 'flex-start', md: 'center' }}
      direction={{ xs: 'column', md: 'row' }}
      justifyContent="space-between"
      spacing={2}
    >
      <Box>
        <Typography variant="h4">
          {greeting()}, {name}
        </Typography>
        <Typography color="text.secondary" sx={{ mt: 0.5 }} variant="body1">
          {unread > 0
            ? `${unread} driver message${unread === 1 ? ' is' : 's are'} waiting for a reply.`
            : "You're all caught up. Here's what's happening across the fleet."}
        </Typography>
      </Box>
      <Stack direction="row" spacing={1.5}>
        <Button href={`${paths.dashboard.users}/driver`} variant="outlined">
          View drivers
        </Button>
        <Button href={paths.dashboard.messages} startIcon={<ChatIcon size={18} />} variant="contained">
          Open messages
        </Button>
      </Stack>
    </Stack>
  );
}

export default function Dashboard(): React.JSX.Element {
  const { data: profile } = useGetProfileQuery();

  const {data,isLoading} = useDashbaordQuery()
    
  if(isLoading){
    return <Typography>Loading...</Typography>
  }
  return (
    <Container maxWidth="xl" sx={{ py: '32px' }}>
      <Grid container spacing={3}>
        <Grid xs={12}>
          <Hero name={profile?.data?.username?.split(' ')[0] || 'there'} unread={Number(data?.data?.userUnMessage) || 0} />
        </Grid>
        <Grid lg={3} sm={6} xs={12}>
          <Budget diff={12} trend="up" sx={{ height: '100%' }} value={data?.data?.channelCount?.toString() || ''} />
        </Grid>
        <Grid lg={3} sm={6} xs={12}>
          <TotalCustomers diff={16} trend="down" sx={{ height: '100%' }} value={data?.data?.messageCount?.toString() || ''} />
        </Grid>
        <Grid lg={3} sm={6} xs={12}>
          <TasksProgress sx={{ height: '100%' }} value={data?.data?.userUnMessage || 0} />
        </Grid>
        <Grid lg={3} sm={6} xs={12}>
          <TotalProfit sx={{ height: '100%' }} value={data?.data?.groupCount?.toString() || ''} />
        </Grid>
        {/* <Grid lg={8} xs={12}>
          <Sales
            chartSeries={[
              { name: 'This year', data: [18, 16, 5, 8, 3, 14, 14, 16, 17, 19, 18, 20] },
              { name: 'Last year', data: [12, 11, 4, 6, 2, 9, 9, 10, 11, 12, 13, 13] },
            ]}
            sx={{ height: '100%' }}
          />
        </Grid>
        <Grid lg={4} md={6} xs={12}>
          <Traffic chartSeries={[63, 15, 22]} labels={['Desktop', 'Tablet', 'Phone']} sx={{ height: '100%' }} />
        </Grid> */}
       <Grid lg={4} md={6} xs={12}>
        <UnreadMessage
          messages={data?.data?.userUnReadMessage || []}
          sx={{ height: '100%' }}
        />
      </Grid>
      <Grid lg={8} md={12} xs={12}>
        <LatestOrders
          orders={data?.data?.lastFiveDriver || []}
          sx={{ height: '100%' }}
        />
      </Grid> 
      </Grid>
    </Container>
  );
}
