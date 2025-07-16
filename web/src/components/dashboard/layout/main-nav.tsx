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
import { Users as UsersIcon } from '@phosphor-icons/react/dist/ssr/Users';

import { usePopover } from '@/hooks/use-popover';

import { MobileNav } from './mobile-nav';
import { UserPopover } from './user-popover';
import { Button } from '@mui/material';
import { useUnReadMessageAllMutation } from '@/redux/ChannelApiSlice';
import MarkMessageDialog from './mark-message-dialog';
import { toast } from 'react-toastify';
import { useGetProfileQuery } from '@/redux/UserApiSlice';

export function MainNav(): React.JSX.Element {
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
          backgroundColor: 'var(--mui-palette-background-paper)',
          position: 'sticky',
          top: 0,
          zIndex: 'var(--mui-zIndex-appBar)',
        }}
      >
        <Stack
          direction="row"
          spacing={2}
          sx={{ alignItems: 'center', justifyContent: 'space-between', minHeight: '64px', px: 2 }}
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
            {/* <Tooltip title="Search">
              <IconButton>
                <MagnifyingGlassIcon />
              </IconButton>
            </Tooltip> */}
          </Stack>
          <Stack sx={{ alignItems: 'center' }} direction="row" spacing={2}>
           <Button variant="outlined"   onClick={(): void => {
                setOpenDialog(true);
              }}> Mark all messages as read</Button>
            {/* <Tooltip title="Notifications">
              <Badge badgeContent={4} color="success" variant="dot">
                <IconButton>
                  <BellIcon />
                </IconButton>
              </Badge>
            </Tooltip> */}
            <Avatar
              onClick={userPopover.handleOpen}
              ref={userPopover.anchorRef}
              src={data?.data?.username?.toUpperCase() || 'User Avatar'}
              alt={data?.data?.username?.toUpperCase() || 'User Avatar'}
              sx={{ cursor: 'pointer' }}
            />
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
