"use client";

import React from 'react';
import { 
  List, 
  ListItem, 
  ListItemAvatar, 
  Avatar, 
  ListItemText, 
  Badge, 
  Typography,
  Divider,
  Box,
  TextField
} from '@mui/material';
import { Chat, User } from './types';
import { Group, GroupModel, SingleGroupModel } from '@/redux/models/GroupModel';
import { FiSearch } from 'react-icons/fi';

interface ChatSidebarProps {
  chats: GroupModel[];
  currentUser: SingleGroupModel | undefined;
  currentChatId?: string;
  onSelectChat: (chatId: string) => void;
  search: string;
  setSearch: React.Dispatch<React.SetStateAction<string>>;
  setSelectedGroup: React.Dispatch<React.SetStateAction<string>>;
  setGroups: React.Dispatch<React.SetStateAction<GroupModel[]>>;
}

export const ChatSidebar: React.FC<ChatSidebarProps> = ({ 
  chats, 
  currentUser,
  currentChatId,
  onSelectChat ,
  search,
  setSearch,
  setSelectedGroup,
  setGroups
}) => {
  return (
    <Box sx={{ 
      width: 300,
      height: '100%',
      borderRight: '1px solid',
      borderColor: 'divider',
      overflowY: 'auto'
    }}>
      <Box sx={{ p: 2 }}>
        <Typography variant="h6">Truck Chats</Typography>
         <Box sx={{marginTop:1 }}>
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
                      }}
                      InputProps={{
                        startAdornment: <FiSearch style={{ marginRight: 8 }} />,
                      }}
                    />
                  </Box>
      </Box>
      <Divider />
      <List>
        {chats.map((chat) => (
          <ListItem 
            key={chat.id}
            button
            selected={chat.id === currentChatId}
            onClick={() => onSelectChat(chat.id)}
            sx={{
              '&:hover': {
                backgroundColor: 'action.hover'
              },
              '&.Mui-selected': {
                backgroundColor: 'action.selected'
              }
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
                whiteSpace: 'nowrap'
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
      </List>
    </Box>
  );
};