'use client';

import React, { useCallback, useEffect, useRef, useState } from 'react';
import { apiSlice } from '@/redux/apiSlice';
import { useGetGroupByIdQuery, useGetGroupMessagesQuery, useGetGroupsQuery } from '@/redux/GroupApiSlice';
import { useFileUploadMutation, useUploadMultipleFilesMutation, useVideoUploadMutation } from '@/redux/MessageApiSlice';
import { GroupModel } from '@/redux/models/GroupModel';
import { MessageModel } from '@/redux/models/MessageModel';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { Add, AttachFile } from '@mui/icons-material';

import 'react-image-gallery/styles/css/image-gallery.css';

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
  Grid,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  Paper,
  Popover,
  TextField,
  Typography,
} from '@mui/material';
import ListItemIcon from '@mui/material/ListItemIcon';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import { Stack, styled } from '@mui/system';
import { Circle, PaperPlane } from '@phosphor-icons/react';
import { File, Video } from '@phosphor-icons/react/dist/ssr';
import moment from 'moment';
import { BsCheckAll } from 'react-icons/bs';
import { FiSearch, FiSend } from 'react-icons/fi';
import ReactImageGallery from 'react-image-gallery';
import InfiniteScroll from 'react-infinite-scroll-component';
import ReactPlayer from 'react-player';
import { useDispatch, useSelector } from 'react-redux';

import { useSocket } from '@/lib/socketProvider';
import useDebounce from '@/hooks/useDebounce';
import DocumentDialog from '@/components/DocumentDialog';
import AvatarWithStatus from '@/components/messages/AvatarWithStatus';
import ChatBubble from '@/components/messages/ChatBubble';
import MediaComponent from '@/components/messages/MediaComment';
import MediaPane from '@/components/messages/MediaPane';
import { formatDate, formatUtcTime } from '@/components/messages/utils';

import TemplateDialog from '../template/TemplateDialog';
import AddGroupDialog from './component/AddGroupDialog';
import GroupDetail from './component/GroupDetail';
import GroupHeader from './component/GroupHeader';
import { generateTempId } from '@/components/messages/MessageInput';

// Styled Components
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

  const [page, setPage] = React.useState(1);
  const [hasMore, setHasMore] = React.useState<boolean>(true);
  const [search, setSearch] = React.useState<string>('');

  const searchItem = useDebounce(search, 200);

  const [open, setOpen] = useState<boolean>(false);
  const [newMessage, setNewMessage] = useState<string>('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const messagesEndRef = useRef<HTMLDivElement | null>(null);
  const [senderId, setSenderId] = useState<string>('');
  const [viewDetailGroup, setViewDetailGroup] = useState<boolean>(false);
  const [currentChannelId, setCurrentChannelId] = useState<string>('');

  const { data: groupList } = useGetGroupsQuery({ type: type, page, search: searchItem });
  const [currentIndex, setCurrentIndex] = React.useState<number | null>(null);
  const [messages, setMessages] = useState<MessageModel[]>([]);

  const [groups, setGroups] = useState<GroupModel[]>([]);
  const [resetKey, setResetKey] = React.useState(Date.now()); // Unique number each time
  const [mResetKey, setMResetKey] = React.useState(Date.now()); // Unique number each time
  const [templateDialog, setTemplateDialog] = React.useState<boolean>(false);
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const openTemplate = Boolean(anchorEl);
  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const { trackChannelState } = useSelector((state: any) => state.channel);
  const handleClose = () => {
    setAnchorEl(null);
  };
  const moveNext = () => {
    if (currentIndex != null) {
      // 1. If we’re already at the last possible index, nothing to do
      if (currentIndex >= messages.length - 1) {
        console.log('No more messages with media.');
        return;
      }

      // 2. Scan forward for the next message that has a non‐empty URL
      for (let i = currentIndex + 1; i < messages.length; i++) {
        const url = messages[i]?.url?.trim();
        if (url) {
          setCurrentIndex(i);
          console.log('Moved to:', messages[i]);
          return;
        }
      }

      console.log('No more messages with media.');
    }
  };

  // Move to the previous message with a URL
  const movePrevious = () => {
    if (currentIndex) {
      // If we're already at 0, nothing to do
      if (currentIndex <= 0) {
        console.log('Reached the beginning. No previous messages with media.');
        return;
      }

      // Walk backwards until we find a message.url
      for (let i = currentIndex - 1; i >= 0; i--) {
        if (messages[i].url?.trim()) {
          setCurrentIndex(i);
          console.log('Moved to:', messages[i]);
          return;
        }
      }

      console.log('Reached the beginning. No previous messages with media.');
    }
  };
  const [anchorElPopOver, setAnchorElPopOver] = React.useState<HTMLButtonElement | null>(null);

  const attachmenPopOver = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorElPopOver(event.currentTarget);
  };

  const handleClosePopOver = () => {
    setAnchorElPopOver(null);
  };
  const openPopOver = Boolean(anchorElPopOver);
  const [uploadMultipleFiles, { isLoading: multipleLoader }] = useUploadMultipleFilesMutation();

  const [selectedGroup, setSelectedGroup] = useState<string>('');
  const [selectedChannel, setSelectedChannel] = useState<string>('');
  const [fileUpload] = useFileUploadMutation();
  const [videoUpload] = useVideoUploadMutation();
  const dispatch = useDispatch();
  const [viewMedia, setViewMedia] = useState<boolean>(false);
  const [file, setFile] = React.useState<any>(null);
  const [previewDialogOpen, setPreviewDialogOpen] = React.useState(false);
  const [caption, setCaption] = React.useState('');
  const [selectedTemplate, setSelectedTemplate] = React.useState<{ name: string; body: string; url?: string }>({
    name: '',
    body: '',
  });
  const [oldGroup, setOldGroup] = useState<string>('');
  const [pageMessage, setPageMessage] = React.useState(1);
  const [hasMoreMessage, setHasMoreMessage] = React.useState<boolean>(true);

  const {
    data: group,
    isFetching,
    isLoading: gLoading,
  } = useGetGroupByIdQuery(
    { id: selectedGroup, page: pageMessage, resetKey },
    {
      skip: !selectedGroup,
      refetchOnMountOrArgChange: false,
    }
  );

  const { data: groupMessage, isLoading: mLoading } = useGetGroupMessagesQuery(
    { channel_id: selectedChannel, group_id: selectedGroup, page: pageMessage, resetKey: mResetKey },
    {
      skip: !selectedGroup,
      refetchOnMountOrArgChange: false,
    }
  );

  useEffect(() => {
    if (trackChannelState > 0) {
      setHasMore(false);
      setHasMoreMessage(false);
      setMessages([]);
      setGroups([]);
    }
  }, [trackChannelState]);

  useEffect(() => {
    if (search.length > 0) {
      setPage(1);
      setHasMore(true);
    }
  }, [search]);

  const scrollToBottom = () => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({
        behavior: 'smooth', // Smooth scrolling
        block: 'start', // Scroll to the bottom
      });
    }
  };

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

  const handleReceiveMessage = useCallback(
    (message: any, groupId: string) => {
      if (message.groupId !== selectedGroup) {
        return; // Ignore the message if the groupId does not match selectedId
      }
      setMessages((prevMessages: any) => {
        if (prevMessages.some((msg: any) => msg.id === message.id)) {
          return prevMessages;
        }
        return [message, ...prevMessages];
      });

      setTimeout(() => {
        scrollToBottom();
      }, 100);
    },
    [setMessages, scrollToBottom]
  );

  useEffect(() => {
    if (groupList?.status && groupList?.data) {
      const newChannelId = groupList?.data?.channel.id;

      // Check if the channel ID has changed
      if (newChannelId !== currentChannelId) {
        setSelectedGroup('');
        setMessages([]);
        // If channel ID has changed, reset the groups and update the current channel ID
        setGroups(groupList?.data?.data);

        setCurrentChannelId(newChannelId);

        setHasMoreMessage(groupList?.data?.pagination.currentPage < groupList?.data?.pagination.totalPages);
        setHasMore(groupList?.data?.pagination.currentPage < groupList?.data?.pagination.totalPages);
      } else {
        setGroups((prevGroups) => {
          const existingGroupIds = new Set(prevGroups.map((group) => group.id));
          const newGroups = groupList?.data?.data.filter((newGroup) => !existingGroupIds.has(newGroup.id));
          return [...prevGroups, ...newGroups];
        });

        setHasMoreMessage(groupList?.data?.pagination.currentPage < groupList?.data?.pagination.totalPages);
        setHasMore(groupList?.data?.pagination.currentPage < groupList?.data?.pagination.totalPages);
      }
    }
  }, [groupList, currentChannelId]);

  useEffect(() => {
    if (oldGroup != '') {
      if (oldGroup != selectedGroup) {
        setMessages([]);
      }
    }
    if (type === 'truck') {
      if (group?.status && group?.data?.messages) {
        setMessages((prevMessages: any) => {
          // Filter out duplicate messages using a unique identifier (e.g., `id`)
          const newMessages = group.data.messages.filter(
            (message: any) => !prevMessages.some((prevMessage: any) => prevMessage.id === message.id)
          );
          return [...prevMessages, ...newMessages];
        });

        setHasMoreMessage(group.data.pagination.currentPage < group.data.pagination.totalPages);
        setSenderId(group?.data?.senderId);
        setOldGroup(group.data.group.id);
      }
    } else {
      if (groupMessage?.data?.messages) {
        setMessages((prevMessages: any) => {
          // Filter out duplicate messages
          const newMessages = groupMessage.data.messages.filter(
            (message: any) => !prevMessages.some((prevMessage: any) => prevMessage.id === message.id)
          );
          return [...prevMessages, ...newMessages];
        });

        setHasMoreMessage(groupMessage.data.pagination.currentPage < groupMessage.data.pagination.totalPages);

        setSenderId(groupMessage?.data?.senderId);
      }
    }
  }, [group, groupMessage, type, selectedGroup]);

  useEffect(() => {
    if (socket) {
      if (type == 'group') {
        socket.on('update_file_upload_status_group', (data: any) => {
          setMessages((prev: any) =>
            prev.map((e: any) => (e.id === data?.messageId ? { ...e, url_upload_type: data?.status } : e))
          );
        });
        socket.on('new_group_message_received', (message: MessageModel) =>
          handleReceiveMessage(message, selectedGroup)
        );
      } else {
        socket.on('update_url_status_truck_group', (data: any) => {
          setMessages((prev: any) =>
            prev.map((e: any) => (e.id === data?.messageId ? { ...e, url_upload_type: data?.status } : e))
          );
        });
        // socket.on('receive_message_group', (message: MessageModel) => handleReceiveMessage(message, selectedGroup));
        socket.on('receive_message_group_truck', (message: MessageModel) =>
          handleReceiveMessage(message, selectedGroup)
        );
      }

      // Cleanup the event listener when the component unmounts or socket changes
      return () => {
        if (type == 'group') {
          socket.off('new_group_message_received', handleReceiveMessage);
        } else {
          //socket.off('receive_message_group', handleReceiveMessage);
          socket.off('receive_message_group_truck', handleReceiveMessage);
        }
      };
    }
  }, [socket, selectedGroup]);

  useEffect(() => {
    scrollToBottom();
  }, [group]);
  const handleCancel = () => {
    setPreviewDialogOpen(false); // Close the preview dialog without sending
    setFile(null);
  };
  //Socket
  const loadMoreMessages = () => {
    if (hasMore && !isLoading) {
      setPage((prevPage) => prevPage + 1);
    }
  };
  const loadMoreGroupMessages = () => {
    if (hasMoreMessage && !isLoading) {
      setPageMessage((prevPage) => prevPage + 1);
    }
  };
  useEffect(() => {
    if (socket) {
      socket.on('update_user_group_list', (message: MessageModel) => {
        if (groups) {
          setGroups((prevGroupList) => {
            if (!prevGroupList) return prevGroupList;

            const updatedUserChannels = prevGroupList.map((group) => {
              if (group.id === message.groupId) {
                return {
                  ...group,
                  message_count: group.message_count + 1,
                  last_message: message,
                };
              }
              return group;
            });

            const updatedUserList = updatedUserChannels.sort((a, b) => {
              if (a.id === message.groupId) return -1;
              if (b.id === message.groupId) return 1;
              return 0;
            });

            return updatedUserList;
          });
        }
      });

      socket.on('update_group_staff_message_count', (groupId: string) => {
        if (groups) {
          setGroups((prevGroupList) => {
            if (!prevGroupList) return prevGroupList;

            const updatedUserChannels = prevGroupList.map((group) => {
              if (group.id === groupId) {
                return {
                  ...group,
                  message_count: 0,
                };
              }
              return group;
            });

            const updatedUserList = updatedUserChannels.sort((a, b) => {
              if (a.id === groupId) return -1;
              if (b.id === groupId) return 1;
              return 0;
            });

            return updatedUserList;
          });
        }
      });
    }
  }, [socket]);

  useEffect(() => {
    if (selectedTemplate) {
      setNewMessage(selectedTemplate?.body);
    }
  }, [selectedTemplate]);

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
          url: selectedTemplate ? selectedTemplate?.url : '',
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
            url: selectedTemplate ? selectedTemplate?.url : '',
          });
        }
      }
      setIsLoading(false);
      setSelectedTemplate({
        name: '',
        body: '',
        url: '',
      });
      setNewMessage('');
      // const data = {}
    } catch (err) {
      setIsLoading(false);
      setError('Failed to send message. Please try again.');
    }
  };
  async function sendFiles() {
    try {
      const userIds = group!.data.members
        .filter((e) => e.userProfileId && e.status == 'active')
        .map((e) => e.userProfileId);
      if (userIds.length == 0) {
        alert('Please Add member before send message into group');
        dispatch(hideLoader());
        return;
      }
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
        userId: '',
        groupId: selectedGroup,
        location: type == 'group' ? 'group' : 'truck',
        source: type == 'group' ? 'group' : 'truck',
        uploadBy: 'staff',
        temp_id:generateTempId()
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

  const formatTimestamp = (timestamp: Date): string => {
    return moment.utc(timestamp).format('hh:mm A');
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
  async function sendMessage() {
    try {
      const extension = file.name?.split('.')[file.name?.split('.').length - 1];

      const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'flv', 'webm', 'mpeg', 'mpg', 'wmv'];
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
        formData.append('source', type);
        formData.append('groupId', group.data.group.id);
        formData.append('type', file.type.startsWith('image/') ? 'media' : 'doc');
        const res = videoExtensions.includes(extension)
          ? await videoUpload({ formData, userId: '', groupId: group.data.group.id }).unwrap()
          : await fileUpload({ formData }).unwrap();
        if (res.status) {
          if (type == 'group') {
            socket?.emit('send_group_message', {
              groupId: selectedGroup,
              channelId: selectedChannel,
              body: newMessage,
              direction: 'S',
              url: res?.data?.key,
              thumbnail: res?.data?.thumbnail,
            });
          } else {
            socket?.emit('send_message_to_user_by_group', {
              userId: userIds?.join(','),
              groupId: selectedGroup,
              body: caption,
              url: res?.data?.key,
              direction: 'S',
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

  const handleReset = () => {
    setMessages([]);
    setPageMessage(1);
    setHasMoreMessage(true);
    setResetKey(Date.now());
    setMResetKey(Date.now());
  };
  const handleGroupChange = (group: any, type: string) => {
    if (type === 'group') {
      setResetKey(Date.now());
      socket.emit('group_user_add', {
        channel_id: group.group_channel.channelId,
        group_id: group.id,
      });
      socket.emit('update_group_staff_message_count', group.id);
    } else {
      setMResetKey(Date.now());
      socket?.emit('staff_open_truck_group', group.id);
    }

    // Reset messages and pagination state
    setMessages([]);
    setPageMessage(1);
    setHasMoreMessage(true);
    setSelectedGroup(''); // Optionally clear the old group first to trigger refetch

    // Set new group and channel
    setSelectedGroup(group.id);
    setSelectedChannel(group.group_channel.channelId);

    // Invalidate cache for relevant tags
    //dispatch(apiSlice.util.invalidateTags(['channels', 'group']));

    // Refetch the data for the new group/channel
    setTimeout(() => {
      // Ensure the messages container is scrolled to the bottom (if needed)
      scrollToBottom();
    }, 100);
  };

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
          <List id="scrollable-channel-container" sx={{ maxHeight: '650px', overflowY: 'auto' }}>
            {
              <InfiniteScroll
                dataLength={groups.length}
                next={loadMoreMessages}
                hasMore={hasMore}
                loader={<h4>Loading...</h4>}
                scrollThreshold={0.95}
                scrollableTarget="scrollable-channel-container"
              >
                {groups &&
                  groups?.map((group, index) => (
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
                          onClick={() => handleGroupChange(group, type)}
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
                                    <Chip
                                      variant="filled"
                                      color="primary"
                                      size="small"
                                      label={group?.message_count}
                                      sx={{ ml: 1 }}
                                    />
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
                      <Divider />
                    </>
                  ))}
              </InfiniteScroll>
            }
          </List>
        </SidebarContainer>
      </Grid>

      {/* Group Detail */}

      {viewDetailGroup ? (
        <Grid item xs={12} md={9}>
          <GroupHeader
            handleReset={handleReset}
            isBack={true}
            setViewDetailGroup={setViewDetailGroup}
            group={group}
            setViewMedia={setViewMedia}
            viewMedia={viewMedia}
          />

          <Divider />

          {group && (
            <GroupDetail
              type={type}
              group={group.data}
              setGroups={setGroups}
              setViewDetailGroup={setViewDetailGroup}
              setSelectedGroup={setSelectedGroup}
            />
          )}
        </Grid>
      ) : (
        <Grid item xs={12} md={9}>
          {selectedGroup || mLoading || gLoading ? (
            group && group?.data ? (
              <Box sx={{ height: '90vh', display: 'flex', flexDirection: 'column' }}>
                <GroupHeader
                  handleReset={handleReset}
                  isBack={false}
                  setViewDetailGroup={setViewDetailGroup}
                  group={group}
                  setViewMedia={setViewMedia}
                  viewMedia={viewMedia}
                />
                <Divider />
                {viewMedia ? (
                  <MediaPane userId={selectedGroup} source="group" channelId={selectedGroup} />
                ) : (
                  <MessagesContainer id="scrollable-messages-group-container">
                    {/* <div ref={messagesEndRef} /> */}
                    <InfiniteScroll
                      style={{
                        display: 'flex',
                        flexDirection: 'column-reverse',
                        gap: '10px',
                        padding: '20px',
                      }}
                      // onScroll={handleScroll}
                      dataLength={messages.length}
                      next={loadMoreGroupMessages}
                      hasMore={hasMoreMessage}
                      loader={<h4>Loading...</h4>} // Loader will be shown at the top when scrolling up
                      scrollThreshold={0.95}
                      scrollableTarget="scrollable-messages-group-container"
                      inverse={true} // Load older messages on scroll up
                    >
                      {type == 'group'
                        ? messages.map((msg) => (
                            <>
                              {msg.senderId != senderId && msg.sender ? (
                                <>
                                  <Box sx={{ display: 'flex', justifyContent: 'flex-start' }}>
                                    <Typography variant="caption">
                                      {msg?.sender?.username}{' '}
                                      {moment.utc(msg.messageTimestampUtc as any).format('YYYY-DD-MM hh:mm A')}
                                    </Typography>
                                    <Badge
                                      color={msg?.sender.isOnline ? 'success' : 'default'}
                                      variant={msg?.sender.isOnline ? 'dot' : 'standard'}
                                      anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
                                      overlap="circular"
                                    />
                                  </Box>
                                </>
                              ) : (
                                <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
                                  <Typography variant="caption">
                                    {msg?.sender?.username}{' '}
                                    {moment.utc(msg.messageTimestampUtc as any).format('YYYY-DD-MM hh:mm A')}
                                  </Typography>
                                  {msg.deliveryStatus === 'sent' && <BsCheckAll />}
                                </Box>
                              )}
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
                          ))
                        : messages.map((message, index) => {
                            const currentDate = moment.utc(message.messageTimestampUtc).format('MM-DD-YYYY');
                            const previousDate =
                              index > 0
                                ? moment.utc(messages?.[index - 1].messageTimestampUtc).format('MM-DD-YYYY')
                                : null;
                            const isDifferentDay = previousDate && currentDate !== previousDate;
                            const isToday = currentDate === moment.utc().format('MM-DD-YYYY');
                            const isYou = message.messageDirection === 'S';

                            return (
                              <React.Fragment key={message.id}>
                                <Stack
                                  direction="row"
                                  spacing={2}
                                  sx={{ flexDirection: isYou ? 'row-reverse' : 'row' }}
                                >
                                  {message.messageDirection !== 'S' && (
                                    <AvatarWithStatus online={message?.sender?.isOnline} src={'a'} />
                                  )}
                                  <ChatBubble
                                    isVisibleThreeDot={false}
                                    onClick={() => {
                                      setCurrentIndex(index);
                                    }}
                                    truckNumbers=""
                                    variant={isYou ? 'sent' : 'received'}
                                    {...message}
                                    attachment={false}
                                    sender={message?.sender}
                                  />
                                </Stack>
                                {isDifferentDay && <Divider>{isToday ? 'Today' : previousDate}</Divider>}
                              </React.Fragment>
                            );
                          })}
                    </InfiniteScroll>
                  </MessagesContainer>
                )}

                {/* Input Container */}

                {!viewMedia && (
                  <InputContainer>
                    <IconButton
                      onClick={handleClick}
                      size="small"
                      sx={{ ml: 2 }}
                      aria-controls={open ? 'account-menu' : undefined}
                      aria-haspopup="true"
                      aria-expanded={open ? 'true' : undefined}
                    >
                      <Add />
                    </IconButton>
                    <Menu
                      anchorEl={anchorEl}
                      id="account-menu"
                      open={openTemplate}
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
                      <MenuItem onClick={() => setTemplateDialog(true)}>
                        <ListItemIcon>
                          <PaperPlane fontSize="small" />
                        </ListItemIcon>
                        Templates
                      </MenuItem>
                    </Menu>
                    {templateDialog && (
                      <TemplateDialog
                        open={templateDialog}
                        setOpen={setTemplateDialog}
                        setSelectedTemplate={setSelectedTemplate}
                      />
                    )}
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
                      <AttachFile />
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
                      fullWidth
                      placeholder="Type a message"
                      variant="outlined"
                      size="small"
                      value={newMessage}
                      onChange={(e) => setNewMessage(e.target.value)}
                      multiline
                      maxRows={10}
                    />
                    <IconButton onClick={handleSendMessage} disabled={isLoading}>
                      {isLoading ? <CircularProgress size={24} /> : <FiSend />}
                    </IconButton>
                  </InputContainer>
                )}
                {selectedTemplate.url && (
                  <Box sx={{}}>
                    <MediaComponent
                      url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${selectedTemplate.url}`}
                      name={selectedTemplate.url ?? ''}
                      width={100}
                      height={100}
                    />
                  </Box>
                )}
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
          ) : mLoading || gLoading ? (
            <CircularProgress />
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
      {currentIndex != null && messages[currentIndex]?.url && (
        <DocumentDialog
          uploadType={messages[currentIndex].url_upload_type}
          open={currentIndex != null ? true : false}
          onClose={() => {
            setCurrentIndex(null);
          }}
          documentKey={messages[currentIndex]?.url?.split('/')?.[1]}
          moveNext={movePrevious}
          movePrev={moveNext}
          currentIndex={currentIndex}
        />
      )}
    </Grid>
  );
};

export const MediaGallery = ({ mediaFiles }: any) => {
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

export default ChatInterface;
