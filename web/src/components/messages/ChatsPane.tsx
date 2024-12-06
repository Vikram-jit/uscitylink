import * as React from 'react';
import { SingleChannelModel } from '@/redux/models/ChannelModel';
import CloseRoundedIcon from '@mui/icons-material/CloseRounded';
import EditNoteRoundedIcon from '@mui/icons-material/EditNoteRounded';
import SearchRoundedIcon from '@mui/icons-material/SearchRounded';
import { Box, Chip, IconButton, Input, List, Paper, Stack, Typography } from '@mui/material';
import InfiniteScroll from 'react-infinite-scroll-component';

import ChatListItem from './ChatListItem';
import { ChatProps } from './types';
import { toggleMessagesPane } from './utils';

type ChatsPaneProps = {
  chats: SingleChannelModel;
  loadMoreMessages: any;
  hasMore: any;
  setSelectedChannelId?: (id: string) => void;

  selectedChannelId?: string;
  selectedUserId: string;
  setSelectedUserId: (id: string) => void;
  setSearch:React.Dispatch<React.SetStateAction<string>>
  search:string,
  handleSearchChange:any
};

export default function ChatsPane(props: ChatsPaneProps) {
  const {
    chats,
    setSelectedChannelId,
    selectedChannelId,
    setSelectedUserId,
    selectedUserId,
    loadMoreMessages,
    hasMore,
    setSearch,
    search,
    handleSearchChange
  } = props;
  const messagesContainerRef = React.useRef<HTMLDivElement | null>(null);

  return (
    <Paper
      sx={{
        borderRight: '1px solid',
        borderColor: 'divider',
        height: { sm: 'calc(100vh - 5vh)', md: '92vh' },
        overflowY: 'auto',
      }}
    >
      <Stack direction="row" spacing={1} sx={{ alignItems: 'center', justifyContent: 'space-between', p: 2, pb: 1.5 }}>
        <Typography variant="h6" component="h1" sx={{ fontWeight: 'bold', mr: 'auto' }}>
          Messages
          {/* <Chip
            variant="outlined"
            color="primary"
            size="small"
            label="4"
            sx={{ ml: 1 }}
          /> */}
        </Typography>
        {/* <IconButton
          aria-label="edit"
          color="inherit"
          size="small"
          sx={{ display: { xs: 'none', sm: 'flex' } }}
        >
          <EditNoteRoundedIcon />
        </IconButton> */}
        {/* <IconButton
          aria-label="close"
          color="inherit"
          size="small"
          onClick={toggleMessagesPane}
          sx={{ display: { sm: 'none' } }}
        >
          <CloseRoundedIcon />
        </IconButton> */}
      </Stack>
      <Box sx={{ px: 2, pb: 1.5 }}>
        <Input value={search} onChange={handleSearchChange} size="small" startAdornment={<SearchRoundedIcon />} placeholder="Search" aria-label="Search" fullWidth />
      </Box>
      <List
        id="scrollable-channel-container"
        sx={{
          py: 0,
          paddingY: '0.75rem',
          paddingX: '1rem',
          padding: 0,
          maxHeight: '650px',
          overflowY: 'auto',
        }}
      >
        {chats?.user_channels && (
          <InfiniteScroll
            dataLength={chats?.user_channels?.length}
            next={loadMoreMessages}
            hasMore={hasMore}
            loader={<h4>Loading...</h4>}
            scrollThreshold={0.95}
            scrollableTarget="scrollable-channel-container"
          >
            {chats?.user_channels?.map((chat) => (
              <ChatListItem
                key={chat.id}
                id={chat?.userProfileId}
                user={chat}
                channelId={chats.id}
                selectedUserId={selectedUserId}
                setSelectedUserId={setSelectedUserId}
              />
            ))}
          </InfiniteScroll>
        )}
      </List>
    </Paper>
  );
}
