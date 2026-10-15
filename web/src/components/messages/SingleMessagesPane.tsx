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
import { useSocketEvent } from '@/hooks/use-socket-event';
import { useOpenChatClaim } from '@/hooks/use-open-chat-claim';

import AvatarWithStatus from './AvatarWithStatus';
import ChatBubble from './ChatBubble';
import MediaComponent from './MediaComment';
import MediaPane from './MediaPane';
import MessageInput from './MessageInput';
import MessagesPaneHeader from './MessagesPaneHeader';
import { toast } from 'react-toastify';

type SingleMessagesPanerops = {
  userId: string;
  
};

export default function SingleMessagesPane(props: SingleMessagesPanerops) {
  const { userId } = props;
  const { trackChannelState } = useSelector((state: any) => state.channel);

  const [textAreaValue, setTextAreaValue] = React.useState('');
  const [messages, setMessages] = React.useState<MessageModel[]>([]);
  const { socket, isConnected } = useSocket();
  const [mediaPanel, setMediaPanel] = React.useState<boolean>(false);
  const [isTyping, setIsTyping] = React.useState<boolean>(false);
  const messagesEndRef = React.useRef<HTMLDivElement | null>(null);
  const messagesContainerRef = React.useRef<HTMLDivElement | null>(null);
  const [pinMessage, setPinMessage] = React.useState<string>('0');
  const [unreadMessage, setUnReadMessage] = React.useState<string>('0');
 
  const [page, setPage] = React.useState(1);
  const [hasMore, setHasMore] = React.useState<boolean>(true);
  const [showScrollToBottomButton, setShowScrollToBottomButton] = React.useState(false);
  const [buttonTitle, setButtonTitle] = React.useState<string>('Scroll to Bottom');
  const [selectedMessageToReply, setSelectedMessageToReply] = React.useState<MessageModel | null>(null);
  const [selectedTemplate, setSelectedTemplate] = React.useState<{ name: string; body: string; url?: string }>({
    name: '',
    body: '',
  });

  const { data, isLoading, refetch } = useGetMessagesByUserIdQuery(
    { id: userId, page, pageSize: 10, pinMessage: pinMessage,unreadMessage:unreadMessage },
    {
      
      skip: !userId,
      // Socket delivers new messages; poll only as a fallback while it is disconnected
      pollingInterval: isConnected ? 0 : 30000,
      selectFromResult: ({ data, isLoading, isFetching }) => ({
        data,
        isLoading,
        isFetching,
      }),
    }
  );

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

  // Socket handling (leak-free; only this driver's messages)
  const userIdRef = React.useRef(userId);
  userIdRef.current = userId;
  const showScrollRef = React.useRef(showScrollToBottomButton);
  showScrollRef.current = showScrollToBottomButton;

  useSocketEvent('receive_message_channel', (message: MessageModel) => {
    // The server sends this to every staff with a chat open in the channel; keep only this driver's
    if (message?.userProfileId != userIdRef.current) return;
    setMessages((prevMessages) =>
      prevMessages.some((m) => m.id === message.id) ? prevMessages : [{ ...message }, ...prevMessages]
    );
    if (showScrollRef.current) setButtonTitle('New Message');
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

  // Same ownership as MessagesPane: set "viewing this driver" while open, clear it when closed
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
  if (isLoading && page === 1) {
    return <CircularProgress />;
  }

  return (
    <Paper
      sx={{
        height: { xs: 'calc(100vh - 5vh)', md: '92vh' },
        display: 'flex',
        flexDirection: 'column',
        backgroundColor: 'var(--mui-palette-background-level1)',
      }}
    >
      {data?.data && userId && (
        <MessagesPaneHeader
          handleReset={() => {}}
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
                              <AvatarWithStatus online={message?.sender?.isOnline} />
                            )}
                            <ChatBubble
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
                <Box sx={{ mb: 1, mx: 2, px: 2, pb: 1, background: 'var(--mui-palette-background-paper)', borderLeft: '6px solid blue' }}>
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
    </Paper>
  );
}
