import * as React from 'react';
import { UserChannel } from '@/redux/models/ChannelModel';
import { Chip } from '@mui/material';
import Box from '@mui/material/Box';
import Divider from '@mui/material/Divider';
import ListItem from '@mui/material/ListItem';
import ListItemButton, { ListItemButtonProps } from '@mui/material/ListItemButton';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import { useSocket } from '@/lib/socketProvider';
import { useDriverOnCall } from '@/calls/CallProvider';
import { Phone } from '@phosphor-icons/react';

import AvatarWithStatus from './AvatarWithStatus';
import { MessageProps } from './types';
import { formatDate, toggleMessagesPane } from './utils';
import { useDispatch } from 'react-redux';
import { apiSlice } from '@/redux/apiSlice';
import { chat } from '@/styles/theme/chat-tokens';

type ChatListItemProps = ListItemButtonProps & {
  id: string;
  unread?: boolean;
  user: UserChannel;
  messages?: MessageProps[];
  setSelectedChannelId?: (id: string) => void;
  selectedChannelId?: string;
  selectedUserId: string;
  setSelectedUserId: (id: string) => void;
  channelId: String;
};

export default function ChatListItem(props: ChatListItemProps) {
  const { id, user, selectedUserId, setSelectedUserId, channelId } = props;
  const selected = selectedUserId === id;
  const { socket } = useSocket();
  const dispatch = useDispatch()
  React.useEffect(() => {}, [socket]);
  // This driver is on a call right now (with any dispatcher): highlight the row
  const onCall = useDriverOnCall(user?.userProfileId);
  const withWhom = onCall?.members.filter((m) => m.id !== user?.userProfileId).map((m) => m.name).join(', ');
  return (
    <>
      <ListItem sx={{ padding: 0 }}>
        <ListItemButton
          onClick={() => {
            
            
            toggleMessagesPane();
            setSelectedUserId(user?.userProfileId);
            socket.emit('staff_open_chat', user?.userProfileId);
            //if (user.unreadCount > 0) {
              // The server acks with update_channel_sent_message_count, which zeroes the row and
              // schedules one coalesced badge refresh (no immediate refetch on every click)
              socket.emit('update_channel_sent_message_count', { channelId, userId: id });
            //}
          }}
          selected={selected}
          sx={{
            flexDirection: 'column',
            alignItems: 'initial',
            gap: 1,
            px: 2,
            py: 1.5,
            transition: 'background-color 0.15s ease',
            '&.Mui-selected, &.Mui-selected:hover': chat.rowSelected,
            '&:hover': chat.rowHover,
            ...(onCall
              ? {
                  boxShadow: 'inset 3px 0 0 var(--mui-palette-success-main)',
                  bgcolor: 'rgba(34, 197, 94, 0.08)',
                }
              : {}),
          }}
        >
          <Stack direction="row" spacing={1.5}>
            <AvatarWithStatus online={user?.UserProfile?.isOnline} title={user?.UserProfile?.username} />
            <Box sx={{ flex: 1 }}>
            <Typography variant="subtitle1">{user?.UserProfile?.username} <span style={{fontSize:12}}> ({user?.UserProfile?.user?.driver_number})</span></Typography>
            {onCall ? (
              <Chip
                color="success"
                icon={<Phone size={12} weight="fill" />}
                label={withWhom ? `On call · ${withWhom}` : 'On call'}
                size="small"
                sx={{ height: 20, fontSize: 11, fontWeight: 600, maxWidth: 240, mb: 0.25 }}
                title={withWhom ? `On a call with ${withWhom}` : 'On a call'}
              />
            ) : null}
            <Typography sx={{
              fontSize:12
            }}> {user?.assginTrucks ? `assgined trucks: ${user?.assginTrucks}`: ""} </Typography>
              <Typography
                variant="body2"
                sx={{
                  display: 'block',
                  maxWidth: '250px',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                }}
              >
                {user?.last_message?.body}
              </Typography>
            </Box>
            <Box sx={{ lineHeight: 1.5, textAlign: 'right' }}>
              {user?.unreadCount > 0 && (
                <Chip
                  variant="filled"
                  color="primary"
                  size="small"
                  label={user?.unreadCount}
                  sx={{ ml: 1, backgroundColor: 'primary.main', color: '#fff', fontWeight: 600, height: 20, borderRadius: '99px' }}
                />
              )}
              <Typography variant="caption" noWrap sx={{ display: { xs: 'none', md: 'block' } }}>
                {formatDate(user?.last_message?.messageTimestampUtc)}
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
          ></Typography>
        </ListItemButton>
      </ListItem>
      <Divider sx={{ margin: 0 }} />
    </>
  );
}
