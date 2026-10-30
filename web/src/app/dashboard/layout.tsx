import * as React from 'react';
import Box from '@mui/material/Box';
import GlobalStyles from '@mui/material/GlobalStyles';

import { AuthGuard } from '@/components/auth/auth-guard';
import { MainNav } from '@/components/dashboard/layout/main-nav';
import { SideNav } from '@/components/dashboard/layout/side-nav';
import { SocketProvider } from '@/lib/socketProvider';
import NotificationGuard from '@/components/auth/notificationguard';
import MessageDialog from '@/components/MessageDialog';
import { ScrollLockReset } from '@/components/dashboard/layout/scroll-lock-reset';
import { CallProvider } from '@/calls/CallProvider';
import { CallOverlay } from '@/calls/CallOverlay';

interface LayoutProps {
  children: React.ReactNode;
}

export default function Layout({ children }: LayoutProps): React.JSX.Element {
  return (
    <AuthGuard>
      {/* <NotificationGuard> */}
      <GlobalStyles
        styles={{
          body: {
            '--MainNav-height': '56px',
            '--MainNav-zIndex': 1000,
            '--SideNav-width': '280px',
            '--SideNav-zIndex': 1100,
            '--MobileNav-width': '320px',
            '--MobileNav-zIndex': 1100,
          },
        }}
      />
     <SocketProvider>
      {/* Voice calls: state + incoming card + floating call bar on every dashboard page */}
      <CallProvider>
       <Box
        sx={{
          bgcolor: 'var(--mui-palette-background-default)',
          display: 'flex',
          flexDirection: 'column',
          position: 'relative',
          minHeight: '100%',
        }}
      >
        <SideNav />
        <Box sx={{ display: 'flex', flex: '1 1 auto', flexDirection: 'column', pl: { lg: 'var(--SideNav-width)' } }}>
          <MainNav />
          <main>{children}</main>
        </Box>
      </Box>
      <ScrollLockReset />
      <MessageDialog/>
      <CallOverlay />
      </CallProvider>
      </SocketProvider>
      {/* </NotificationGuard> */}
    </AuthGuard>
  );
}
