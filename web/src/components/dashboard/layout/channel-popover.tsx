import * as React from 'react';
import { useGetChannelsQuery } from '@/redux/ChannelApiSlice';
import Box from '@mui/material/Box';
import Divider from '@mui/material/Divider';
import MenuItem from '@mui/material/MenuItem';
import MenuList from '@mui/material/MenuList';
import Popover from '@mui/material/Popover';
import Typography from '@mui/material/Typography';
import { useUpdateActiveChannelMutation } from '@/redux/UserApiSlice';
import { toast } from 'react-toastify';


export interface ChannelPopoverProps {
  anchorEl: Element | null;
  onClose: () => void;
  open: boolean;
}

export function ChannelPopover({ anchorEl, onClose, open }: ChannelPopoverProps): React.JSX.Element {
  const { data, isLoading } = useGetChannelsQuery();
  const [updateActiveChannel] = useUpdateActiveChannelMutation()
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
            return <MenuItem  sx={{
              background: e.isActive ? "var(--mui-palette-primary-dark)" : "#fff",
              color: e.isActive ? "#fff" : "black",
              "&:hover": {
                background: "#e7e7e7",
                color: "#000"
              }
            }}   onClick={async()=>{
               const res = await updateActiveChannel({channelId:e.id,id:"0adc1023-bb6c-4444-81b6-2f6c942c5392"})
               if(res.data?.status){
                toast.success("Changes Channel successfully.")
                onClose?.()
               }else{
                toast.error("SERVER ERROR")
               }
            }}>{e.name}</MenuItem>;
          })}
      </MenuList>
    </Popover>
  );
}
