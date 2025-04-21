import * as React from 'react';
import { useGetMessagesByUserIdQuery } from '@/redux/MessageApiSlice';
import { SingleChannelModel } from '@/redux/models/ChannelModel';
import { MessageModel } from '@/redux/models/MessageModel';
import { Close, WavingHand } from '@mui/icons-material';
import { Button, CircularProgress, Divider, IconButton, Typography } from '@mui/material';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Stack from '@mui/material/Stack';
import moment from 'moment';
import InfiniteScroll from 'react-infinite-scroll-component';
import { useSelector } from 'react-redux';

import { useSocket } from '@/lib/socketProvider';

import AvatarWithStatus from './AvatarWithStatus';
import ChatBubble from './ChatBubble';
import MediaComponent from './MediaComment';
import MediaPane from './MediaPane';
import MessageInput from './MessageInput';
import MessagesPaneHeader from './MessagesPaneHeader';
import { toast } from 'react-toastify';
import { set } from 'react-hook-form';
import DocumentDialog from '../DocumentDialog';

type MessagesPaneProps = {
  userId: string;
  userList: any | null;
  setUserList: React.Dispatch<React.SetStateAction<SingleChannelModel | null>>;
};

export default function MessagesPane(props: MessagesPaneProps) {
  const { userId, setUserList } = props;
  const { trackChannelState } = useSelector((state: any) => state.channel);

  const [textAreaValue, setTextAreaValue] = React.useState('');
  const [messages, setMessages] = React.useState<MessageModel[]>([]);
  const { socket } = useSocket();
  const [mediaPanel, setMediaPanel] = React.useState<boolean>(false);
  const [isTyping, setIsTyping] = React.useState<boolean>(false);
  const messagesEndRef = React.useRef<HTMLDivElement | null>(null);
  const messagesContainerRef = React.useRef<HTMLDivElement | null>(null);
  const [pinMessage, setPinMessage] = React.useState<string>('0');
  const [unreadMessage, setUnReadMessage] = React.useState<string>('0');
  const [resetCount, setResetCount] = React.useState(0);
  const [resetKey, setResetKey] = React.useState(Date.now()); // Unique number each time
  const [page, setPage] = React.useState(1);
  const [hasMore, setHasMore] = React.useState<boolean>(true);
  const [showScrollToBottomButton, setShowScrollToBottomButton] = React.useState(false);
  const [buttonTitle, setButtonTitle] = React.useState<string>('Scroll to Bottom');
  const [selectedMessageToReply, setSelectedMessageToReply] = React.useState<MessageModel | null>(null);
  const [selectedTemplate, setSelectedTemplate] = React.useState<{ name: string; body: string; url?: string }>({
    name: '',
    body: '',
  });
  const [currentIndex, setCurrentIndex] = React.useState<number | null>(null);  
  const { data, isLoading, refetch ,isFetching} = useGetMessagesByUserIdQuery(
    { id: userId, page, pageSize: 10, pinMessage: pinMessage,unreadMessage:unreadMessage,resetKey },
    {
      
      skip: !userId,
      pollingInterval: 30000,
      refetchOnFocus: true,
      selectFromResult: ({ data, isLoading, isFetching }) => ({
        data,
        isLoading,
        isFetching,
      }),
    }
  );

  React.useEffect(() => {
    if (userId) {
      refetch();
    }
  }, [userId, refetch]);

  React.useEffect(() => {
    if (userId) {
      // Resetting all necessary states when userId changes
      setMessages([]);
      setTextAreaValue('');
      setPage(1);
      setHasMore(true);
      setSelectedTemplate({ name: '', body: '', url: '' });
      setIsTyping(false);
      //setShowScrollToBottomButton(false)
      if (messagesContainerRef.current) {
        messagesContainerRef.current.scrollTo({
          top: 1,
          behavior: 'smooth',
        });
        setButtonTitle('Scroll to Bottom');
      }
    }
    
  }, [userId]);

  React.useEffect(() => {
    if (data && data.status) {
      if (page == 1) {
        setMessages([]);
      }
      setMessages((prevMessages) => {
        const newMessages = data.data.messages.filter(
          (message) => !prevMessages.some((prevMessage) => prevMessage.id === message.id)
        );
        return [...prevMessages, ...newMessages];
      });
      setHasMore(data.data.pagination.currentPage < data.data.pagination.totalPages);
    }
  }, [data, page]);


  React.useEffect(() => {
    if (trackChannelState > 0) {
      setHasMore(false);
      setMessages([]);
    }
  }, [trackChannelState]);

  const loadMoreMessages = () => {
    if (hasMore && !isLoading) {
      setPage((prevPage) => prevPage + 1);
    }
  };
  const handleReset = () => {
    setMessages([]);
    setTextAreaValue('');
    setPage(1);
    setHasMore(true);
    setUnReadMessage('0');
    setPinMessage('0');
    setSelectedTemplate({ name: '', body: '', url: '' });
    setIsTyping(false);
    setSelectedMessageToReply(null);
  
    if (messagesContainerRef.current) {
      messagesContainerRef.current.scrollTo({
        top: 1,
        behavior: 'smooth',
      });
      setButtonTitle('Scroll to Bottom');
    }
  
   
    setResetKey(Date.now());
   
  };
  // Socket handling (e.g., new messages)
  React.useEffect(() => {
    if (socket) {
      socket.emit('staff_active_channel_user_update', userId);
      
      socket.on('receive_message_channel', (message: MessageModel) => {
     
        if(message?.userProfileId == userId){
          setMessages((prevMessages) => [{ ...message }, ...prevMessages]);
        }
      
        if (showScrollToBottomButton) {
          setButtonTitle('New Message');
        }
        // Update user list if necessary
        setUserList((prevUserList) => {
          if (!prevUserList) return prevUserList;
          const updatedUserChannels = prevUserList.user_channels.map((channel) => {
            if (channel.userProfileId === message.userProfileId) {
              return { ...channel, sent_message_count: 0, last_message: message };
            }
            return channel;
          });
          return { ...prevUserList, user_channels: updatedUserChannels };
        });
      });

      socket.on('typing', (data: any) => {
        setIsTyping(data.isTyping);
      });

      socket.on('stopTyping', () => {
        setIsTyping(false);
      });

      socket.on('pin_done_web',(data:any)=>{
        if(data.value == "0"){
          toast.success("Un-pin message successfully")
        }else{
          toast.success("Pin message successfully")
        }
       
        setMessages((prev) =>
          prev.map((e) =>
            e.id === data?.messageId ? { ...e, staffPin: data?.value } : e
          )
        );
       
       
      })
      socket.on("update_file_recivied_status",(data:any)=>{
       setMessages((prev) =>
          prev.map((e) =>
            e.id === data?.messageId ? { ...e, url_upload_type: data?.status } : e
          )
        );
       })
       socket.on("update_file_sent_status",(data:any)=>{
        setMessages((prev) =>
           prev.map((e) =>
             e.id === data?.messageId ? { ...e, url_upload_type: data?.status } : e
           )
         );
        })
 
       
      socket.on('delete_message',(data:any)=>{
      
       
        setMessages((prev) =>
          prev.filter((e) =>
            e.id != data 
          )
        );
      
          toast.error("Deleted message successfully")
        
      })
    }
    
  
    
    const intervalId = setInterval(() => {
      if (userId && socket) {
        socket.emit('staff_open_chat', userId);
       
      }
    }, 15000); // Every 15 seconds

    // Cleanup the interval when the component is unmounted or userId changes
    return () => {
      if (socket) {
        socket.off('update_file_sent_status');
        socket.off('delete_message');
        socket.off('update_file_recivied_status');
        socket.off('receive_message_channel');
        socket.off('pin_done');
        socket.off('pin_done_web');
        socket.off('staff_open_chat', userId);
      }
      clearInterval(intervalId); // Clear interval to avoid memory leaks
    };
  }, [socket, userId]);

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

  function onHandlePin(){
    setMessages([])

  }
  const moveNext = () => {
    if(currentIndex != null){
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
    if(currentIndex){
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
  };
}
  if (isLoading && page === 1) {
    return <CircularProgress />;
  }

  return (
    <Paper
      sx={{
        height: { xs: 'calc(100vh - 5vh)', md: '92vh' },
        display: 'flex',
        flexDirection: 'column',
        backgroundColor: '#f0f0f0',
      }}
    >
      {data?.data && userId && (
        <MessagesPaneHeader
        handleReset={handleReset}
          onHandlePin={onHandlePin}
          mediaPanel={mediaPanel}
          truckNumbers={data?.data?.truckNumbers}
          sender={data?.data?.userProfile}
          setMediaPanel={setMediaPanel}
          setSelectedTemplate={setSelectedTemplate}
          pinMessage={pinMessage}
          setPinMessage={setPinMessage}
          unreadMessage={unreadMessage}
          setUnReadMessage={setUnReadMessage}
          setMessages={setMessages}
          setPage={setPage}
        />
      )}

      {mediaPanel ? (
        <MediaPane userId={props.userId} source="channel" channelId={'null'} />
      ) : (
        <>
          {data?.status && messages.length > 0 ? (
            <>
              <Box
                id="scrollable-messages-container"
                ref={messagesContainerRef}
                sx={{
                  display: 'flex',
                  flex: 1,
                  minHeight: 0,
                  px: 2,
                  py: 3,
                  overflowY: 'scroll',
                  flexDirection: 'column-reverse', // Most recent messages at the bottom
                }}
              >
                <InfiniteScroll
                  style={{
                    display: 'flex',
                    flexDirection: 'column-reverse',
                  }}
                  onScroll={handleScroll}
                  dataLength={messages.length}
                  next={loadMoreMessages}
                  hasMore={hasMore}
                  loader={<h4>Loading...</h4>} 
                  scrollThreshold={0.95}
                  scrollableTarget="scrollable-messages-container"
                  inverse={true} // Load older messages on scroll up
                >
                  {/* Show the loader before the actual messages */}
                  <Stack
                    spacing={2}
                    sx={{
                      justifyContent: 'flex-end',
                      flexDirection: 'column-reverse', // The most recent messages stay at the bottom
                    }}
                  >
                    {messages.map((message: MessageModel, index: number) => {
                      const currentDate = moment.utc(message.messageTimestampUtc).format('MM-DD-YYYY');
                      const previousDate =
                        index > 0 ? moment.utc(messages?.[index - 1].messageTimestampUtc).format('MM-DD-YYYY') : null;
                      const isDifferentDay = previousDate && currentDate !== previousDate;
                      const isToday = currentDate === moment.utc().format('MM-DD-YYYY');
                      const isYou = message.messageDirection === 'S';

                      return (
                        <React.Fragment key={message.id}>
                          <Stack direction="row" spacing={2} sx={{ flexDirection: isYou ? 'row-reverse' : 'row' }}>
                            {message.messageDirection !== 'S' && (
                              <AvatarWithStatus online={message?.sender?.isOnline} src={'a'} />
                            )}
                            <ChatBubble onClick={() => {
                             setCurrentIndex(index)
                             console.log("index",index)
                            }}
                              truckNumbers={data?.data?.truckNumbers}
                              variant={isYou ? 'sent' : 'received'}
                              {...message}
                              attachment={false}
                              sender={message?.sender}
                              setSelectedMessageToReply={setSelectedMessageToReply}
                            />
                          </Stack>
                          {isDifferentDay && <Divider>{isToday ? 'Today' : previousDate}</Divider>}
                        </React.Fragment>
                      );
                    })}
                  </Stack>
                </InfiniteScroll>
              </Box>
              {showScrollToBottomButton && (
                <Button
                  variant="contained"
                  color="secondary"
                  size="small"
                  sx={{
                    width: 200,
                    alignSelf: 'center',
                    marginBottom: 1,
                  }}
                  onClick={() => {
                    if (messagesContainerRef.current) {
                      messagesContainerRef.current.scrollTo({
                        top: 1,
                        behavior: 'smooth',
                      });
                      setButtonTitle('Scroll to Bottom');
                    }
                  }}
                >
                  {buttonTitle}
                </Button>
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
                       <Box sx={{display:"flex"}}>
                       <Typography variant="body2">
                          {selectedMessageToReply?.messageDirection === 'S'
                            ? selectedMessageToReply?.sender?.username
                              ? `${selectedMessageToReply?.sender?.username}(staff)`
                              : '(staff)'
                            : `${selectedMessageToReply?.sender?.username}(driver)`}
                        </Typography>
                        <Box sx={{width:"20px"}}></Box>
                        <Typography variant="caption">
                          {moment(selectedMessageToReply?.messageTimestampUtc).format('YYYY-MM-DD HH:mm')}
                        </Typography>
                       </Box>
                       <IconButton onClick={()=>{
                        setSelectedMessageToReply(null)
                       }}><Close/></IconButton>
                      </Stack>
                      <Typography sx={{ fontSize: 16,whiteSpace: 'pre-wrap' }}>{selectedMessageToReply?.body}</Typography>
                    </>
                  )}
                </Box>
              )}
              {messages.length > 0 && (
                <MessageInput
                  selectedTemplate={selectedTemplate}
                  isTyping={isTyping}
                  textAreaValue={textAreaValue}
                  setTextAreaValue={setTextAreaValue}
                  userId={userId}
                  onSubmit={() => {
                    if (selectedMessageToReply) {
                      socket.emit('send_message_to_user', {
                        body: textAreaValue,
                        userId: userId,
                        direction: 'S',
                        url: null,
                        thumbnail: null,
                        r_message_id: selectedMessageToReply.id,
                      });
                    } else {
                      socket.emit('send_message_to_user', {
                        body: textAreaValue,
                        userId: userId,
                        direction: 'S',
                        ...(selectedTemplate ? { url: selectedTemplate.url } : {}),
                      });
                    }

                    if (selectedTemplate) {
                      setSelectedTemplate({ name: '', body: '', url: '' });
                    }
                    if (selectedMessageToReply) {
                      setSelectedMessageToReply(null);
                    }
                  }}
                />
              )}
            </>
          ) : (
            <Box flex={1} display={'flex'} flexDirection={'column'} alignItems={'center'} justifyContent={'center'}>
              {userId && messages.length === 0  ?  (
                <IconButton
                  onClick={() => socket.emit('send_message_to_user', { body: 'Hi', userId: userId, direction: 'S' })}
                >
                  <Box display={'flex'} flexDirection={'column'} justifyContent={'center'} alignItems={'center'}>
                    <WavingHand color="warning" />
                    <Typography>Say Hi</Typography>
                  </Box>
                </IconButton>
              ) : (
                <Typography>Not Chat found</Typography>
              )}
            </Box>
          )}
        </>
      )}
      {currentIndex != null && messages[currentIndex]?.url && <DocumentDialog open={currentIndex ? true :false} onClose={
       ()=>{
        setCurrentIndex(null)
       }
      } documentKey={messages[currentIndex]?.url?.split('/')?.[1]} moveNext={movePrevious} movePrev={moveNext} currentIndex={currentIndex}/>}
    </Paper>
  );
}
