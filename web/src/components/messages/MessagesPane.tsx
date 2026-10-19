import * as React from 'react';
import { useGetMessagesByUserIdQuery } from '@/redux/MessageApiSlice';
import { SingleChannelModel, UserProfile } from '@/redux/models/ChannelModel';
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
import { useSocketEvent } from '@/hooks/use-socket-event';
import { useOpenChatClaim } from '@/hooks/use-open-chat-claim';

import AvatarWithStatus from './AvatarWithStatus';
import ChatBubble from './ChatBubble';
import MediaComponent from './MediaComment';
import MediaPane from './MediaPane';
import MessageInput from './MessageInput';
import MessagesPaneHeader from './MessagesPaneHeader';
import { toast } from 'react-toastify';

import DocumentDialog from '../DocumentDialog';

type MessagesPaneProps = {
  userId: string;
  userList: any | null;
  setUserList: React.Dispatch<React.SetStateAction<SingleChannelModel | null>>;
  data:{

    userProfile: UserProfile; messages: MessageModel[],pagination:{
      currentPage: number,
      pageSize: number,
      totalMessages:number,
      totalPages:number,
    },truckNumbers?:string
  },
    isLoading:boolean, refetch:any ,isFetching:boolean
    pinMessage:string,
    setPinMessage:React.Dispatch<React.SetStateAction<string>>
    setResetKey:React.Dispatch<React.SetStateAction<number>>
    setPage:React.Dispatch<React.SetStateAction<number>>
    setHasMore:React.Dispatch<React.SetStateAction<boolean>>
    page:number
    hasMore:boolean
};

export default function MessagesPane(props: MessagesPaneProps) {
  const { userId, setUserList ,data,isFetching,isLoading,refetch,pinMessage,setPinMessage,setResetKey,hasMore,setHasMore,setPage,page} = props;
  const { trackChannelState } = useSelector((state: any) => state.channel);

  const [textAreaValue, setTextAreaValue] = React.useState('');
  const [messages, setMessages] = React.useState<MessageModel[]>([]);
  const { socket } = useSocket();
  const [mediaPanel, setMediaPanel] = React.useState<boolean>(false);
  const [isTyping, setIsTyping] = React.useState<boolean>(false);
  const messagesEndRef = React.useRef<HTMLDivElement | null>(null);
  const messagesContainerRef = React.useRef<HTMLDivElement | null>(null);
  
  const [unreadMessage, setUnReadMessage] = React.useState<string>('0');
  const [resetCount, setResetCount] = React.useState(0);
  

  const [showScrollToBottomButton, setShowScrollToBottomButton] = React.useState(false);
  const [buttonTitle, setButtonTitle] = React.useState<string>('Scroll to Bottom');
  const [selectedMessageToReply, setSelectedMessageToReply] = React.useState<MessageModel | null>(null);
  const [selectedTemplate, setSelectedTemplate] = React.useState<{ name: string; body: string; url?: string }>({
    name: '',
    body: '',
  });
  const [currentIndex, setCurrentIndex] = React.useState<number | null>(null);  
  const [sender,setSender] = React.useState<UserProfile|undefined>(undefined)
  

  React.useEffect(() => {
    if (!userId) return;
  
    // Reset states when `userId` changes
    setMessages([]);
    setTextAreaValue('');
    setPage(1);
    setHasMore(true);
    setSender(undefined);
    setPinMessage('0');
    setUnReadMessage('0');
    setSelectedMessageToReply(null);
  
    if (messagesContainerRef.current) {
      messagesContainerRef.current.scrollTo({
        top: 1,
        behavior: 'smooth',
      });
      setButtonTitle('Scroll to Bottom');
    }
  }, [userId]);


  React.useEffect(() => {
    if (data) {
      if(data?.userProfile){
        setSender(data?.userProfile)
      }
      if (page == 1) {
        setMessages([]);
      }
      setMessages((prevMessages) => {
        const newMessages = data?.messages.filter(
          (message) => !prevMessages.some((prevMessage) => prevMessage.id === message.id)
        );
        return newMessages ? [...prevMessages, ...newMessages] : prevMessages;
      });
      setHasMore(data.pagination.currentPage < data.pagination.totalPages);
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
    setSender(undefined); 
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
  // Socket handling (leak-free; refs give handlers the current chat)
  const userIdRef = React.useRef(userId);
  userIdRef.current = userId;
  const showScrollRef = React.useRef(showScrollToBottomButton);
  showScrollRef.current = showScrollToBottomButton;

  useSocketEvent('receive_message_channel', (message: MessageModel) => {
    if (message?.userProfileId == userIdRef.current) {
      setMessages((prevMessages) =>
        prevMessages.some((m) => m.id === message.id) ? prevMessages : [{ ...message }, ...prevMessages]
      );
      if (showScrollRef.current) setButtonTitle('New Message');
    }
    setUserList((prevUserList) => {
      if (!prevUserList) return prevUserList;
      const updatedUserChannels = prevUserList?.user_channels?.map((channel: any) =>
        channel.userProfileId === message.userProfileId ? { ...channel, sent_message_count: 0, last_message: message } : channel
      );
      return { ...prevUserList, user_channels: updatedUserChannels };
    });
  });

  useSocketEvent('user_online', (socketData: any) => {
    if (!socketData || typeof socketData.userId === 'undefined' || typeof socketData.isOnline === 'undefined') return;
    if (socketData.userId !== userIdRef.current) return;
    setSender((prevSender) => (prevSender ? { ...prevSender, isOnline: socketData.isOnline } : prevSender));
  });

  useSocketEvent('typing', (typingData: any) => setIsTyping(typingData.isTyping));
  useSocketEvent('stopTyping', () => setIsTyping(false));

  useSocketEvent('pin_done_web', (pinData: any) => {
    toast.success(pinData.value == '0' ? 'Un-pin message successfully' : 'Pin message successfully');
    setMessages((prev) => prev.map((e) => (e.id === pinData?.messageId ? { ...e, staffPin: pinData?.value } : e)));
  });

  const applyUploadStatus = (statusData: any) =>
    setMessages((prev) => prev.map((e) => (e.id === statusData?.messageId ? { ...e, url_upload_type: statusData?.status } : e)));
  useSocketEvent('update_file_recivied_status', applyUploadStatus);
  useSocketEvent('update_file_sent_status', applyUploadStatus);

  useSocketEvent('delete_message', (messageId: any) => {
    setMessages((prev) => prev.filter((e) => e.id != messageId));
    toast.error('Deleted message successfully');
  });

  // This pane owns the server's "staff is viewing driver X" state (messages from that driver are marked
  // seen). The claim is released whenever the pane closes for ANY reason (search, filters, Back, leaving
  // the page) and is only reported while this tab is the one being looked at.
  useOpenChatClaim(userId);
  React.useEffect(() => {
    if (socket && userId) socket.emit('staff_active_channel_user_update', userId);
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
        minWidth: 0,
        overflow: 'hidden',
        backgroundColor: 'var(--mui-palette-background-level1)',
      }}
    >
      {data && userId && (
        <MessagesPaneHeader
          handleReset={handleReset}
          onHandlePin={onHandlePin}
          mediaPanel={mediaPanel}
          truckNumbers={data?.truckNumbers}
          sender={sender}
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
        <MediaPane userId={props?.userId} source="channel" channelId={'null'} />
      ) : (
        <>
          {data && messages.length > 0 ? (
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
                  overflowX: 'hidden',
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
                              <AvatarWithStatus online={message?.sender?.isOnline} />
                            )}
                            <ChatBubble onClick={() => {
                           
                             setCurrentIndex(index)
                           
                            }}
                            isVisibleThreeDot={true}
                              truckNumbers={data?.truckNumbers}
                              variant={isYou ? 'sent' : 'received'}
                              {...message}
                              singleMessage={message}
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
      {currentIndex != null && messages[currentIndex]?.url && <DocumentDialog datetime={messages[currentIndex]?.messageTimestampUtc} open={currentIndex  != null? true :false} onClose={
       ()=>{
        setCurrentIndex(null)
       }
      } uploadType={messages[currentIndex]?.url_upload_type} documentKey={messages[currentIndex]?.url?.split('/')?.[1] =="video" ? messages[currentIndex]?.url?.split('/')?.[2] : messages[currentIndex]?.url?.split('/')?.[1]} moveNext={movePrevious} movePrev={moveNext} currentIndex={currentIndex}/>}
    </Paper>
  );
}
