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
import { UserProps } from './types';
import { toggleMessagesPane } from './utils';

type MessagesPaneHeaderProps = {
  sender: UserProps;
};

export default function MessagesPaneHeader(props: MessagesPaneHeaderProps) {
  const { sender } = props;

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
        <Avatar alt={sender.name} src={sender.avatar} />
        <div>
          <Typography
            variant="h6"
            noWrap
            sx={{ fontWeight: 'fontWeightBold' }}
          >
            {sender.name}
            {sender.online && (
              <Chip
                size="small"
                color="success"
                sx={{ ml: 1 }}
                icon={<CircleIcon sx={{ fontSize: 12 }} />}
                label="Online"
              />
            )}
          </Typography>
          <Typography variant="body2">{sender.username}</Typography>
        </div>
      </Stack>
      <Stack spacing={1} direction="row" sx={{ alignItems: 'center' }}>
        {/* <Button
          startIcon={<PhoneInTalkRoundedIcon />}

          variant="outlined"
          size="small"
          sx={{ display: { xs: 'none', md: 'inline-flex' } }}
        >
          Call
        </Button> */}
        <Button

          variant="outlined"
          size="small"
          sx={{ display: { xs: 'none', md: 'inline-flex' } }}
        >
          View profile
        </Button>
        <IconButton size="small" color="default">
          <MoreVertRoundedIcon />
        </IconButton>
      </Stack>
    </Stack>
  );
}
