'use client';

import React, { useCallback, useEffect, useRef, useState } from 'react';
import { useGetGroupByIdQuery, useGetGroupsQuery } from '@/redux/GroupApiSlice';
import Logout from '@mui/icons-material/Logout';
import PersonAdd from '@mui/icons-material/PersonAdd';
import Settings from '@mui/icons-material/Settings';
import {
  Alert,
  Avatar,
  Badge,
  Box,
  Button,
  CircularProgress,
  Divider,
  Grid,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  Paper,
  TextField,
  Typography,
} from '@mui/material';
import ListItemIcon from '@mui/material/ListItemIcon';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import { styled } from '@mui/system';
import { Eye, EyeClosed } from '@phosphor-icons/react';
import moment from 'moment';
import { BsCheckAll, BsEmojiSmile } from 'react-icons/bs';
import { FiMoreVertical, FiPhone, FiPlus, FiSearch, FiSend, FiUsers, FiVideo } from 'react-icons/fi';
import { MdAttachFile } from 'react-icons/md';

import { useSocket } from '@/lib/socketProvider';

import AddGroupDialog from './component/AddGroupDialog';
import GroupDetail from './component/GroupDetail';
import { ArrowBackIos } from '@mui/icons-material';
import AddMemberDialog from './component/AddmemberDialog';

// Styled Components
const MessagesContainer = styled(Box)({
  flex: 1,
  overflow: 'auto',
  padding: '20px',
  display: 'flex',
  flexDirection: 'column',
  gap: '10px',
  backgroundColor: '#fff',
});

const MessageBubble = styled(Paper)(({ isOwn }: { isOwn: boolean }) => ({
  padding: '10px 15px',
  maxWidth: '65%',
  wordBreak: 'break-word',
  backgroundColor: isOwn ? '#635bff' : '#fff',
  color: isOwn ? '#fff' : '#111b21',
  alignSelf: isOwn ? 'flex-end' : 'flex-start',
  borderRadius: '7.5px',
  position: 'relative',
  boxShadow: '0 1px 0.5px rgba(11,20,26,.13)',
}));

const InputContainer = styled(Box)({
  padding: '10px 20px',
  backgroundColor: '#f0f2f5',
  display: 'flex',
  alignItems: 'center',
  gap: '10px',
});

const SidebarContainer = styled(Box)({
  height: '100vh',
  backgroundColor: '#fff',
  borderRight: '1px solid #e0e0e0',

  display: 'flex',
  flexDirection: 'column',
  overflowY: 'auto', // This makes the sidebar scrollable
  maxHeight: '90vh', // Make sure the sidebar does not exceed the viewport height
});

const HeaderContainer = styled(Box)({
  padding: '10px 16px',
  backgroundColor: '#f0f2f5',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
  "&:hover":{
    cursor:"pointer"
  }
});

interface User {
  name: string;
  avatar: string;
  status: 'online' | 'offline';
}

interface Message {
  id: number;
  text: string;
  sender: 'self' | 'other';
  timestamp: Date;
  status: 'sent' | 'read';
  user: User;
}

const ChatInterface: React.FC = () => {
  const { socket } = useSocket();

  const [open, setOpen] = useState<boolean>(false);
  const [newMessage, setNewMessage] = useState<string>('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const messagesEndRef = useRef<HTMLDivElement | null>(null);
  const [addMemberDialog, setAddMemberDialog] = useState<boolean>(false);
  const [viewDetailGroup, setViewDetailGroup] = useState<boolean>(false);

  const { data: groupList } = useGetGroupsQuery({ type: 'truck' });

  const [messages, setMessages] = useState<any>([]);

  const [selectedGroup, setSelectedGroup] = useState<string>('');

  const { data: group, isFetching } = useGetGroupByIdQuery(
    { id: selectedGroup },
    {
      skip: !selectedGroup,
      refetchOnMountOrArgChange: true,
    }
  );

  const scrollToBottom = () => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({
        behavior: 'smooth', // Smooth scrolling
        block: 'end', // Scroll to the bottom
      });
    }
  };
  const handleReceiveMessage = useCallback(
    (message: any) => {
      setMessages((prevMessages: any) => {
        if (prevMessages.some((msg: any) => msg.id === message.id)) {
          return prevMessages;
        }
        return [...prevMessages, message];
      });
      setIsLoading(false);
      setTimeout(() => {
        scrollToBottom();
      }, 100);
    },
    [setMessages, setIsLoading, scrollToBottom]
  );

  useEffect(() => {
    if (group?.status && group?.data?.messages) {
      setMessages(group?.data?.messages || []);
      setTimeout(() => {
        scrollToBottom();
      }, 100);
    }
  }, [group]);

  useEffect(() => {
    if (socket) {
      socket.on('receive_message_group', handleReceiveMessage);

      // Cleanup the event listener when the component unmounts or socket changes
      return () => {
        socket.off('receive_message_group', handleReceiveMessage);
      };
    }
  }, [socket]);

  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const openMenu = Boolean(anchorEl);

  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };
  const handleClose = () => {
    setAnchorEl(null);
  };

  useEffect(() => {
    scrollToBottom();
  }, [group]);

  const handleSendMessage = async () => {
    if (!newMessage.trim()) return;

    try {
      // userId,groupId,body,direction,url

      if (group?.data) {
        const userIds = group.data.members.map((e) => e.userProfileId);
        if (userIds.length == 0) {
          alert('Please Add member before send message into group');
          return;
        }
        setIsLoading(true);
        socket?.emit('send_message_to_user_by_group', {
          userId: userIds?.join(','),
          groupId: selectedGroup,
          body: newMessage,
          direction: 'S',
        });
      }
      setNewMessage('');
      // const data = {}
    } catch (err) {
      setIsLoading(false);
      setError('Failed to send message. Please try again.');
    }
  };

  const formatTimestamp = (timestamp: Date): string => {
    return moment.utc(timestamp).format('HH:mm');
  };

  return (
    <Grid container>
      {open && <AddGroupDialog open={open} setOpen={setOpen} />}
      {/* {addMemberDialog && (
        <AddMemberDialog open={addMemberDialog} setOpen={setAddMemberDialog} groupId={group?.data.group.id ||''} group={group?.data || undefined}/>
      )} */}
      {/* Sidebar (Contact List) */}
      <Grid item xs={12} md={3} sx={{ borderRight: '1px solid #e0e0e0' }}>
        <SidebarContainer>
          <HeaderContainer>
            <Typography variant="h5">Group List</Typography>
            <Box sx={{ display: 'flex', gap: 1 }}>
              <Button onClick={() => setOpen(true)} size="small" variant="contained">
                Add Group
              </Button>
            </Box>
          </HeaderContainer>
          <Box sx={{ p: 2 }}>
            <TextField
              fullWidth
              placeholder="Search groups"
              variant="outlined"
              size="small"
              InputProps={{
                startAdornment: <FiSearch style={{ marginRight: 8 }} />,
              }}
            />
          </Box>
          <List>
            {groupList &&
              groupList?.data?.map((group, index) => (
                <>
                  <ListItem key={index} sx={{ padding: 0 }}>
                    <ListItemButton
                      selected={selectedGroup == group.id}
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
                        socket?.emit('staff_open_truck_group', group.id);
                        setSelectedGroup(group.id);
                        setTimeout(() => {
                          scrollToBottom();
                        }, 100);
                      }}
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
                        primary={group.name}
                        secondary={
                          <Typography
                            sx={{
                              color: 'grey',
                              '&:hover': {
                                color: 'grey',
                              },
                            }}
                          >
                            {group.description}
                          </Typography>
                        }
                        sx={{ ml: 2 }}
                      />
                    </ListItemButton>
                  </ListItem>
                  <Divider />
                </>
              ))}
          </List>
        </SidebarContainer>
      </Grid>

      {/* Group Detail */}

      {viewDetailGroup ? (
        <Grid item xs={12} md={9}>
          <HeaderContainer onClick={() => setViewDetailGroup(false)}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <IconButton onClick={()=>setViewDetailGroup(false)}>
                <ArrowBackIos/>
              </IconButton>
              <Avatar>{group?.data?.group?.name?.split('')?.[0]?.toUpperCase()}</Avatar>
              <Box>
                <Typography variant="subtitle1" sx={{ fontWeight: 'medium' }}>
                  {group?.data?.group?.name}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {group?.data.members?.length == 0
                    ? 'No members yet'
                    : ` Members : ${group?.data.members?.map((e) => e?.UserProfile?.username)?.join(',')}`}
                </Typography>
              </Box>
            </Box>
            <Box sx={{ display: 'flex', gap: 1 }}>
              <IconButton
                onClick={handleClick}
                size="small"
                sx={{ ml: 2 }}
                aria-controls={open ? 'account-menu' : undefined}
                aria-haspopup="true"
                aria-expanded={open ? 'true' : undefined}
              >
                <FiMoreVertical />
              </IconButton>
              <Menu
                anchorEl={anchorEl}
                id="account-menu"
                open={openMenu}
                onClose={handleClose}
                onClick={handleClose}
                slotProps={{
                  paper: {
                    elevation: 0,
                    sx: {
                      overflow: 'visible',
                      filter: 'drop-shadow(0px 2px 8px rgba(0,0,0,0.32))',
                      mt: 1.5,
                      '& .MuiAvatar-root': {
                        width: 32,
                        height: 32,
                        ml: -0.5,
                        mr: 1,
                      },
                      '&::before': {
                        content: '""',
                        display: 'block',
                        position: 'absolute',
                        top: 0,
                        right: 14,
                        width: 10,
                        height: 10,
                        bgcolor: 'background.paper',
                        transform: 'translateY(-50%) rotate(45deg)',
                        zIndex: 0,
                      },
                    },
                  },
                }}
                transformOrigin={{ horizontal: 'right', vertical: 'top' }}
                anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
              >
                <MenuItem onClick={() => setViewDetailGroup(true)}>
                  <ListItemIcon>
                    <Eye fill="fill" fontSize="small" style={{ fontSize: 18 }} />
                  </ListItemIcon>
                  View Details
                </MenuItem>
                {/* <MenuItem onClick={() => setAddMemberDialog(true)}>
                  <ListItemIcon>
                    <Settings fontSize="small" />
                  </ListItemIcon>
                  Add Members
                </MenuItem> */}
              </Menu>
            </Box>
          </HeaderContainer>
          <Divider />

          {group && <GroupDetail group={group.data} setViewDetailGroup={setViewDetailGroup} setSelectedGroup={setSelectedGroup}/>}
        </Grid>
      ) : (
        <Grid item xs={12} md={9}>
          {selectedGroup ? (
            group && group?.data ? (
              <Box sx={{ height: '90vh', display: 'flex', flexDirection: 'column' }}>
                <HeaderContainer onClick={() => setViewDetailGroup(true)} >
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Avatar>{group?.data?.group?.name?.split('')?.[0]?.toUpperCase()}</Avatar>
                    <Box>
                      <Typography variant="subtitle1" sx={{ fontWeight: 'medium' }}>
                        {group?.data?.group?.name}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {group.data.members?.length == 0
                          ? 'No members yet'
                          : ` Members : ${group.data.members?.map((e) => e?.UserProfile?.username)?.join(',')}`}
                      </Typography>
                    </Box>
                  </Box>
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <IconButton
                      onClick={handleClick}
                      size="small"
                      sx={{ ml: 2 }}
                      aria-controls={open ? 'account-menu' : undefined}
                      aria-haspopup="true"
                      aria-expanded={open ? 'true' : undefined}
                    >
                      <FiMoreVertical />
                    </IconButton>
                    <Menu
                      anchorEl={anchorEl}
                      id="account-menu"
                      open={openMenu}
                      onClose={handleClose}
                      onClick={handleClose}
                      slotProps={{
                        paper: {
                          elevation: 0,
                          sx: {
                            overflow: 'visible',
                            filter: 'drop-shadow(0px 2px 8px rgba(0,0,0,0.32))',
                            mt: 1.5,
                            '& .MuiAvatar-root': {
                              width: 32,
                              height: 32,
                              ml: -0.5,
                              mr: 1,
                            },
                            '&::before': {
                              content: '""',
                              display: 'block',
                              position: 'absolute',
                              top: 0,
                              right: 14,
                              width: 10,
                              height: 10,
                              bgcolor: 'background.paper',
                              transform: 'translateY(-50%) rotate(45deg)',
                              zIndex: 0,
                            },
                          },
                        },
                      }}
                      transformOrigin={{ horizontal: 'right', vertical: 'top' }}
                      anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
                    >
                      <MenuItem onClick={() => setViewDetailGroup(true)}>
                        <ListItemIcon>
                          <Eye fill="fill" fontSize="small" style={{ fontSize: 18 }} />
                        </ListItemIcon>
                        View Details
                      </MenuItem>
                      {/* <MenuItem onClick={handleClose}>
                        <ListItemIcon>
                          <Settings fontSize="small" />
                        </ListItemIcon>
                        Add Members
                      </MenuItem> */}
                    </Menu>
                  </Box>
                </HeaderContainer>

                {error && (
                  <Alert severity="error" onClose={() => setError(null)} sx={{ m: 1 }}>
                    {error}
                  </Alert>
                )}
                <Divider />
                <MessagesContainer>
                  {messages.map((msg: any) => (
                    <MessageBubble key={msg.id} isOwn={msg.sender !== 'self'}>
                      {msg.body}
                      <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
                        <Typography variant="caption">{formatTimestamp(msg.messageTimestampUtc)}</Typography>
                        {msg.deliveryStatus === 'seen' && <BsCheckAll />}
                      </Box>
                    </MessageBubble>
                  ))}
                  <div ref={messagesEndRef} />
                </MessagesContainer>

                {/* Input Container */}

                <InputContainer>
                  <IconButton>
                    <MdAttachFile />
                  </IconButton>
                  <TextField
                    fullWidth
                    placeholder="Type a message"
                    variant="outlined"
                    size="small"
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
                  />
                  <IconButton onClick={handleSendMessage} disabled={isLoading}>
                    {isLoading ? <CircularProgress size={24} /> : <FiSend />}
                  </IconButton>
                </InputContainer>
              </Box>
            ) : (
              <Box
                sx={{
                  height: '90vh',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'center',
                  alignItems: 'center',
                }}
              >
                <CircularProgress />
              </Box>
            )
          ) : (
            <Box
              sx={{
                height: '90vh',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                alignItems: 'center',
              }}
            >
              <Typography>Not Selected Group Yet</Typography>
            </Box>
          )}
        </Grid>
      )}
    </Grid>
  );
};

export default ChatInterface;
