'use client';

import * as React from 'react';
import Avatar from '@mui/material/Avatar';
import Badge from '@mui/material/Badge';
import Box from '@mui/material/Box';
import IconButton from '@mui/material/IconButton';
import Stack from '@mui/material/Stack';
import Tooltip from '@mui/material/Tooltip';
import { Bell as BellIcon } from '@phosphor-icons/react/dist/ssr/Bell';
import { List as ListIcon } from '@phosphor-icons/react/dist/ssr/List';
import { Moon as MoonIcon } from '@phosphor-icons/react/dist/ssr/Moon';
import { Sun as SunIcon } from '@phosphor-icons/react/dist/ssr/Sun';
import { useColorScheme } from '@mui/material/styles';
import { usePathname } from 'next/navigation';
import Typography from '@mui/material/Typography';

import { usePopover } from '@/hooks/use-popover';

import { MobileNav } from './mobile-nav';
import { UserPopover } from './user-popover';
import { Button } from '@mui/material';
import { useUnReadMessageAllMutation } from '@/redux/ChannelApiSlice';
import MarkMessageDialog from './mark-message-dialog';
import { toast } from 'react-toastify';
import { useGetProfileQuery } from '@/redux/UserApiSlice';

const PAGE_TITLES: Record<string, string> = {
  overview: 'Overview',
  messages: 'Messages',
  truckgroup: 'Truck groups',
  'truck-chat': 'Truck chat',
  groups: 'Groups',
  'broadcast-messages': 'Broadcast messages',
  'system-messages': 'System messages',
  templates: 'Templates',
  users: 'Users',
  channels: 'Channels',
  trainings: 'Training',
  staff_chat: 'Staff chat',
  automation: 'Automation',
  account: 'Account',
  settings: 'Settings',
};

const titleFor = (pathname: string): string => {
  const parts = pathname.split('/').filter(Boolean);
  const segment = parts[1] || 'overview';
  if (segment === 'users') return parts.includes('driver') ? 'Drivers' : 'Staff users';
  return PAGE_TITLES[segment] || segment.replace(/[-_]/g, ' ').replace(/^\w/, (c) => c.toUpperCase());
};

export function MainNav(): React.JSX.Element {
  const pathname = usePathname();
  const { mode, setMode } = useColorScheme();
  const [openNav, setOpenNav] = React.useState<boolean>(false);

  const userPopover = usePopover<HTMLDivElement>();
  const [openDialog,setOpenDialog] = React.useState<boolean>(false)
  const {data,isLoading:profileLoader} = useGetProfileQuery();
  const [unReadMessageAll,{isLoading}] = useUnReadMessageAllMutation()

  return (

    <React.Fragment>
      <Box
        component="header"
        sx={{
          borderBottom: '1px solid var(--mui-palette-divider)',
          backgroundColor: 'rgba(var(--mui-palette-background-paperChannel) / 0.9)',
          backdropFilter: 'saturate(180%) blur(12px)',
          position: 'sticky',
          top: 0,
          zIndex: 'var(--mui-zIndex-appBar)',
        }}
      >
        <Stack
          direction="row"
          spacing={2}
          sx={{ alignItems: 'center', justifyContent: 'space-between', minHeight: '60px', px: 3 }}
        >
          <Stack sx={{ alignItems: 'center' }} direction="row" spacing={2}>
            <IconButton
              onClick={(): void => {
                setOpenNav(true);
              }}
              sx={{ display: { lg: 'none' } }}
            >
              <ListIcon />
            </IconButton>
            <Box>
              <Stack alignItems="center" direction="row" spacing={0.75}>
                <Typography color="text.secondary" sx={{ fontSize: 13, fontWeight: 500 }}>
                  Dashboard
                </Typography>
                <Typography color="text.disabled" sx={{ fontSize: 13 }}>
                  /
                </Typography>
                <Typography color="text.primary" sx={{ fontSize: 13, fontWeight: 600 }}>
                  {titleFor(pathname)}
                </Typography>
              </Stack>
            </Box>
          </Stack>
          <Stack sx={{ alignItems: 'center' }} direction="row" spacing={2}>
           <Button variant="outlined" size="small" onClick={(): void => {
                setOpenDialog(true);
              }}> Mark all messages as read</Button>
            <Tooltip title={mode === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}>
              <IconButton
                aria-label="Toggle light and dark mode"
                onClick={() => setMode(mode === 'dark' ? 'light' : 'dark')}
                sx={{ border: '1px solid var(--mui-palette-divider)' }}
              >
                {mode === 'dark' ? <SunIcon /> : <MoonIcon />}
              </IconButton>
            </Tooltip>
         
            <Avatar
              onClick={userPopover.handleOpen}
              ref={userPopover.anchorRef}
              sx={{
                cursor: 'pointer',
                width: 34,
                height: 34,
                transition: 'box-shadow 0.15s ease',
                '&:hover': { boxShadow: '0 0 0 3px rgba(var(--mui-palette-primary-mainChannel) / 0.2)' },
              }}
            >
              {(data?.data?.username || 'U').charAt(0).toUpperCase()}
            </Avatar>
          </Stack>
        </Stack>
      </Box>
      <UserPopover data={data} isLoading={profileLoader} anchorEl={userPopover.anchorRef.current} onClose={userPopover.handleClose} open={userPopover.open} />
      <MobileNav
        onClose={() => {
          setOpenNav(false);
        }}
        open={openNav}
      />
      {openDialog && <MarkMessageDialog open={openDialog} loader={isLoading} onClose={()=>{
        setOpenDialog(false)
      }} onSendOtp={async()=>{
        const res = await unReadMessageAll()
        if(res.data?.status){
          toast.success(res.data?.message)
          setOpenDialog(false)
          window.location.reload()
          return
        }
        toast.error("SERVER ERROR")
      }}/>}
    </React.Fragment>

  );
}
