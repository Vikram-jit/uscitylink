import { Box, CircularProgress } from '@mui/material';
import * as React from 'react';
import ChatsPane from './ChatsPane';

import { ChatProps } from './types';
import { chats } from './data';
import MessagesPane from './MessagesPane';
import { useGetChannelMembersQuery } from '@/redux/ChannelApiSlice';

export default function MyMessage() {

  const {data,isLoading} = useGetChannelMembersQuery();

  const [selectedChannelId, setSelectedChannelId] = React.useState<string>("");

  const [selectedUserId, setSelectedUserId] = React.useState<string>("");

  if(isLoading){
    return <CircularProgress/>
  }

  return (
    <Box
      sx={{
        flex: 1,
        width: '100%',

        display: 'grid',
        gridTemplateColumns: {
          xs: '1fr',
          sm: 'minmax(min-content, min(30%, 400px)) 1fr',
        },
      }}
    >
      <Box
        sx={{
          position: { xs: 'fixed', sm: 'sticky' },
          transform: {
            xs: 'translateX(calc(100% * (var(--MessagesPane-slideIn, 0) - 1)))',
            sm: 'none',
          },
          transition: 'transform 0.4s, width 0.4s',
          zIndex: 100,
          width: '100%',

        }}
      >
       <ChatsPane
          chats={data?.data!}
          selectedUserId={selectedUserId}
          setSelectedUserId={setSelectedUserId}
        />
      </Box>
      <MessagesPane userId={selectedUserId} />
    </Box>
  );
}
