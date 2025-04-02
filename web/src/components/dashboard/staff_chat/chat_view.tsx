'use client';

import React, { useEffect, useState } from 'react';
import { StaffChatModel } from '@/redux/models/StaffChatModel';
import { useGetStaffChatUsersQuery } from '@/redux/StaffChatApiSlice';
import SendIcon from '@mui/icons-material/Send';
import {
  Avatar,
  Badge,
  Box,
  Button,
  Divider,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  Paper,
  TextField,
  Typography,
} from '@mui/material';

import AddMemberDialog from './add_member_dialog';

interface Contact {
  id: number;
  name: string;
}

interface Message {
  sender: string;
  content: string;
}

const contacts: Contact[] = [
  { id: 1, name: 'Alice' },
  { id: 2, name: 'Bob' },
];

const ChatView: React.FC = () => {
  const [selectedContact, setSelectedContact] = useState<Contact | null>(null);
  const [messages, setMessages] = useState<{ [key: number]: Message[] }>({});
  const [newMessage, setNewMessage] = useState<string>('');
  const [chatUsers, setChatUsers] = useState<StaffChatModel[]>([]);
  const { data, isLoading,isFetching } = useGetStaffChatUsersQuery();
  const [open, setOpen] = useState<boolean>(false);
  useEffect(() => {
    if (data?.status) {
      setChatUsers(data?.data);
    }
  }, [isFetching]);

  const handleSelectContact = (contact: Contact) => {
    setSelectedContact(contact);
  };

  const handleSendMessage = () => {
    if (selectedContact && newMessage.trim()) {
      const updatedMessages = { ...messages };
      if (!updatedMessages[selectedContact.id]) {
        updatedMessages[selectedContact.id] = [];
      }
      updatedMessages[selectedContact.id].push({ sender: 'You', content: newMessage });
      setMessages(updatedMessages);
      setNewMessage('');
    }
  };

  return (
    <Box display="flex" height="90vh">
      {open && <AddMemberDialog open={open} setOpen={setOpen} />}
      {/* Contact List */}
      <Box width="25%" borderRight="1px solid #ccc">
        <Box display={'flex'} borderBottom="1px solid #ccc" justifyContent={'space-between'} alignItems={'center'}>
          <Typography variant="h6" p={2}>
            Staff List
          </Typography>
          <Button onClick={() => setOpen(true)} sx={{ height: 40, marginRight: 1 }} variant="contained" size="small">
            + Add member
          </Button>
        </Box>
        <List>
          {chatUsers.map((contact, index) => (
            <>
              <ListItem key={`${index}-staff-chat`} sx={{ padding: 0 }}>
                <ListItemButton
                  // selected={selectedGroup == group.id}
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
                  onClick={() => {}}
                >
                  <Badge
                    overlap="circular"
                    anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                    variant="dot"
                    // color={contact.status === "online" ? "success" : "default"}
                  >
                    <Avatar>{contact.username.split('')?.[0]}</Avatar>
                    {/* <Avatar alt=""} /> */}
                  </Badge>
                  <ListItemText
                    primary={
                      <Box display={'flex'} justifyContent={'space-between'}>
                        <Box display={'flex'} flexDirection={'column'}>
                          <Typography>{contact.username}</Typography>
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
                            {'No Message Yet'}
                          </Typography>
                        </Box>
                        <Box display={'flex'} flexDirection={'column'}>
                          {/* {group?.message_count > 0 && (
                                               <Chip
                                                 variant="filled"
                                                 color="primary"
                                                 size="small"
                                                 label={group?.message_count}
                                                 sx={{ ml: 1 }}
                                               />
                                             )} */}
                          <Typography variant="caption" noWrap sx={{ display: { xs: 'none', md: 'block' } }}>
                            {/* {formatDate(group?.last_message?.messageTimestampUtc)} */}
                          </Typography>
                        </Box>
                      </Box>
                    }
                    sx={{ ml: 2 }}
                  />
                </ListItemButton>
              </ListItem>
              <Divider />
            </>
          ))}
        </List>
      </Box>

      {/* Chat Window */}
      <Box width="75%" display="flex" flexDirection="column">
        {selectedContact ? (
          <>
            <Typography variant="h6" p={2} borderBottom="1px solid #ccc">
              Chat with {selectedContact.name}
            </Typography>
            <Box flexGrow={1} p={2} overflow="auto">
              {messages[selectedContact.id]?.map((msg, index) => (
                <Paper
                  key={index}
                  elevation={1}
                  sx={{ p: 1, mb: 1, alignSelf: msg.sender == 'You' ? 'flex-end' : 'flex-start' }}
                >
                  <Typography variant="body1">
                    <strong>{msg.sender}:</strong> {msg.content}
                  </Typography>
                </Paper>
              ))}
            </Box>
            <Box display="flex" p={2} borderTop="1px solid #ccc">
              <TextField
                fullWidth
                variant="outlined"
                placeholder="Type a message..."
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
                onKeyPress={(e) => {
                  if (e.key === 'Enter') {
                    handleSendMessage();
                  }
                }}
              />
              <IconButton color="primary" onClick={handleSendMessage}>
                <SendIcon />
              </IconButton>
            </Box>
          </>
        ) : (
          <Typography variant="h6" p={2}>
            Select a contact to start chatting
          </Typography>
        )}
      </Box>
    </Box>
  );
};

export default ChatView;
