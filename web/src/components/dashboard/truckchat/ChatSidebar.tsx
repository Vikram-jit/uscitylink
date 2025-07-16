'use client';

import React, { useState } from 'react';
import { Group, GroupModel, SingleGroupModel } from '@/redux/models/GroupModel';
import {
  Avatar,
  Badge,
  Box,
  Button,
  Chip,
  Divider,
  List,
  ListItem,
  ListItemAvatar,
  ListItemButton,
  ListItemText,
  TextField,
  Typography,
} from '@mui/material';
import { FiSearch } from 'react-icons/fi';
import InfiniteScroll from 'react-infinite-scroll-component';

import { Chat, User } from './types';
import moment from 'moment';
import { type } from 'os';
import AddGroupDialog from '../truckgroup/component/AddGroupDialog';

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
  setPage,
}) => {
    const [open, setOpen] = useState<boolean>(false);
  
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
      {open && <AddGroupDialog open={open} setOpen={setOpen} type={"truck"} />}
          <Box sx={{ display: 'flex', gap: 1,justifyContent: 'space-between', alignItems: 'center' }}>
              <Typography variant="h6">Truck Chats</Typography>
                      <Button onClick={() => setOpen(true)} size="small" variant="contained">
                        Add Group
                      </Button>
                    </Box>
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
          {chats.map((group) => (
            <ListItem key={group.id} sx={{ padding: 0 }}>
                        <ListItemButton
                          selected={currentChatId == group.id}
                          sx={{
                            alignItems: 'initial',
                            gap: 1,
                            '&.Mui-selected': {
                              backgroundColor: 'primary.main',
                              color: 'white',
                            },
                            '&:hover': {
                              backgroundColor: 'primary.light',
                              color: 'black',
                            },
                          }}
                          onClick={() => onSelectChat(group.id)}
                        >
                          <Badge
                            overlap="circular"
                            anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                            variant="dot"
                            // color={contact.status === "online" ? "success" : "default"}
                          >
                            <Avatar>{group.name.split('')?.[0]}</Avatar>
                            {/* <Avatar alt=""} /> */}
                          </Badge>
                          <ListItemText
                            primary={
                              <Box display={'flex'} justifyContent={'space-between'}>
                                <Box display={'flex'} flexDirection={'column'}>
                                  <Typography>{group.name}</Typography>
                                  <Typography
                                    sx={{
                                      color: 'grey',
                                      overflow: 'hidden',
                                      display: '-webkit-box',
                                      WebkitBoxOrient: 'vertical',
                                      WebkitLineClamp: 2, // Limits text to 2 lines
                                      '&:hover': {
                                        color: 'grey',
                                      },
                                    }}
                                  >
                                    {group.last_message?.body ?? 'No Message Yet'}
                                  </Typography>
                                </Box>
                                <Box display={'flex'} flexDirection={'column'}>
                                  {group?.message_count > 0 && (
                                   <Box width={'100%'}>
                                     <Chip
                                     
                                      size="small"
                                      variant="filled"
                                      color="primary"
                                     
                                      label={group?.message_count}
                                      sx={{ ml: 1 ,float: 'right'}}
                                    />
                                   </Box>
                                  )}
                                  <Typography variant="caption" noWrap sx={{ display: { xs: 'none', md: 'block' } }}>
                                    {moment(group?.last_message?.messageTimestampUtc).format('MM-DD-YYYY hh:mm A')}
                                  </Typography>
                                </Box>
                              </Box>
                            }
                            sx={{ ml: 2 }}
                          />
                        </ListItemButton>
                      </ListItem>
          ))}
        </InfiniteScroll>
      </List>
    </Box>
  );
};
