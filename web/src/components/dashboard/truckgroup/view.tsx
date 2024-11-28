'use client';

import React, { useCallback, useEffect, useRef, useState } from 'react';
import { useGetGroupByIdQuery, useGetGroupMessagesQuery, useGetGroupsQuery } from '@/redux/GroupApiSlice';
import { useFileUploadMutation } from '@/redux/MessageApiSlice';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { AttachFile } from '@mui/icons-material';
import {
  Avatar,
  Badge,
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
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
import { styled } from '@mui/system';
import moment from 'moment';
import { BsCheckAll } from 'react-icons/bs';
import { FiSearch, FiSend } from 'react-icons/fi';
import { useDispatch } from 'react-redux';

import { useSocket } from '@/lib/socketProvider';
import MediaComponent from '@/components/messages/MediaComment';

import AddGroupDialog from './component/AddGroupDialog';
import GroupDetail from './component/GroupDetail';
import GroupHeader from './component/GroupHeader';

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
  backgroundColor: isOwn ? '#635bff' : '#e4e4e4',
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
  '&:hover': {
    cursor: 'pointer',
  },
});

const ChatInterface = ({ type }: { type: string }) => {
  const { socket } = useSocket();

  const [open, setOpen] = useState<boolean>(false);
  const [newMessage, setNewMessage] = useState<string>('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const messagesEndRef = useRef<HTMLDivElement | null>(null);
  const [senderId,setSenderId] = useState<string>("")
  const [viewDetailGroup, setViewDetailGroup] = useState<boolean>(false);

  const { data: groupList } = useGetGroupsQuery({ type: type });

  const [messages, setMessages] = useState<any>([]);

  const [selectedGroup, setSelectedGroup] = useState<string>('');
  const [selectedChannel, setSelectedChannel] = useState<string>('');
  const [fileUpload] = useFileUploadMutation();
  const dispatch = useDispatch();
  const [file, setFile] = React.useState<any>(null);
  const [previewDialogOpen, setPreviewDialogOpen] = React.useState(false);
  const [caption, setCaption] = React.useState('');
  const { data: group, isFetching } = useGetGroupByIdQuery(
    { id: selectedGroup },
    {
      skip: !selectedGroup,
      refetchOnMountOrArgChange: true,
    }
  );

  const { data: groupMessage } = useGetGroupMessagesQuery(
    { channel_id: selectedChannel, group_id: selectedGroup },
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

  const handleFileChange = (event: any) => {
    const selectedFile = event.target.files[0];
    if (selectedFile) {
      setFile(selectedFile);
      setPreviewDialogOpen(true);
    }
  };

  const renderFilePreview = () => {
    if (file && file.type.startsWith('image/')) {
      // Display image preview for images
      return (
        <img
          src={URL.createObjectURL(file)}
          alt="Preview"
          style={{ maxWidth: '100%', maxHeight: 300, objectFit: 'contain' }}
        />
      );
    } else if (file && file.type === 'application/pdf') {
      // Display placeholder for PDF files
      return <div>PDF Preview (placeholder)</div>;
    } else {
      return <div>File Preview Not Available</div>;
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
    if (type == 'truck') {
      if (group?.status && group?.data?.messages) {
        setMessages(group?.data?.messages || []);
        setTimeout(() => {
          scrollToBottom();
        }, 100);
      }
    } else {
      if (groupMessage?.data) {
        setMessages(groupMessage?.data.messages || []);
        setSenderId(groupMessage?.data?.senderId)
        setTimeout(() => {
          scrollToBottom();
        }, 100);
      }
    }
  }, [group, groupMessage]);

  useEffect(() => {
    if (socket) {

      if(type == "group"){
        socket.on('new_group_message_received', handleReceiveMessage);
      }else{
        socket.on('receive_message_group', handleReceiveMessage);
      }


      // Cleanup the event listener when the component unmounts or socket changes
      return () => {
        if(type == "group"){
          socket.off('new_group_message_received', handleReceiveMessage);
        }else{
          socket.off('receive_message_group', handleReceiveMessage);
        }

      };
    }
  }, [socket]);

  useEffect(() => {
    scrollToBottom();
  }, [group]);
  const handleCancel = () => {
    setPreviewDialogOpen(false); // Close the preview dialog without sending
    setFile(null);
  };
  const handleSendMessage = async () => {
    if (!newMessage.trim()) return;

    try {
      // userId,groupId,body,direction,url

      if (type == 'group') {
        socket.emit('send_group_message', {
          groupId: selectedGroup,
          channelId: selectedChannel,
          body: newMessage,
          direction: 'S',
          url: '',
        });
      } else {
        if (group?.data) {
          const userIds = group.data.members
            .filter((e) => e.userProfileId && e.status == 'active')
            .map((e) => e.userProfileId);

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
  const handleIconClick = () => {
    document?.getElementById('file-input')?.click(); // Trigger the click event of the hidden file input
  };

  async function sendMessage() {
    try {
      dispatch(showLoader());
      if (group?.data) {
        const userIds = group.data.members
          .filter((e) => e.userProfileId && e.status == 'active')
          .map((e) => e.userProfileId);
        if (userIds.length == 0) {
          alert('Please Add member before send message into group');
          dispatch(hideLoader());
          return;
        }
        let formData = new FormData();
        formData.append('file', file);
        formData.append('userId', '');
        formData.append('groupId', group.data.group.id);
        formData.append('type', file.type.startsWith('image/') ? 'media' : 'doc');
        const res = await fileUpload(formData).unwrap();
        if (res.status) {
          socket?.emit('send_message_to_user_by_group', {
            userId: userIds?.join(','),
            groupId: selectedGroup,
            body: caption,
            url: res?.data?.key,
            direction: 'S',
          });
          setFile(null);
          setCaption('');
          setPreviewDialogOpen(false);
          dispatch(hideLoader());
        }
      }
    } catch (error) {
      dispatch(hideLoader());
      console.log(error);
    }
  }

  return (
    <Grid container>
      {open && <AddGroupDialog open={open} setOpen={setOpen} type={type} />}

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
                        if(type == "group"){
                          socket.emit(
                            "group_user_add", {"channel_id": group.group_channel.channelId, "group_id": group.id});
                        }else{
                          socket?.emit('staff_open_truck_group', group.id);
                        }

                        setSelectedGroup(group.id);
                        setSelectedChannel(group.group_channel.channelId);
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
          <GroupHeader isBack={true} setViewDetailGroup={setViewDetailGroup} group={group} />

          <Divider />

          {group && (
            <GroupDetail
              type={type}
              group={group.data}
              setViewDetailGroup={setViewDetailGroup}
              setSelectedGroup={setSelectedGroup}
            />
          )}
        </Grid>
      ) : (
        <Grid item xs={12} md={9}>
          {selectedGroup ? (
            group && group?.data ? (
              <Box sx={{ height: '90vh', display: 'flex', flexDirection: 'column' }}>
                <GroupHeader isBack={false} setViewDetailGroup={setViewDetailGroup} group={group} />
                <Divider />
                <MessagesContainer>
                  {messages.map((msg: any) => (
                    <MessageBubble key={msg.id} isOwn={msg.senderId == senderId}>
                      {msg.url && (
                        <Paper
                          variant="outlined"
                          sx={{
                            px: 1.75,
                            py: 1.25,
                          }}
                        >
                          <MediaComponent
                            url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${msg.url}`}
                            name={msg.url ? msg.url : ' '}
                          />
                        </Paper>
                      )}
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
                  <input
                    id="file-input"
                    type="file"
                    style={{ display: 'none' }} // Hide the input element
                    onChange={handleFileChange} // Handle file selection
                  />
                  <IconButton onClick={handleIconClick}>
                    <AttachFile />
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
      {previewDialogOpen && (
        <Dialog open={previewDialogOpen} onClose={handleCancel} fullWidth>
          <DialogTitle>Selected File</DialogTitle>
          <DialogContent>
            <div style={{ display: 'flex', flexDirection: 'column', alignContent: 'center' }}>
              {/* Render file preview */}
              {renderFilePreview()}

              {/* Input for file description */}
              <TextField
                fullWidth
                placeholder="Enter file description..."
                multiline
                value={caption}
                onChange={(event) => setCaption(event.target.value)}
                sx={{ marginTop: 2 }}
              />
            </div>
          </DialogContent>
          <DialogActions>
            <Button onClick={handleCancel} color="secondary">
              Cancel
            </Button>
            <Button disabled={isLoading} onClick={sendMessage} color="primary">
              Send {isLoading && <CircularProgress />}
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </Grid>
  );
};

export default ChatInterface;
