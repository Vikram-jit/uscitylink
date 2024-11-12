import * as React from 'react';
import { Stack, Box, Chip, IconButton, Input, List, Typography, Paper } from '@mui/material';
import EditNoteRoundedIcon from '@mui/icons-material/EditNoteRounded';
import SearchRoundedIcon from '@mui/icons-material/SearchRounded';
import CloseRoundedIcon from '@mui/icons-material/CloseRounded';
import ChatListItem from './ChatListItem';
import { ChatProps } from './types';
import { toggleMessagesPane } from './utils';
import { SingleChannelModel } from '@/redux/models/ChannelModel';

type ChatsPaneProps = {
  chats: SingleChannelModel;
  setSelectedChannelId?: (id: string) => void;
  selectedChannelId?: string;
  selectedUserId:string;
  setSelectedUserId: (id: string) => void;

};

export default function ChatsPane(props: ChatsPaneProps) {
  const { chats, setSelectedChannelId, selectedChannelId,setSelectedUserId,selectedUserId } = props;

  return (
    <Paper
      sx={{
        borderRight: '1px solid',
        borderColor: 'divider',
        height: { sm: 'calc(100vh - 5vh)', md: '92vh' },
        overflowY: 'auto',
      }}
    >
      <Stack
        direction="row"
        spacing={1}
        sx={{ alignItems: 'center', justifyContent: 'space-between', p: 2, pb: 1.5 }}
      >
        <Typography
          variant="h6"
          component="h1"
          sx={{ fontWeight: 'bold', mr: 'auto' }}
        >
          Messages
          <Chip
            variant="outlined"
            color="primary"
            size="small"
            label="4"
            sx={{ ml: 1 }}
          />
        </Typography>
        <IconButton
          aria-label="edit"
          color="inherit"
          size="small"
          sx={{ display: { xs: 'none', sm: 'flex' } }}
        >
          <EditNoteRoundedIcon />
        </IconButton>
        <IconButton
          aria-label="close"
          color="inherit"
          size="small"
          onClick={toggleMessagesPane}
          sx={{ display: { sm: 'none' } }}
        >
          <CloseRoundedIcon />
        </IconButton>
      </Stack>
      <Box sx={{ px: 2, pb: 1.5 }}>
        <Input
          size="small"
          startAdornment={<SearchRoundedIcon />}
          placeholder="Search"
          aria-label="Search"
          fullWidth
        />
      </Box>
      <List
        sx={{
          py: 0,
          paddingY: '0.75rem',
          paddingX: '1rem',
        }}
      >
        {chats?.user_channels?.map((chat) => (
          <ChatListItem
            key={chat.id}
            id={chat?.userProfileId}
            user={chat}
            selectedUserId={selectedUserId}
            setSelectedUserId={setSelectedUserId}
          />
        ))}
      </List>
    </Paper>
  );
}
