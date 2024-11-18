import * as React from 'react';
import { useGetMessagesByUserIdQuery } from '@/redux/MessageApiSlice';
import { SingleChannelModel } from '@/redux/models/ChannelModel';
import { MessageModel } from '@/redux/models/MessageModel';
import { updateMessageList } from '@/redux/slices/messageSlice';
import { WavingHand } from '@mui/icons-material';
import { CircularProgress, IconButton, Typography } from '@mui/material';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Stack from '@mui/material/Stack';
import { useDispatch, useSelector } from 'react-redux';

import { useSocket } from '@/lib/socketProvider';

import AvatarWithStatus from './AvatarWithStatus';
import ChatBubble from './ChatBubble';
import MessageInput from './MessageInput';
import MessagesPaneHeader from './MessagesPaneHeader';

type MessagesPaneProps = {
  userId: string;
  userList: SingleChannelModel | null;
  setUserList: React.Dispatch<React.SetStateAction<SingleChannelModel | null>>;
};

export default function MessagesPane(props: MessagesPaneProps) {
  const { userId, userList, setUserList } = props;

  const [textAreaValue, setTextAreaValue] = React.useState('');
  const [messages, setMessages] = React.useState<MessageModel[]>([]);
  const { socket } = useSocket();
  const dispatch = useDispatch();

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
    // Force a refetch whenever the userId changes or re-renders
    if (userId) {
      refetch(); // Manually trigger refetch to reload data
    }
  }, [userId, refetch]); // Trigger the effect when userId changes

  React.useEffect(() => {
    if (data && data?.status) {
      setMessages(data?.data?.messages);
    }
  }, [data, isLoading]);

  React.useEffect(() => {
    if (userId == '') {
      setMessages([]);
    }
  }, [userId]);

  React.useEffect(() => {
    if (socket) {
      socket.emit('staff_active_channel_user_update', userId);

      socket.on('receive_message_channel', (message: MessageModel) => {
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
    }

    return () => {
      if (socket) {
        //socket.off('receive_message_channel');
        // socket?.emit('staff_open_chat', "");
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
      {data?.data && userId && <MessagesPaneHeader sender={data?.data?.userProfile} />}
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
                  const isYou = message.messageDirection === 'S';
                  return (
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
                  );
                })}
            </Stack>
          </Box>
          {messages.length > 0 && (
            <MessageInput
              textAreaValue={textAreaValue}
              setTextAreaValue={setTextAreaValue}
              userId={userId}
              onSubmit={() => {
                socket.emit('send_message_to_user', { body: textAreaValue, userId: userId, direction: 'S' });
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
    </Paper>
  );
}
