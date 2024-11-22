import * as React from 'react';
import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import IconButton from '@mui/material/IconButton';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import CircleIcon from '@mui/icons-material/Circle';
import ArrowBackIosNewRoundedIcon from '@mui/icons-material/ArrowBackIosNewRounded';
import PhoneInTalkRoundedIcon from '@mui/icons-material/PhoneInTalkRounded';
import MoreVertRoundedIcon from '@mui/icons-material/MoreVertRounded';
import { toggleMessagesPane } from './utils';
import { UserProfile } from '@/redux/models/ChannelModel';

type MessagesPaneHeaderProps = {
  sender?: UserProfile;
  mediaPanel:boolean
  setMediaPanel:React.Dispatch<React.SetStateAction<boolean>>
};

export default function MessagesPaneHeader(props: MessagesPaneHeaderProps) {
  const { sender,setMediaPanel,mediaPanel } = props;

  return (
    <Stack
      direction="row"
      sx={{
        justifyContent: 'space-between',
        py: 2,
        px: 2,
        borderBottom: '1px solid',
        borderColor: 'divider',
        backgroundColor: 'background.paper',
      }}
    >
      <Stack
        direction="row"
        spacing={2}
        sx={{ alignItems: 'center' }}
      >
        <IconButton
          color="default"
          size="small"
          sx={{ display: { xs: 'inline-flex', sm: 'none' } }}
          onClick={() => toggleMessagesPane()}
        >
          <ArrowBackIosNewRoundedIcon />
        </IconButton>
        <Avatar alt={sender?.username} src={sender?.profile_pic || ""} />
        <div>
          <Typography
            variant="h6"
            noWrap
            sx={{ fontWeight: 'fontWeightBold' }}
          >
            {sender?.username}
            {sender?.isOnline && (
              <Chip
                size="small"
                color="success"
                sx={{ ml: 1 }}
                icon={<CircleIcon sx={{ fontSize: 12 }} />}
                label="Online"
              />
            )}
          </Typography>
          <Typography variant="body2">{sender?.isOnline ? "online" : sender?.last_login}</Typography>
        </div>
      </Stack>
      <Stack spacing={1} direction="row" sx={{ alignItems: 'center' }}>

        <Button
          onClick={()=>setMediaPanel((prev) => !prev)}
          variant="outlined"
          size="small"
          sx={{ display: { xs: 'none', md: 'inline-flex' } }}
        >
         {mediaPanel ? "View Messages"  : "View Media"}
        </Button>
        <IconButton size="small" color="default">
          <MoreVertRoundedIcon />
        </IconButton>
      </Stack>
    </Stack>
  );
}
