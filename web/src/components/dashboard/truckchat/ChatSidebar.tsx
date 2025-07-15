'use client';

import React from 'react';
import { Group, GroupModel, SingleGroupModel } from '@/redux/models/GroupModel';
import {
  Avatar,
  Badge,
  Box,
  Divider,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  TextField,
  Typography,
} from '@mui/material';
import { FiSearch } from 'react-icons/fi';

import { Chat, User } from './types';
import InfiniteScroll from 'react-infinite-scroll-component';

interface ChatSidebarProps {
  chats: GroupModel[];
  currentUser: SingleGroupModel | undefined;
  currentChatId?: string;
  onSelectChat: (chatId: string) => void;
  search: string;
  setSearch: React.Dispatch<React.SetStateAction<string>>;
  setSelectedGroup: React.Dispatch<React.SetStateAction<string>>;
  setGroups: React.Dispatch<React.SetStateAction<GroupModel[]>>;
   loadMoreMessages: () => void;
        hasMore?: boolean;
        setPage?: React.Dispatch<React.SetStateAction<number>>;
}

export const ChatSidebar: React.FC<ChatSidebarProps> = ({
  chats,
  currentUser,
  currentChatId,
  onSelectChat,
  search,
  setSearch,
  setSelectedGroup,
  setGroups,
  loadMoreMessages,
  hasMore = true,
  setPage
}) => {
  return (
    <Box
      sx={{
        width: 300,
        height: '100%',
        borderRight: '1px solid',
        borderColor: 'divider',
        overflowY: 'auto',
      }}
    >
      <Box sx={{ p: 2 }}>
        <Typography variant="h6">Truck Chats</Typography>
        <Box sx={{ marginTop: 1 }}>
          <TextField
            value={search}
            fullWidth
            placeholder="Search groups"
            variant="outlined"
            size="small"
            onChange={(e) => {
              setSearch(e.target.value);
              setGroups([]);
              setSelectedGroup('');
              setPage?.(1);
            }}
            InputProps={{
              startAdornment: <FiSearch style={{ marginRight: 8 }} />,
            }}
          />
        </Box>
      </Box>
      <Divider />
      <List id="scrollable-channel-container" sx={{ maxHeight: '650px', overflowY: 'auto' }}>
          <InfiniteScroll
                        dataLength={chats?.length || 0}
                        next={loadMoreMessages}
                        hasMore={hasMore}
                        loader={<h4>Loading...</h4>}
                        scrollThreshold={0.95}
                        scrollableTarget="scrollable-channel-container"
                      >
        {chats.map((chat) => (
          <ListItem
            key={chat.id}
            button
            selected={chat.id === currentChatId}
            onClick={() => onSelectChat(chat.id)}
            sx={{
              '&:hover': {
                backgroundColor: 'action.hover',
              },
              '&.Mui-selected': {
                backgroundColor: 'action.selected',
              },
            }}
          >
            <ListItemAvatar>
              <Badge
                overlap="circular"
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                variant="dot"
                // color={
                //   chat.user.status === 'online' ? 'success' :
                //   chat.user.status === 'away' ? 'warning' : 'default'
                // }
              >
                <Avatar src={chat.name} alt={chat.name} />
              </Badge>
            </ListItemAvatar>
            <ListItemText
              primary={chat?.name}
              secondary={
                chat.last_message
                  ? `${chat.last_message?.body?.substring(0, 30)}${chat.last_message.body?.length > 30 ? '...' : ''}`
                  : 'No messages yet'
              }
              secondaryTypographyProps={{
                overflow: 'hidden',
                textOverflow: 'ellipsis',
                whiteSpace: 'nowrap',
              }}
            />
            {/* {chat.unreadCount > 0 && (
              <Box sx={{
                minWidth: 24,
                height: 24,
                borderRadius: '50%',
                bgcolor: 'primary.main',
                color: 'primary.contrastText',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                ml: 1
              }}>
                <Typography variant="caption">
                  {chat.unreadCount}
                </Typography>
              </Box>
            )} */}
          </ListItem>
        ))}
        </InfiniteScroll>
      </List>
      
    </Box>
  );
};
