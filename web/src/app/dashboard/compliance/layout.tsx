'use client';

import * as React from 'react';
import { usePathname } from 'next/navigation';
import { Container, Stack, Typography } from '@mui/material';

import { paths } from '@/paths';
import { StaffGuard } from '@/components/dashboard/automation/AdminGuard';

const TITLES: Record<string, { title: string; subtitle: string }> = {
  [paths.compliance.scaleChecks]: {
    title: 'Scale checks',
    subtitle: 'Every CAT scale ticket drivers send, checked against the route rules and equipment, and released by dispatch.',
  },
  [paths.compliance.equipment]: {
    title: 'Equipment',
    subtitle: 'Tractor and trailer measurements the scale agent needs for the bridge formula, trailer position and slide estimates.',
  },
};

export default function Layout({ children }: { children: React.ReactNode }): React.JSX.Element {
  const pathname = usePathname();
  const header = TITLES[pathname] || { title: 'Compliance', subtitle: '' };
  return (
    <Container maxWidth="xl" sx={{ py: '48px' }}>
      <StaffGuard>
        <Stack spacing={3}>
          <Stack spacing={0.5}>
            <Typography variant="h4">{header.title}</Typography>
            <Typography color="text.secondary" variant="body2">
              {header.subtitle}
            </Typography>
          </Stack>
          {children}
        </Stack>
      </StaffGuard>
    </Container>
  );
}
