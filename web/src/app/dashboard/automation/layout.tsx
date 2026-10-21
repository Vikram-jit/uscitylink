'use client';

import * as React from 'react';
import RouterLink from 'next/link';
import { usePathname } from 'next/navigation';
import { Container, Stack, Tab, Tabs, Typography } from '@mui/material';

import { paths } from '@/paths';
import { AutomationGuard, ReadOnlyBanner } from '@/components/dashboard/automation/AdminGuard';

const TABS = [
  { label: 'Overview', href: paths.dashboard.automation },
  { label: 'Flows', href: paths.automation.flows },
  { label: 'Document types', href: paths.automation.docTypes },
  { label: 'Run log', href: paths.automation.runs },
  { label: 'Review', href: paths.automation.review },
  { label: 'Usage & cost', href: paths.automation.usage },
  { label: 'Settings', href: paths.automation.settings },
];

export default function Layout({ children }: { children: React.ReactNode }): React.JSX.Element {
  const pathname = usePathname();
  const current =
    [...TABS].reverse().find((t) => pathname === t.href || pathname.startsWith(`${t.href}/`))?.href ??
    paths.dashboard.automation;

  return (
    <Container maxWidth="xl" sx={{ py: '48px' }}>
      <AutomationGuard>
        <Stack spacing={3}>
          <Stack spacing={0.5}>
            <Typography variant="h4">Automation</Typography>
            <Typography color="text.secondary" variant="body2">
              Read driver paperwork automatically and act on it with if/then flows.
            </Typography>
          </Stack>
          <Tabs value={current} variant="scrollable">
            {TABS.map((t) => (
              <Tab component={RouterLink} href={t.href} key={t.href} label={t.label} value={t.href} />
            ))}
          </Tabs>
          <ReadOnlyBanner />
          {children}
        </Stack>
      </AutomationGuard>
    </Container>
  );
}
