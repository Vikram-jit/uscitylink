import * as React from 'react';
import { useGetChannelsQuery } from '@/redux/ChannelApiSlice';
import { useUpdateActiveChannelMutation } from '@/redux/UserApiSlice';
import Box from '@mui/material/Box';
import Divider from '@mui/material/Divider';
import MenuItem from '@mui/material/MenuItem';
import MenuList from '@mui/material/MenuList';
import Popover from '@mui/material/Popover';
import Typography from '@mui/material/Typography';
import { toast } from 'react-toastify';

import { useSocket } from '@/lib/socketProvider';
import { useDispatch } from 'react-redux';
import { updateChannelState } from '@/redux/slices/channelSlice';

export interface ChannelPopoverProps {
  anchorEl: Element | null;
  onClose: () => void;
  open: boolean;
}

export function ChannelPopover({ anchorEl, onClose, open }: ChannelPopoverProps): React.JSX.Element {
  const { data, isLoading } = useGetChannelsQuery();
  const [updateActiveChannel] = useUpdateActiveChannelMutation();
  const { socket } = useSocket();
  const dispatch = useDispatch()
  return (
    <Popover
      anchorEl={anchorEl}
      anchorOrigin={{ horizontal: 'left', vertical: 'bottom' }}
      onClose={onClose}
      open={open}
      slotProps={{ paper: { sx: { width: '240px' } } }}
    >
      <MenuList disablePadding sx={{ p: '8px', '& .MuiMenuItem-root': { borderRadius: 1 } }}>
        {data &&
          data?.data?.map((e) => {
            return (
              <MenuItem
                sx={{
                  background: e.isActive ? 'var(--mui-palette-primary-dark)' : '#fff',
                  color: e.isActive ? '#fff' : 'black',
                  '&:hover': {
                    background: '#e7e7e7',
                    color: '#000',
                  },
                }}
                onClick={async () => {
                  const res = await updateActiveChannel({ channelId: e.id });
                  if (res.data?.status) {
                    toast.success('Changes Channel successfully.');
                    socket.emit('staff_channel_update', e.id);
                    dispatch(updateChannelState())
                    onClose?.();
                  } else {
                    toast.error('SERVER ERROR');
                  }
                }}
              >
                {e.name}
              </MenuItem>
            );
          })}
      </MenuList>
    </Popover>
  );
}
