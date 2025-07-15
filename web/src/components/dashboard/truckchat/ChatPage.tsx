'use client';

import { type } from 'os';

import React, { useCallback, useEffect, useRef, useState } from 'react';
import { useGetGroupByIdQuery } from '@/redux/GroupApiSlice';
import { useFileUploadMutation, useUploadMultipleFilesMutation, useVideoUploadMutation } from '@/redux/MessageApiSlice';
import { GroupModel } from '@/redux/models/GroupModel';
import { MessageModel } from '@/redux/models/MessageModel';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { useGetTruckGroupsQuery } from '@/redux/truckChatApiSlice';
import { Button, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, TextField } from '@mui/material';
import ReactPlayer from 'react-player';
import { useDispatch } from 'react-redux';

import { useSocket } from '@/lib/socketProvider';
import useDebounce from '@/hooks/useDebounce';

import { MediaGallery } from '../truckgroup/view';
import { ChatView } from './ChatView';
import { Chat, Message, User } from './types';

const ChatPage = () => {
  const [search, setSearch] = React.useState<string>('');

  const searchItem = useDebounce(search, 200);
  const [pageMessage, setPageMessage] = React.useState(1);
  const [hasMoreMessage, setHasMoreMessage] = React.useState<boolean>(true);
  const { socket } = useSocket();
  const [page, setPage] = React.useState(1);
  const [hasMore, setHasMore] = React.useState<boolean>(true);
  const [uploadMultipleFiles, { isLoading: multipleLoader }] = useUploadMultipleFilesMutation();
  const [viewDetailGroup, setViewDetailGroup] = useState<boolean>(false);

  const [currentChatId, setCurrentChatId] = useState<string>();
  const { data: truckGroups, isLoading } = useGetTruckGroupsQuery({ page: page, search: searchItem });
  const [fileUpload] = useFileUploadMutation();
  const [videoUpload] = useVideoUploadMutation();
  const dispatch = useDispatch();
  const [viewMedia, setViewMedia] = useState<boolean>(false);
  const [file, setFile] = React.useState<any>(null);
  const [previewDialogOpen, setPreviewDialogOpen] = React.useState(false);
  const [caption, setCaption] = React.useState('');
  const [groups, setGroups] = useState<GroupModel[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [files, setFiles] = React.useState<any>([]);
  const [selectedTemplate, setSelectedTemplate] = React.useState<{ name: string; body: string; url?: string }>({
    name: '',
    body: '',
  });
const currentChatIdRef = useRef<string | undefined>();

// Keep the ref updated
useEffect(() => {
  currentChatIdRef.current = currentChatId;
}, [currentChatId]);

  const {
    data: messages,
    isLoading: messageLoader,
    isFetching: isMessagesFetching,
    refetch: refetchMessages,
  } = useGetGroupByIdQuery(
    { page: pageMessage, id: currentChatId || '' },
    {
      skip: !currentChatId,
    }
  );

  const [message, setMessage] = useState<MessageModel[]>([]);

  const loadMoreGroupMessages = () => {
    console.log('Loading more messages...');
    if (hasMoreMessage && !messageLoader) {
      setPageMessage((prevPage) => prevPage + 1);
    }
  };
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  

  useEffect(() => {
     const newGroups = truckGroups?.data?.data || [];

    if (newGroups?.length > 0) {
     setHasMore((truckGroups?.data?.pagination.currentPage || 0 )< (truckGroups?.data?.pagination.totalPages || 0));

      if ((truckGroups?.data?.pagination?.currentPage || 1) > 1) {
        // Append to existing messages
        setGroups((prev) => [...prev, ...newGroups]);
      } else {
        // Replace existing messages
         setGroups(newGroups);
      }
    }
  
  }, [truckGroups,isLoading]);

  useEffect(() => {
    const newMessages = messages?.data?.messages || [];

    if (newMessages.length > 0) {
      setHasMoreMessage((messages?.data?.pagination?.currentPage || 0) < (messages?.data?.pagination?.totalPages || 0));

      if ((messages?.data?.pagination?.currentPage || 1) > 1) {
        // Append to existing messages
        setMessage((prev) => [...prev, ...newMessages]);
      } else {
        // Replace existing messages
        setMessage(newMessages);
      }
    }
  }, [messages, messageLoader]);

  // Force refetch when currentChatId changes (optional)
  useEffect(() => {
    if (currentChatId) {
      refetchMessages();
    }
  }, [currentChatId, refetchMessages]);

  function handleReceiveMessage (message: any, groupId: string) {
 const currentId = currentChatIdRef.current;
      console.log('Received message:', message, 'for groupId:', groupId, 'currentChatId:', currentChatId);
      if (message.groupId !== currentId) {
        return; // Ignore the message if the groupId does not match selectedId
      }
      setMessage((prevMessages: any) => {
        if (prevMessages.some((msg: any) => msg.id === message.id)) {
          return prevMessages;
        }
        return [message, ...prevMessages];
      });
    }
    const loadMoreMessages = () => {
    if (hasMore && !isLoading) {
      setPage((prevPage) => prevPage + 1);
    }
  };
console.log('Current chat ID:', currentChatId);
  useEffect(() => {
    if (socket) {
      socket.on('update_url_status_truck_group', (data: any) => {
        setMessage((prev: any) =>
          prev.map((e: any) => (e.id === data?.messageId ? { ...e, url_upload_type: data?.status } : e))
        );
      });
      // socket.on('receive_message_group', (message: MessageModel) => handleReceiveMessage(message, selectedGroup));
      socket.on('receive_message_group_truck', (message: MessageModel) =>
        handleReceiveMessage(message, currentChatId!)
      );

      // Cleanup the event listener when the component unmounts or socket changes
      return () => {
        socket.off('receive_message_group_truck', handleReceiveMessage);
      };
    }
  }, [socket]);


// Interval effect
useEffect(() => {
  if (currentChatId && socket?.connected) {
    intervalRef.current = setInterval(() => {
      socket.emit('staff_open_truck_chat', currentChatId);
    }, 2000);
  }

  return () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
  };
}, [currentChatId, socket?.connected]);


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

  async function sendFiles() {
    try {
      const userIds = messages?.data.members
        .filter((e) => e.userProfileId && e.status == 'active')
        .map((e) => e.userProfileId);
      if (userIds?.length == 0) {
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
        groupId: currentChatId,
        location: 'truck',
        source: 'truck',
        uploadBy: 'staff',
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

  const handleSendMessage = (message: string) => {
    try {
      // userId,groupId,body,direction,url
     if(!currentChatId){
      alert('Please re-select a group to send message or refresh the page.');
      return
     }
      if (messages?.data) {
        const userIds = messages?.data?.members
          .filter((e) => e.userProfileId && e.status == 'active')
          .map((e) => e.userProfileId);

        if (userIds.length == 0) {
          alert('Please Add member before send message into group');
          return;
        }

        socket?.emit('send_message_to_user_by_group', {
          userId: userIds?.join(','),
          groupId: currentChatId,
          body: message,
          direction: 'S',
          url: '',
        });
      }

      //   setIsLoading(false);
      setSelectedTemplate({
        name: '',
        body: '',
        url: '',
      });
      //   setNewMessage('');
      // const data = {}
    } catch (err) {
      //   setIsLoading(false);
      //   setError('Failed to send message. Please try again.');
    }
  };

  const handleSelectChat = (chatId: string) => {
    console.log('Selected chat ID:', chatId);
    if (socket.connected) {
      socket.emit('staff_open_truck_chat', chatId);
    } else {
      alert('Socket connection is not established. Please try again later or refesh page.');
      return;
    }
    setMessage([]); // Clear messages when switching chats
    setPageMessage(1); // Reset message page to 1
    // Mark messages as read when selecting a chat
    // setChats((prevChats) => prevChats.map((chat) => (chat.id === chatId ? { ...chat, unreadCount: 0 } : chat)));
    setCurrentChatId(chatId);
  };

  //   const currentChat = chats.find((chat) => chat.id === currentChatId);

  async function sendMessage() {
    try {
      const extension = file.name?.split('.')[file.name?.split('.').length - 1];

      const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'flv', 'webm', 'mpeg', 'mpg', 'wmv'];
      dispatch(showLoader());
      if (messages?.data) {
        const userIds = messages?.data.members
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
        formData.append('source', 'truck');
        formData.append('groupId', currentChatId || '');
        formData.append('type', file.type.startsWith('image/') ? 'media' : 'doc');
        const res = videoExtensions.includes(extension)
          ? await videoUpload({ formData, userId: '', groupId: currentChatId }).unwrap()
          : await fileUpload({ formData }).unwrap();
        if (res.status) {
          socket?.emit('send_message_to_user_by_group', {
            userId: userIds?.join(','),
            groupId: currentChatId,
            body: caption,
            url: res?.data?.key,
            direction: 'S',
            thumbnail: res?.data?.thumbnail,
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
  const handleCancel = () => {
    setPreviewDialogOpen(false); // Close the preview dialog without sending
    setFile(null);
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
  useEffect(() => {
    if (selectedTemplate) {
      setNewMessage(selectedTemplate?.body);
    }
  }, [selectedTemplate]);

  return (
    <div style={{ height: '80vh' }}>
      {isLoading ? (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
          <p>Loading...</p>
        </div>
      ) : (
        <ChatView
        setPage={setPage}
        loadMoreMessages={loadMoreMessages}
        hasMore={hasMore}
          search={search}
          setSearch={setSearch}
          setSelectedGroup={setCurrentChatId as any}
          message={newMessage}
          setMessage={setNewMessage}
          selectedTemplate={selectedTemplate}
          setSelectedTemplate={setSelectedTemplate}
          setCurrentChatId={setCurrentChatId}
          isBack={false}
          setViewDetailGroup={setViewDetailGroup}
          viewDetailGroup={viewDetailGroup}
          viewMedia={viewMedia}
          setViewMedia={setViewMedia}
          handleReset={() => {}}
          hasMoreMessage={hasMoreMessage}
          loadMoreGroupMessages={loadMoreGroupMessages}
          messageLoader={messageLoader || isMessagesFetching}
          trucks={groups}
          setGroups={setGroups}
          currentUser={messages?.data}
          messages={message}
          onSelectChat={handleSelectChat}
          onSendMessage={handleSendMessage}
          handleFileChangeVedio={handleFileChangeVedio}
          handleVedioClick={handleVedioClick}
        />
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
    </div>
  );
};

export default ChatPage;
