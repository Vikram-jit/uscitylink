'use client';

import React, { use, useEffect } from 'react';
import { Box } from '@mui/material';

import { useSocket } from '@/lib/socketProvider';

import SingleMessagesPane from './SingleMessagesPane';

export default function SingleChatUi(
  { id }: { id: string } = { id: '' } // Default value for id
) {
  const { socket } = useSocket();

  useEffect(() => {
    if (id) {
    if(socket){
        socket.emit('staff_open_chat', id);
    }
    }
  }, [socket,id]);
  return (
    <Box component="main" className="MainContent">
      <SingleMessagesPane userId={id} />
    </Box>
  );
}
