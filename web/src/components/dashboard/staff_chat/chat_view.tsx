'use client';

import React, { useEffect, useState } from 'react';
import { apiSlice } from '@/redux/apiSlice';
import { useFileUploadMutation, useUploadMultipleFilesMutation, useVideoUploadMutation } from '@/redux/MessageApiSlice';
import { MessageModel } from '@/redux/models/MessageModel';
import { StaffChatModel } from '@/redux/models/StaffChatModel';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { useGetMessagesByPrivateChatIdQuery, useGetStaffChatUsersQuery } from '@/redux/StaffChatApiSlice';
import { Attachment, Close, SearchRounded } from '@mui/icons-material';
import SendIcon from '@mui/icons-material/Send';
import {
  Avatar,
  Badge,
  Box,
  Button,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  IconButton,
  Input,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Paper,
  Popover,
  styled,
  TextField,
  Typography,
} from '@mui/material';
import { Stack } from '@mui/system';
import { File, Video } from '@phosphor-icons/react';
import moment from 'moment';
import ReactImageGallery from 'react-image-gallery';
import InfiniteScroll from 'react-infinite-scroll-component';
import ReactPlayer from 'react-player';
import { useDispatch } from 'react-redux';
import { toast } from 'react-toastify';

import { useSocket } from '@/lib/socketProvider';
import useDebounce from '@/hooks/useDebounce';
import MediaComponent from '@/components/messages/MediaComment';
import MediaPane from '@/components/messages/MediaPane';
import { formatDate } from '@/components/messages/utils';

import AddMemberDialog from './add_member_dialog';
import MessageView from './messge_view';

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

const ChatView: React.FC = () => {
  const [selectedContact, setSelectedContact] = useState<StaffChatModel | null>(null);
  const [messages, setMessages] = useState<MessageModel[]>([]);
  const [newMessage, setNewMessage] = useState<string>('');
  const [chatUsers, setChatUsers] = useState<StaffChatModel[]>([]);
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
  const [file, setFile] = React.useState<any>(null);
  const [previewDialogOpen, setPreviewDialogOpen] = React.useState(false);
  const [caption, setCaption] = React.useState('');
  const [mediaPanel, setMediaPanel] = React.useState<boolean>(false);
  const [pinMessage, setPinMessage] = React.useState<string>('0');
  const [search, setSearch] = useState<string>('');
  const [fileUpload] = useFileUploadMutation();
  const [videoUpload] = useVideoUploadMutation();
  const dispatch = useDispatch();
  const [uploadMultipleFiles, { isLoading: multipleLoader }] = useUploadMultipleFilesMutation();
  const [selectedMessageToReply, setSelectedMessageToReply] = React.useState<MessageModel | null>(null);

  const [anchorElPopOver, setAnchorElPopOver] = React.useState<HTMLButtonElement | null>(null);

  const attachmenPopOver = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorElPopOver(event.currentTarget);
  };

  const handleClosePopOver = () => {
    setAnchorElPopOver(null);
  };
  const openPopOver = Boolean(anchorElPopOver);

  const searchItem = useDebounce(search, 200);
  const searchParam = searchItem;

  const { data, isLoading, isFetching } = useGetStaffChatUsersQuery(
    { search: searchParam },
    { refetchOnMountOrArgChange: true }
  );
  const {
    data: messagesStaff,
    isLoading: loader,
    isFetching: loadMessages,
    refetch,
  } = useGetMessagesByPrivateChatIdQuery(
    {
      id: selectedContact?.chat_id || '',
      page: page,
      pin_type: selectedContact?.isCreatedBy ? 'staff' : 'driver',
      pinMessage,
    },
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
      socket.on('update_file_sent_status_staff', (data: any) => {
        setMessages((prev) =>
          prev.map((e) => (e.id === data?.messageId ? { ...e, url_upload_type: data?.status } : e))
        );
      });

      socket.on('staff_chat_count_increment', (data: any) => {
        setChatUsers((prev) => {
          return prev.map((e) => {
            if (e.chat_id == data.chat_id) {
              if (data.type == 'reciverCount') {
                return { ...e, reciverCount: e.reciverCount + 1 };
              } else {
                return { ...e, senderCount: e.senderCount + 1 };
              }
            }
            return e;
          });
        });
      });

      socket.on('mark_all_message_seen', (data: any) => {
        if (selectedContact?.chat_id == data.chat_id) {
          setMessages((prev) =>
            prev.map((e) => {
              return { ...e, deliveryStatus: 'seen' };
            })
          );
        }
      });
      socket.on('staff_chat_count_decrement', (data: any) => {
        setChatUsers((prev) => {
          return prev.map((e) => {
            if (e.chat_id == data.chat_id) {
              if (data.type == 'reciverCount') {
                return { ...e, reciverCount: 0 };
              } else {
                return { ...e, senderCount: 0 };
              }
            }
            return e;
          });
        });
      });
      socket.on('delete_message', (data: any) => {
        setMessages((prev) => prev.filter((e) => e.id != data));

        toast.error('Deleted message successfully');
      });

      socket.on('pin_done_web', (data: any) => {
        console.log(data);
        if (data.value == '0') {
          toast.success('Un-pin message successfully');
        } else {
          toast.success('Pin message successfully');
        }

        setMessages((prev) =>
          prev.map((e) => {
            if (e.id === data?.messageId) {
              // Determine the property to update based on data.type
              const updatedField = data?.type === 'driver' ? { driverPin: data?.value } : { staffPin: data?.value };

              // Return the updated message object
              return { ...e, ...updatedField };
            }
            return e;
          })
        );
      });

      return () => {
        socket.off('pin_done_web');
        socket.off('delete_message');
        socket.off('staff_chat_count_decrement');
        socket.off('staff_chat_count_increment');
        socket.off('mark_all_message_seen');
        socket.off('send_message_compelete');
        socket.off('typingUser');
        socket.off('update_file_sent_status_staff');
      };
    }
  }, [socket, isConnected, selectedContact?.chat_id]);
  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearch(event.target.value);

    setChatUsers([]);
    setSelectedContact(null);
  };

  const handleSendMessage = () => {
    if (isConnected) {
      socket.emit('staff_message_send', {
        body: newMessage,
        messageDirection: 'S',
        type: 'active',
        private_chat_id: selectedContact?.chat_id,
        url:null,
        thumbnail:null,
        r_message_id:selectedMessageToReply?.id || null,
    
      });
      if(selectedMessageToReply){
        setSelectedMessageToReply(null)
      }
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
  const handleCancel = () => {
    setPreviewDialogOpen(false); // Close the preview dialog without sending
    setFile(null);
  };

  const handleIconClick = () => {
    document?.getElementById('file-input')?.click(); // Trigger the click event of the hidden file input
  };
  const [files, setFiles] = React.useState<any>([]);

  const handleFileChange = (event: any) => {
    //console.log(event.target.files)
    const selectedFile = event.target.files[0];
    if (selectedFile) {
      //setFile(selectedFile);
      const selectedFiles = Array.from(event.target.files);
      setFiles(selectedFiles);
      setPreviewDialogOpen(true);
    }
  };

  const handleVedioClick = () => {
    document?.getElementById('file-input-vedio')?.click();
  };
  const handleFileChangeVedio = (event: any) => {
    //console.log(event.target.files)
    const selectedFile = event.target.files[0];
    if (selectedFile) {
      setFile(selectedFile);
      //   const selectedFiles = Array.from(event.target.files);
      //  setFiles(selectedFiles);
      setPreviewDialogOpen(true);
    }
  };
  async function sendFiles() {
    try {
      dispatch(showLoader());

      let formData = new FormData();

      formData.append('body', caption);
      formData.append('type', '');
      formData.append('channelId', '');
      //  formData.append("files",files)

      for (const file of files) {
        formData.append('files', file, file.name);
      }

      const res = await uploadMultipleFiles({
        formData: formData,
        userId: selectedContact?.id,
        groupId: '',
        location: 'message',
        source: 'message',
        uploadBy: 'staff_group',
        private_chat_id: selectedContact?.chat_id,
      }).unwrap();
      if (res?.status) {
        setFiles([]);
        setCaption('');
        setPreviewDialogOpen(false);
        dispatch(hideLoader());
      }
      dispatch(hideLoader());
      console.log(res);
    } catch (error) {
      dispatch(hideLoader());
      console.log(error);
    }
  }
  async function sendMessage() {
    try {
      const extension = file.name?.split('.')[file.name?.split('.').length - 1];

      const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'flv', 'webm', 'mpeg', 'mpg', 'wmv'];
      dispatch(showLoader());
      if (selectedContact) {
        let formData = new FormData();
        formData.append('file', file);
        formData.append('userId', selectedContact.id);
        formData.append('source', 'message');
        formData.append('groupId', '');
        formData.append(
          'type',
          file.type.startsWith('image/') ? 'media' : videoExtensions.includes(extension) ? 'media' : 'doc'
        );
        const res = videoExtensions.includes(extension)
          ? await videoUpload({
              formData,
              userId: selectedContact.id,
              groupId: '',
              private_chat_id: selectedContact?.chat_id,
            }).unwrap()
          : await fileUpload({ formData, private_chat_id: selectedContact?.chat_id }).unwrap();
        if (res.status) {
          if (isConnected) {
            socket.emit('staff_message_send', {
              body: caption,
              messageDirection: 'S',
              type: 'active',
              private_chat_id: selectedContact?.chat_id,
              url: res?.data?.key,
              thumbnail: res?.data?.thumbnail,
            });
          }

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

  const renderFilePreview = () => {
    const extension = file.name?.split('.')[file.name?.split('.').length - 1];

    const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'flv', 'webm', 'mpeg', 'mpg', 'wmv'];

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
    } else if (videoExtensions.includes(extension)) {
      return <ReactPlayer height={200} width={500} url={URL.createObjectURL(file)} controls={true} />;
    } else {
      return <div>File Preview Not Available</div>;
    }
  };
  function onHandlePin() {
    setMessages([]);
  }
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
        <Box sx={{ mt: 2, pb: 1.5 }}>
          <Input
            value={search}
            onChange={handleSearchChange}
            size="small"
            startAdornment={<SearchRounded />}
            placeholder="Search"
            aria-label="Search"
            fullWidth
          />
        </Box>
        <List>
          {chatUsers.map((contact, index) => (
            <>
              <ListItem key={`${index}-staff-chat`} sx={{ padding: 0 }}>
                <ListItemButton
                  disabled={selectedContact?.chat_id == contact.chat_id}
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
                      socket.emit('unread_staff_message', {
                        chat_id: contact.chat_id,
                        user_id: contact.id,
                        type: contact.isCreatedBy == false ? 'reciverCount' : 'senderCount',
                      });
                      setChatUsers((prev) => {
                        return prev.map((e) => {
                          if (e.chat_id == contact.chat_id) {
                            if (contact.isCreatedBy == false) {
                              return { ...e, reciverCount: 0 };
                            } else {
                              return { ...e, senderCount: 0 };
                            }
                          }
                          return e;
                        });
                      });
                      dispatch(apiSlice.util.invalidateTags(['dashboard', 'channels']));
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
                            <Chip
                              variant="filled"
                              color="primary"
                              size="small"
                              label={contact?.reciverCount}
                              sx={{ ml: 1 }}
                            />
                          )}
                          {contact.isCreatedBy && contact?.senderCount > 0 && (
                            <Chip
                              variant="filled"
                              color="primary"
                              size="small"
                              label={contact?.senderCount}
                              sx={{ ml: 1 }}
                            />
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
            <Stack
              direction="row"
              spacing={2}
              sx={{ alignItems: 'center', justifyContent: 'space-between' }}
              padding={2}
            >
              <div style={{ display: 'flex', alignItems: 'center' }}>
                <Avatar alt={selectedContact?.username} src={''} />
                <div style={{ width: '20px' }}></div>
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
              <div>
                <Button
                  onClick={() => setMediaPanel((prev) => !prev)}
                  variant="outlined"
                  size="small"
                  sx={{ display: { xs: 'none', md: 'inline-flex', marginRight: 6 } }}
                >
                  {mediaPanel ? 'View Messages' : 'View Media'}
                </Button>

                <Button
                  onClick={() => {
                    setPage(1);
                    setPinMessage((prev) => (prev == '0' ? '1' : '0'));
                    onHandlePin();
                  }}
                  variant={pinMessage == '0' ? 'outlined' : 'contained'}
                  size="small"
                  sx={{ display: { xs: 'none', md: 'inline-flex' } }}
                >
                  {pinMessage == '0' ? 'View Pin Messages' : 'View All Messages'}
                </Button>
              </div>
            </Stack>
            <Divider />
            {mediaPanel ? (
              <MediaPane private_chat_id={selectedContact.chat_id} />
            ) : (
              <>
                {' '}
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
                      {messages.map((msg, index) => {
                        const currentDate = moment.utc(msg.messageTimestampUtc).format('MM-DD-YYYY');
                        const previousDate =
                          index > 0 ? moment.utc(messages?.[index - 1].messageTimestampUtc).format('MM-DD-YYYY') : null;
                        const isDifferentDay = previousDate && currentDate !== previousDate;
                        const isToday = currentDate === moment.utc().format('MM-DD-YYYY');
                        const isYou = msg.messageDirection === 'S';
                        return (
                          <MessageView
                            setSelectedMessageToReply={setSelectedMessageToReply}
                            selectedContact={selectedContact}
                            msg={msg}
                          />
                        );
                      })}
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
                {selectedMessageToReply && (
                  <Box sx={{ mb: 1, mx: 2, px: 2, pb: 1, background: 'white', borderLeft: '6px solid blue' }}>
                    {selectedMessageToReply?.url ? (
                      <Paper
                        variant="outlined"
                        sx={{
                          px: 1.75,
                          py: 1.25,
                          borderRadius: 'lg',
                          // borderTopRightRadius: isSent ? 0 : 'lg',
                          // borderTopLeftRadius: isSent ? 'lg' : 0,
                        }}
                      >
                        <MediaComponent
                          thumbnail={`https://ciity-sms.s3.us-west-1.amazonaws.com/${selectedMessageToReply?.thumbnail}`}
                          url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${selectedMessageToReply?.url}`}
                          name={selectedMessageToReply?.url ? selectedMessageToReply?.url : ' '}
                        />
                        {selectedMessageToReply?.body && (
                          <Typography sx={{ fontSize: 16 }}>{selectedMessageToReply?.body}</Typography>
                        )}
                      </Paper>
                    ) : (
                      <>
                        <Stack direction="row" spacing={2} sx={{ justifyContent: 'space-between', mb: 0.25 }}>
                          {' '}
                          <Box sx={{ display: 'flex' }}>
                            <Typography variant="body2">
                              {selectedMessageToReply?.messageDirection === 'S'
                                ? selectedMessageToReply?.sender?.username
                                  ? `${selectedMessageToReply?.sender?.username}(staff)`
                                  : '(staff)'
                                : `${selectedMessageToReply?.sender?.username}(driver)`}
                            </Typography>
                            <Box sx={{ width: '20px' }}></Box>
                            <Typography variant="caption">
                              {moment(selectedMessageToReply?.messageTimestampUtc).format('YYYY-MM-DD HH:mm')}
                            </Typography>
                          </Box>
                          <IconButton
                            onClick={() => {
                              setSelectedMessageToReply(null);
                            }}
                          >
                            <Close />
                          </IconButton>
                        </Stack>
                        <Typography sx={{ fontSize: 16, whiteSpace: 'pre-wrap' }}>
                          {selectedMessageToReply?.body}
                        </Typography>
                      </>
                    )}
                  </Box>
                )}
                <Box display="flex" p={2} borderTop="1px solid #ccc">
                  <input
                    id="file-input-vedio"
                    type="file"
                    accept="video/*"
                    style={{ display: 'none' }}
                    onChange={handleFileChangeVedio}
                  />
                  <input
                    multiple
                    id="file-input"
                    type="file"
                    style={{ display: 'none' }} // Hide the input element
                    onChange={handleFileChange} // Handle file selection
                  />
                  <IconButton onClick={attachmenPopOver}>
                    <Attachment />
                  </IconButton>
                  <Popover
                    id={`attachment-popover`}
                    open={openPopOver}
                    anchorEl={anchorElPopOver}
                    onClose={handleClosePopOver}
                    // anchorOrigin={{
                    //   vertical: 'bottom',
                    //   horizontal: 'left',
                    // }}
                  >
                    <List disablePadding>
                      <ListItem disablePadding>
                        <ListItemButton onClick={handleIconClick}>
                          <ListItemIcon>
                            <File />
                          </ListItemIcon>
                          <ListItemText primary="Media/Docs" />
                        </ListItemButton>
                      </ListItem>
                      <Divider />
                      <ListItem disablePadding>
                        <ListItemButton onClick={handleVedioClick}>
                          <ListItemIcon>
                            <Video />
                          </ListItemIcon>
                          <ListItemText primary={'Video'} />
                        </ListItemButton>
                      </ListItem>
                      <Divider />
                    </List>
                  </Popover>
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
            )}
          </>
        ) : (
          <Typography variant="h6" p={2}>
            Select a contact to start chatting
          </Typography>
        )}
      </Box>
      {previewDialogOpen && (
        <Dialog open={previewDialogOpen} onClose={handleCancel} fullWidth>
          <DialogTitle>Selected File</DialogTitle>
          <DialogContent>
            <div style={{ display: 'flex', flexDirection: 'column', alignContent: 'center' }}>
              {/* Render file preview */}
              {files.length > 0 ? <MediaGallery mediaFiles={files} /> : renderFilePreview()}

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
            <Button
              disabled={isLoading || multipleLoader}
              onClick={files.length ? sendFiles : sendMessage}
              color="primary"
            >
              Send {(isLoading || multipleLoader) && <CircularProgress />}
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </Box>
  );
};

export default ChatView;

const MediaGallery = ({ mediaFiles }: any) => {
  const galleryItems = mediaFiles.map((file: any) => {
    const objectUrl = URL.createObjectURL(file);
    const extension = file.name.split('.').pop().toLowerCase();
    const isVideo = ['mp4', 'mkv', 'avi', 'mov', 'flv', 'webm', 'mpeg', 'mpg', 'wmv'].includes(extension);
    const isPDF = extension === 'pdf';

    return {
      original: objectUrl,
      thumbnail: objectUrl,
      renderItem: () =>
        isVideo ? (
          <video controls style={{ width: '100%', height: '75vh' }}>
            <source src={objectUrl} type={file.type} />
            Your browser does not support the video tag.
          </video>
        ) : isPDF ? (
          <iframe src={objectUrl} title={file.name} style={{ width: '100%', height: '75vh' }} />
        ) : (
          <img src={objectUrl} alt={file.name} style={{ height: '75vh' }} />
        ),
    };
  });

  return <ReactImageGallery items={galleryItems} showThumbnails={false} />;
};
