'use client';

import * as React from 'react';
import { Alert, Box, CircularProgress } from '@mui/material';

import { useGetAutomationMeQuery } from '@/redux/AutomationApiSlice';

export function AdminGuard({ children }: { children: React.ReactNode }): React.JSX.Element {
  const { data, isLoading } = useGetAutomationMeQuery();

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
        <CircularProgress />
      </Box>
    );
  }
  if (!data?.data?.isAdmin) {
    return <Alert severity="warning">Automation is only available to admins.</Alert>;
  }
  return <>{children}</>;
}
