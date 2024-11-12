import * as React from 'react';
import Box from '@mui/material/Box';
import Divider from '@mui/material/Divider';
import ListItem from '@mui/material/ListItem';
import ListItemButton, { ListItemButtonProps } from '@mui/material/ListItemButton';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import CircleIcon from '@mui/icons-material/Circle';
import AvatarWithStatus from './AvatarWithStatus';
import { ChatProps, MessageProps, UserProps } from './types';
import { toggleMessagesPane } from './utils';
import { UserChannel } from '@/redux/models/ChannelModel';
import { useSocket } from '@/lib/socketProvider';

type ChatListItemProps = ListItemButtonProps & {
  id: string;
  unread?: boolean;
  user: UserChannel;
  messages?: MessageProps[];
  setSelectedChannelId?: (id: string) => void;
  selectedChannelId?: string;
  selectedUserId:string;
  setSelectedUserId: (id: string) => void;
};

export default function ChatListItem(props: ChatListItemProps) {
  const { id, user, messages, setSelectedChannelId, selectedUserId,setSelectedUserId } = props;
  const selected = selectedUserId === id;
  const {socket} = useSocket();
  return (
    <>
      <ListItem>
        <ListItemButton
          onClick={() => {
            toggleMessagesPane();
            setSelectedUserId(user?.userProfileId);
            socket.emit("staff_open_chat",user?.userProfileId)
          }}
          selected={selected}
          sx={{ flexDirection: 'column', alignItems: 'initial', gap: 1 }}
        >
          <Stack direction="row" spacing={1.5}>
            <AvatarWithStatus online={user?.UserProfile?.isOnline} src={user?.UserProfile?.username} />
            <Box sx={{ flex: 1 }}>
              <Typography variant="subtitle1">{user?.UserProfile?.username}</Typography>
              {/* <Typography variant="body2">{sender.username}</Typography> */}
            </Box>
            <Box sx={{ lineHeight: 1.5, textAlign: 'right' }}>
              {/* {messages[0]?.unread && (
                <CircleIcon sx={{ fontSize: 12 }} color="primary" />
              )} */}
              <Typography
                variant="caption"
                noWrap
                sx={{ display: { xs: 'none', md: 'block' } }}
              >
                5 mins ago
              </Typography>
            </Box>
          </Stack>
          <Typography
            variant="body2"
            sx={{
              display: '-webkit-box',
              WebkitLineClamp: 2,
              WebkitBoxOrient: 'vertical',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
            }}
          >

          </Typography>
        </ListItemButton>
      </ListItem>
      <Divider sx={{ margin: 0 }} />
    </>
  );
}
