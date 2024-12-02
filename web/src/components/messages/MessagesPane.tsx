import * as React from 'react';
import { useGetMessagesByUserIdQuery } from '@/redux/MessageApiSlice';
import { SingleChannelModel } from '@/redux/models/ChannelModel';
import { MessageModel } from '@/redux/models/MessageModel';
import { WavingHand } from '@mui/icons-material';
import { CircularProgress, Divider, IconButton, Typography } from '@mui/material';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Stack from '@mui/material/Stack';

import { useSocket } from '@/lib/socketProvider';

import AvatarWithStatus from './AvatarWithStatus';
import ChatBubble from './ChatBubble';
import MessageInput from './MessageInput';
import MessagesPaneHeader from './MessagesPaneHeader';
import MediaPane from './MediaPane';
import moment from 'moment';

type MessagesPaneProps = {
  userId: string;
  userList: SingleChannelModel | null;
  setUserList: React.Dispatch<React.SetStateAction<SingleChannelModel | null>>;
};

export default function MessagesPane(props: MessagesPaneProps) {
  const { userId,  setUserList } = props;

  const [textAreaValue, setTextAreaValue] = React.useState('');
  const [messages, setMessages] = React.useState<MessageModel[]>([]);
  const { socket } = useSocket();
  const [mediaPanel,setMediaPanel] = React.useState<boolean>(false)
  const [isTyping, setIsTyping] = React.useState<boolean>(false);
  const messagesEndRef = React.useRef<HTMLDivElement | null>(null);
  const [selectedTemplate,setSelectedTemplate] = React.useState<{name:string,body:string,url?:string}>({name:"",body:""})
  const scrollToBottom = () => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({
        behavior: 'smooth',
        block: 'end',
      });
    }
  };
  const { data, isLoading, refetch } = useGetMessagesByUserIdQuery(
    { id: userId },
    {
      skip: !userId,
      pollingInterval: 30000,
      refetchOnFocus: true,
      selectFromResult: ({ data, isLoading, isFetching }) => ({
        data: data,
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
    scrollToBottom();
  }, [messages]);

  React.useEffect(() => {
    if (data && data?.status) {
      setMessages(data?.data?.messages);
    }
  }, [data, isLoading]);



  React.useEffect(() => {

    if (socket) {
      socket.emit('staff_active_channel_user_update', userId);

      socket.on('receive_message_channel', (message: MessageModel) => {
        scrollToBottom();
        setMessages((prevMessages) => [...prevMessages, message]);

        if (message) {
          setUserList((prevUserList) => {
            if (!prevUserList) return prevUserList;

            const updatedUserChannels = prevUserList.user_channels.map((channel) => {
              if (channel.userProfileId === message?.userProfileId) {
                return {
                  ...channel,
                  sent_message_count: 0,
                  last_message:message

                };
              }
              return channel;
            });

            return { ...prevUserList, user_channels: updatedUserChannels };
          });
        }
      });
      socket.on('typing', (data:any) => {
        setIsTyping(data.isTyping);
      });

      socket.on('stopTyping', () => {
        setIsTyping(false);
      });
    }

    return () => {
      if (socket) {
        socket.off('receive_message_channel');
        socket?.off('staff_open_chat', null);
      }
    };
  }, [socket, userId]);

  if (isLoading) {
    return <CircularProgress />;
  }

  return (
    <Paper
      sx={{
        height: { xs: 'calc(100vh - 5vh)', md: '92vh' },
        display: 'flex',
        flexDirection: 'column',
        backgroundColor: 'background.default',
      }}
    >
      {data?.data && userId && <MessagesPaneHeader mediaPanel={mediaPanel} sender={data?.data?.userProfile} setMediaPanel={setMediaPanel} setSelectedTemplate={setSelectedTemplate}/>}

      {mediaPanel ?  <><MediaPane userId={props.userId}/></> :  <>
        {data?.data && messages?.length > 0 ? (
        <>
          <Box
            sx={{
              display: 'flex',
              flex: 1,
              minHeight: 0,
              px: 2,
              py: 3,
              overflowY: 'scroll',
              flexDirection: 'column-reverse',
            }}

          >
             <Stack spacing={2} sx={{ justifyContent: 'flex-end' }}>
      {messages &&
        messages.map((message: MessageModel, index: number) => {
          const currentDate = moment.utc(message.messageTimestampUtc).format('MM-DD-YYYY');

          const previousDate =
            index > 0
              ? moment.utc(messages?.[index - 1].messageTimestampUtc).format('MM-DD-YYYY')
              : null;

          const isDifferentDay = previousDate && currentDate !== previousDate;
          const isToday = currentDate === moment.utc().format('MM-DD-YYYY');  // Adjusted for correct logic

          const isYou = message.messageDirection === 'S';

          return (
            <>
              <Stack
                key={index}
                direction="row"
                spacing={2}
                sx={{ flexDirection: isYou ? 'row-reverse' : 'row' }}
              >
                {message.messageDirection !== 'S' && (
                  <AvatarWithStatus online={message?.sender?.isOnline} src={'a'} />
                )}
                <ChatBubble
                  variant={isYou ? 'sent' : 'received'}
                  {...message}
                  attachment={false}
                  sender={message?.sender}
                />
              </Stack>

              {/* Render divider only if it's a different day */}
              {isDifferentDay && (
                <Divider>{isToday ? 'Today' : previousDate}</Divider>
              )}


            </>
          );
        })}
    </Stack>
          </Box>
          <div ref={messagesEndRef} />
          {messages.length > 0 && (
            <MessageInput
            selectedTemplate={selectedTemplate}
              isTyping={isTyping}
              textAreaValue={textAreaValue}
              setTextAreaValue={setTextAreaValue}
              userId={userId}
              onSubmit={() => {
                socket.emit('send_message_to_user', { body: textAreaValue, userId: userId, direction: 'S',...(selectedTemplate ? { url: selectedTemplate.url } : {}) });
                if(selectedTemplate){
                  setSelectedTemplate({
                    name:"",
                    body:"",
                    url:""
                  })
                }
              }}
            />
          )}
        </>
      ) : (
        <>
          <Box flex={1} display={'flex'} flexDirection={'column'} alignItems={'center'} justifyContent={'center'}>
            {userId && messages.length == 0 ? (
              <IconButton
                onClick={() => {
                  socket.emit('send_message_to_user', { body: 'Hi', userId: userId, direction: 'S' });
                }}
              >
                <Box display={'flex'} flexDirection={'column'} justifyContent={'center'} alignItems={'center'}>
                  <WavingHand color="warning" />
                  <Typography>Say Hi</Typography>
                </Box>
              </IconButton>
            ) : (
              <Typography>Not Chat Selected</Typography>
            )}
          </Box>
        </>
      )}

      </>}


    </Paper>
  );
}
