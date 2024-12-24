"use client"
import * as React from 'react';

import { Container, Typography } from '@mui/material';
import Grid from '@mui/material/Unstable_Grid2';

import { config } from '@/config';
import { Budget } from '@/components/dashboard/overview/budget';
import { Sales } from '@/components/dashboard/overview/sales';
import { TasksProgress } from '@/components/dashboard/overview/tasks-progress';
import { TotalCustomers } from '@/components/dashboard/overview/total-customers';
import { TotalProfit } from '@/components/dashboard/overview/total-profit';
import { useDashbaordQuery } from '@/redux/UserApiSlice';
import { UnreadMessage } from './overview/unread-messages';
import { LatestOrders } from './overview/latest-orders';


export default function Dashboard(): React.JSX.Element {

  const {data,isLoading} = useDashbaordQuery()
    
  if(isLoading){
    return <Typography>Loading...</Typography>
  }
  return (
    <Container maxWidth="xl" sx={{ py: '64px' }}>
      <Grid container spacing={3}>
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
