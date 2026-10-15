'use client';

import React from 'react';
import { Box } from '@mui/material';


import SingleMessagesPane from './SingleMessagesPane';

export default function SingleChatUi(
  { id }: { id: string } = { id: '' } // Default value for id
) {
  // SingleMessagesPane claims/releases the open chat (useOpenChatClaim)
  return (
    <Box component="main" className="MainContent">
      <SingleMessagesPane userId={id} />
    </Box>
  );
}
