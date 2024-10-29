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

type ChatListItemProps = ListItemButtonProps & {
  id: string;
  unread?: boolean;
  sender: UserProps;
  messages: MessageProps[];
  selectedChatId?: string;
  setSelectedChat: (chat: ChatProps) => void;
};

export default function ChatListItem(props: ChatListItemProps) {
  const { id, sender, messages, selectedChatId, setSelectedChat } = props;
  const selected = selectedChatId === id;

  return (
    <>
      <ListItem>
        <ListItemButton
          onClick={() => {
            toggleMessagesPane();
            setSelectedChat({ id, sender, messages });
          }}
          selected={selected}
          sx={{ flexDirection: 'column', alignItems: 'initial', gap: 1 }}
        >
          <Stack direction="row" spacing={1.5}>
            <AvatarWithStatus online={sender.online} src={sender.avatar} />
            <Box sx={{ flex: 1 }}>
              <Typography variant="subtitle1">{sender.name}</Typography>
              <Typography variant="body2">{sender.username}</Typography>
            </Box>
            <Box sx={{ lineHeight: 1.5, textAlign: 'right' }}>
              {messages[0]?.unread && (
                <CircleIcon sx={{ fontSize: 12 }} color="primary" />
              )}
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
            {messages[0]?.content}
          </Typography>
        </ListItemButton>
      </ListItem>
      <Divider sx={{ margin: 0 }} />
    </>
  );
}
