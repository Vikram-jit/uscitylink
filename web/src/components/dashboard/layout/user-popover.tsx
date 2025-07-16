import * as React from 'react';
import RouterLink from 'next/link';
import { useRouter } from 'next/navigation';
import Box from '@mui/material/Box';
import Divider from '@mui/material/Divider';
import ListItemIcon from '@mui/material/ListItemIcon';
import MenuItem from '@mui/material/MenuItem';
import MenuList from '@mui/material/MenuList';
import Popover from '@mui/material/Popover';
import Typography from '@mui/material/Typography';
import { GearSix as GearSixIcon } from '@phosphor-icons/react/dist/ssr/GearSix';
import { SignOut as SignOutIcon } from '@phosphor-icons/react/dist/ssr/SignOut';
import { User as UserIcon } from '@phosphor-icons/react/dist/ssr/User';

import { paths } from '@/paths';
import { authClient } from '@/lib/auth/client';
import { logger } from '@/lib/default-logger';
import { useUser } from '@/hooks/use-user';
import { useSocket } from '@/lib/socketProvider';
import { useGetProfileQuery } from '@/redux/UserApiSlice';
import { CircularProgress } from '@mui/material';

export interface UserPopoverProps {
  anchorEl: Element | null;
  onClose: () => void;
  open: boolean;
  data:any
  isLoading:boolean;
}

export function UserPopover({ anchorEl, onClose, open ,data,isLoading}: UserPopoverProps): React.JSX.Element {
  const { checkSession } = useUser();
  const  {socket} = useSocket();
  const  [socketServer,setSocketServer] = React.useState<any>(null)
 
  const router = useRouter();
  React.useEffect(()=>{
    if(socket){
    
      setSocketServer(socket)
    }
  },[socket])
  const handleSignOut = React.useCallback(async (): Promise<void> => {
    try {

        if(socket){

         await socket.emit("driverLogout",{})
        }


      const { error } = await authClient.signOut();

      if (error) {
        logger.error('Sign out error', error);
        return;
      }

      // Refresh the auth state
      await checkSession?.();

      // UserProvider, for this case, will not refresh the router and we need to do it manually
      router.refresh();
      // After refresh, AuthGuard will handle the redirect
    } catch (err) {
      logger.error('Sign out error', err);
    }
  }, [checkSession, router,socket,socketServer]);

  return (
    <Popover
      anchorEl={anchorEl}
      anchorOrigin={{ horizontal: 'left', vertical: 'bottom' }}
      onClose={onClose}
      open={open}
      slotProps={{ paper: { sx: { width: '240px' } } }}
    >
     {isLoading ? <CircularProgress/> :  <Box sx={{ p: '16px 20px ' }}>
        <Typography variant="subtitle1">{data?.data?.username}</Typography>
        <Typography color="text.secondary" variant="body2">
        {data?.data?.user?.email}
        </Typography>
      </Box>}
      <Divider />
      <MenuList disablePadding sx={{ p: '8px', '& .MuiMenuItem-root': { borderRadius: 1 } }}>
        {/* <MenuItem component={RouterLink} href={paths.dashboard.settings} onClick={onClose}>
          <ListItemIcon>
            <GearSixIcon fontSize="var(--icon-fontSize-md)" />
          </ListItemIcon>
          Settings
        </MenuItem> */}
        {/* <MenuItem component={RouterLink} href={paths.dashboard.account} onClick={onClose}>
          <ListItemIcon>
            <UserIcon fontSize="var(--icon-fontSize-md)" />
          </ListItemIcon>
          Profile
        </MenuItem> */}
        <MenuItem onClick={handleSignOut}>
          <ListItemIcon>
            <SignOutIcon fontSize="var(--icon-fontSize-md)" />
          </ListItemIcon>
          Sign out
        </MenuItem>
      </MenuList>
    </Popover>
  );
}
