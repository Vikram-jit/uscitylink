'use client';

import React, { useEffect, useState } from 'react';
import { MessageModel } from '@/redux/models/MessageModel';
import { StaffChatModel } from '@/redux/models/StaffChatModel';
import { useGetMessagesByPrivateChatIdQuery, useGetStaffChatUsersQuery } from '@/redux/StaffChatApiSlice';
import { Done, DoneAll } from '@mui/icons-material';
import SendIcon from '@mui/icons-material/Send';
import {
  Avatar,
  Badge,
  Box,
  Button,
  Chip,
  Divider,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  Paper,
  styled,
  TextField,
  Typography,
} from '@mui/material';
import { Stack } from '@mui/system';
import { BsCheckAll } from 'react-icons/bs';
import InfiniteScroll from 'react-infinite-scroll-component';

import { useSocket } from '@/lib/socketProvider';
import MediaComponent from '@/components/messages/MediaComment';
import { formatDate } from '@/components/messages/utils';

import AddMemberDialog from './add_member_dialog';

interface Contact {
  id: number;
  name: string;
}

const MessagesContainer = styled(Box)({
  flex: 1,
  overflow: 'auto',
  padding: '20px',
  display: 'flex',
  flexDirection: 'column-reverse',
  gap: '10px',
  backgroundColor: '#fff',
});

const MessageBubble = styled(Paper)(({ isOwn }: { isOwn: boolean }) => ({
  padding: '10px 15px',
  maxWidth: '65%',
  wordBreak: 'break-word',
  backgroundColor: isOwn ? '#635bff' : '#e4e4e4',
  color: isOwn ? '#fff' : '#111b21',
  alignSelf: isOwn ? 'flex-end' : 'flex-start',
  borderRadius: '7.5px',
  position: 'relative',
  boxShadow: '0 1px 0.5px rgba(11,20,26,.13)',
}));

const ChatView: React.FC = () => {
  const [selectedContact, setSelectedContact] = useState<StaffChatModel | null>(null);
  const [messages, setMessages] = useState<MessageModel[]>([]);
  const [newMessage, setNewMessage] = useState<string>('');
  const [chatUsers, setChatUsers] = useState<StaffChatModel[]>([]);
  const { data, isLoading, isFetching } = useGetStaffChatUsersQuery();
  const [open, setOpen] = useState<boolean>(false);
  const { socket, isConnected } = useSocket();
  const [page, setPage] = useState<number>(1);
  const messagesContainerRef = React.useRef<HTMLDivElement | null>(null);
  const [isTyping, setIsTyping] = React.useState<boolean>(false);
  const [hasMore, setHasMore] = React.useState<boolean>(true);
  const [showScrollToBottomButton, setShowScrollToBottomButton] = React.useState(false);
  const [typingStartTime, setTypingStartTime] = React.useState<number>(0);
  const [userTypingMessage, setUserTypingMessage] = React.useState<string>('');
  const [userTyping, setUserTyping] = React.useState<boolean>(false);

  const {
    data: messagesStaff,
    isLoading: loader,
    isFetching: loadMessages,
    refetch,
  } = useGetMessagesByPrivateChatIdQuery(
    { id: selectedContact?.chat_id || '', page: page },
    {
      skip: !selectedContact,
    }
  );

  useEffect(() => {
    if (messagesStaff && messagesStaff.status) {
      if (page == 1) {
        setMessages([]);
      }
      setMessages((prevMessages) => {
        const newMessages = messagesStaff.data.messages.filter(
          (message) => !prevMessages.some((prevMessage) => prevMessage.id === message.id)
        );
        return [...prevMessages, ...newMessages];
      });
      setHasMore(messagesStaff.data.pagination.currentPage < messagesStaff.data.pagination.totalPages);
    }
  }, [selectedContact, loadMessages, page, loader]);

  const loadMoreMessages = () => {
    if (hasMore && !isLoading) {
      setPage((prevPage) => prevPage + 1);
    }
  };

  React.useEffect(() => {
    if (selectedContact?.chat_id) {
      // Resetting all necessary states when userId changes
      setMessages([]);
      setNewMessage('');
      setPage(1);
      // setHasMore(true);
      if (messagesContainerRef.current) {
        messagesContainerRef.current.scrollTo({
          top: 1,
          behavior: 'smooth',
        });
      }
    }
  }, [selectedContact?.chat_id]);

  useEffect(() => {
    if (data?.status) {
      setChatUsers(data?.data);
    }
  }, [isFetching]);

  useEffect(() => {
    if (socket) {
      socket.on('send_message_compelete', (data: MessageModel) => {
        if (data.private_chat_id == selectedContact?.chat_id) {
          setMessages((prev) => [data, ...prev]);
        }
      });
      socket.on('typingStaffChat', (data: { chat_id: string; typing: boolean; message: string }) => {
        if (data.chat_id == selectedContact?.chat_id) {
          if (data?.typing) {
            setUserTyping(data?.typing);
            setUserTypingMessage(data?.message);
          } else {
            setUserTyping(data?.typing);
            setUserTypingMessage('');
          }
        }
      });
      return () => {
        socket.off('send_message_compelete');
        socket.off('typingUser');
      };
    }
  }, [socket, isConnected, selectedContact?.chat_id]);

  const handleSendMessage = () => {
    if (isConnected) {
      socket.emit('staff_message_send', {
        body: newMessage,
        messageDirection: 'S',
        type: 'active',
        private_chat_id: selectedContact?.chat_id,
      });
      setNewMessage('');
    }
  };
  const handleScroll = () => {
    const container = messagesContainerRef.current;

    if (container) {
      if (container?.scrollTop > -200) {
        setShowScrollToBottomButton(false);
      } else {
        setShowScrollToBottomButton(true);
      }
    }
  };

  const handleKeyDown = () => {
    if (!isTyping) {
      setIsTyping(true);
      sendTypingStatus(true);
    }
    setTypingStartTime(Date.now());
  };

  const checkIfTypingStopped = () => {
    if (isTyping && Date.now() - typingStartTime > 1500) {
      setIsTyping(false);
      sendTypingStatus(false);
    }
  };

  React.useEffect(() => {
    const interval = setInterval(() => {
      checkIfTypingStopped();
    }, 500);

    return () => {
      clearInterval(interval);
    };
  }, [isTyping, typingStartTime]);

  const sendTypingStatus = (isTyping: Boolean) => {
    socket.emit('typing_staff_to_staff_chat', {
      chat_id: selectedContact?.chat_id,
      user_id: selectedContact?.id,
      isTyping,
    });
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
                  selected={selectedContact?.chat_id == contact.chat_id}
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
                  onClick={() => {
                    if (socket) {
                      socket.emit('update_staff_open_staff_chat', contact.chat_id);
                    }
                    setMessages([]);
                    setPage(1);
                    setSelectedContact(contact);
                  }}
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
                              WebkitLineClamp: 2,
                              '&:hover': {
                                color: 'grey',
                              },
                            }}
                          >
                            {contact.last_message ? (
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
                                {contact?.last_message?.body}
                              </Typography>
                            ) : (
                              'No Message Yet'
                            )}
                          </Typography>
                        </Box>
                        <Box sx={{ lineHeight: 1.5, textAlign: 'right' }}>
                        {contact.isCreatedBy == false && contact?.reciverCount > 0 && (
                <Chip variant="filled" color="primary" size="small" label={ contact?.reciverCount} sx={{ ml: 1 }} />
              )}
              {contact.isCreatedBy && contact?.senderCount > 0 && (
                <Chip variant="filled" color="primary" size="small" label={ contact?.senderCount} sx={{ ml: 1 }} />
              )}
                          {contact.last_message && (
                            <Typography variant="caption" noWrap sx={{ display: { xs: 'none', md: 'block' } }}>
                              {formatDate(contact?.last_message?.messageTimestampUtc)}
                            </Typography>
                          )}
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
            <Stack direction="row" spacing={2} sx={{ alignItems: 'center' }} padding={2}>
              <Avatar alt={selectedContact?.username} src={''} />
              <div>
                <Typography variant="h6" noWrap sx={{ fontWeight: 'fontWeightBold' }}>
                  {selectedContact?.username}

                  {/* {sender?.isOnline && (
              <Chip
                size="small"
                color="success"
                sx={{ ml: 1 }}
                icon={<CircleIcon sx={{ fontSize: 12 }} />}
                label="Online"
              />
            )} */}
                </Typography>

                {/* <Typography marginTop={1} variant="body2">{sender?.isOnline ? "online" : sender?.last_login ? moment(sender?.last_login).format('YYYY-MM-DD HH:mm') :'' }</Typography> */}
              </div>
            </Stack>
            <Divider />
            <Box
              sx={{
                display: 'flex',
                flex: 1,
                minHeight: 0,
                px: 2,
                py: 3,
                overflowY: 'scroll',
                flexDirection: 'column-reverse', // Most recent messages at the bottom
              }}
              ref={messagesContainerRef}
            >
              <MessagesContainer id="scrollable-messages-group-container">
                {/* <div ref={messagesEndRef} /> */}
                <InfiniteScroll
                  style={{
                    display: 'flex',
                    flexDirection: 'column-reverse',
                    gap: '10px',
                    padding: '20px',
                  }}
                  onScroll={handleScroll}
                  dataLength={messages.length}
                  next={loadMoreMessages}
                  hasMore={hasMore}
                  loader={<h4>Loading...</h4>}
                  scrollThreshold={0.95}
                  scrollableTarget="scrollable-messages-group-container"
                  inverse={true}
                >
                  {messages.map((msg) => (
                    <>
                      {selectedContact.id == msg.senderId ? (
                        <Box sx={{ display: 'flex', justifyContent: 'flex-start' }}>
                          <Typography variant="caption">{msg?.sender?.username}</Typography>
                          <Badge
                            color={msg?.sender.isOnline ? 'success' : 'default'}
                            variant={msg?.sender.isOnline ? 'dot' : 'standard'}
                            anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
                            overlap="circular"
                          />
                        </Box>
                      ) : (
                        <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
                          <Typography variant="caption">{msg?.sender?.username}</Typography>
                          {msg.deliveryStatus === 'sent' && (
                            <Done
                              sx={{
                                fontSize: 14,
                              }}
                            />
                          )}
                          {msg.deliveryStatus == 'seen' && (
                            <DoneAll
                              sx={{
                                fontSize: 14,
                                color: 'blue',
                              }}
                            />
                          )}
                        </Box>
                      )}
                      <MessageBubble key={msg.id} isOwn={selectedContact.id != msg.senderId}>
                        {msg.url && (
                          <Paper
                            variant="outlined"
                            sx={{
                              px: 1.75,
                              py: 1.25,
                            }}
                          >
                            <MediaComponent
                              type={msg.url_upload_type}
                              messageDirection={msg.messageDirection || 'S'}
                              url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${msg.url}`}
                              name={msg.url ? msg.url : ' '}
                              thumbnail={`https://ciity-sms.s3.us-west-1.amazonaws.com/${msg.thumbnail}`}
                            />
                          </Paper>
                        )}
                        <p style={{ whiteSpace: 'pre-wrap' }}>{msg.body}</p>
                      </MessageBubble>
                    </>
                  ))}
                </InfiniteScroll>
              </MessagesContainer>
            </Box>
            {userTyping && (
              <div
                style={{
                  background: 'gray',
                  borderRadius: '6px',
                  padding: '10px',
                  width: '50%',
                  color: 'white',
                  display: 'flex',
                  justifyContent: 'start',
                  marginLeft: 2,
                  marginBottom: '5px',
                  marginRight: '10px',
                }}
              >
                {userTypingMessage ?? 'Typing...'}
              </div>
            )}
            <Box display="flex" p={2} borderTop="1px solid #ccc">
              <TextField
                onKeyDown={(event) => {
                  handleKeyDown();
                }}
                fullWidth
                variant="outlined"
                placeholder="Type a message..."
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
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
