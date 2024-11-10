import * as React from 'react';
import { useGetMessagesByUserIdQuery } from '@/redux/MessageApiSlice';
import { MessageModel } from '@/redux/models/MessageModel';
import { CircularProgress } from '@mui/material';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Stack from '@mui/material/Stack';

import AvatarWithStatus from './AvatarWithStatus';
import ChatBubble from './ChatBubble';
import MessageInput from './MessageInput';
import MessagesPaneHeader from './MessagesPaneHeader';
import { ChatProps, MessageProps } from './types';
import { useSocket } from '@/lib/socketProvider';

type MessagesPaneProps = {
  userId: string;
};

export default function MessagesPane(props: MessagesPaneProps) {
  const { userId } = props;

  // const [chatMessages, setChatMessages] = React.useState(chat.messages);
  const [textAreaValue, setTextAreaValue] = React.useState('');
  const [messages, setMessages] = React.useState<MessageModel[]>([]);
  const {socket} = useSocket();
  const { data, isLoading } = useGetMessagesByUserIdQuery(
    { id: userId },
    {
      skip: !userId,
    }
  );

  React.useEffect(() => {


    if (data && data?.status) {
      setMessages(data?.data);
    }
  }, [data, isLoading]);

  React.useEffect(()=>{
    if(socket){
      socket.emit("staff_active_channel_user_update",userId);
    }
  },[socket])

  // React.useEffect(() => {
  //   setChatMessages(chat.messages);
  // }, [chat.messages]);

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
      {/* <MessagesPaneHeader sender={chat.sender} /> */}
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
                <Stack key={index} direction="row" spacing={2} sx={{ flexDirection: isYou ? 'row-reverse' : 'row' }}>
                  {message.messageDirection !== 'S' && <AvatarWithStatus online={true} src={'a'} />}
                  <ChatBubble variant={isYou ? 'sent' : 'received'} {...message} attachment={false} />
                </Stack>
              );
            })}
        </Stack>
      </Box>
      {data && (
        <MessageInput
          textAreaValue={textAreaValue}
          setTextAreaValue={setTextAreaValue}
          onSubmit={() => {
            socket.emit("send_message_to_user",{body:textAreaValue,userId:userId,direction:"S"})
            setMessages([
              ...messages,
              {
                id: 'newIdString',
                messageDirection: 'S',
                body: textAreaValue,
                messageTimestampUtc: new Date(),
                userProfileId: userId,
                channelId: '',
                groupId: null,
                deliveryStatus: 'sent',
                senderId: 'string',
                isRead: false,
                status: 'send',
                createdAt: new Date(),
                updatedAt: new Date(),
              },
            ]);
          }}
        />
      )}
    </Paper>
  );
}
