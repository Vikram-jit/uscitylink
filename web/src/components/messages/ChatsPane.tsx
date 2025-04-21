import * as React from 'react';
import { SingleChannelModel } from '@/redux/models/ChannelModel';
import SearchRoundedIcon from '@mui/icons-material/SearchRounded';
import { Box, Button, CircularProgress, Input, List, Paper, Stack, Typography } from '@mui/material';
import ToggleButton from '@mui/material/ToggleButton';
import ToggleButtonGroup from '@mui/material/ToggleButtonGroup';
import { styled } from '@mui/system';
import { Truck } from '@phosphor-icons/react';
import InfiniteScroll from 'react-infinite-scroll-component';

import ChatListItem from './ChatListItem';
import { RestartAlt } from '@mui/icons-material';

type ChatsPaneProps = {
  chats: SingleChannelModel;
  loadMoreMessages: any;
  hasMore: any;

  setSelectedChannelId?: (id: string) => void;
  selected: boolean;
  setSelected: React.Dispatch<React.SetStateAction<boolean>>;
  selectedChannelId?: string;
  selectedUserId: string;
  setSelectedUserId: (id: string) => void;
  setSearch: React.Dispatch<React.SetStateAction<string>>;
  search: string;
  handleSearchChange: any;
  unreadMessage: string;

  setUserList: React.Dispatch<React.SetStateAction<SingleChannelModel | null>>;
  setUnReadMessage: React.Dispatch<React.SetStateAction<string>>;
  setPage: React.Dispatch<React.SetStateAction<number>>;
  onChangeUnread:()=>void
  handleReset:()=>void
  isFetching: boolean;
  
};

export default function ChatsPane(props: ChatsPaneProps) {
  const handleToggle = () => {
    if (!props.selected == false) {
      props.setSearch('');
    }
    props.setSelected(!props.selected);
  };
  const CustomToggleButton = styled(ToggleButton)(({ theme }) => ({
    '&.Mui-selected, &.Mui-selected:hover': {
      color: theme.palette.common.white,
      backgroundColor: theme.palette.primary.main,
    },
  }));

  const {
    chats,

    setSelectedUserId,
    selectedUserId,
    loadMoreMessages,
    hasMore,
    search,
    handleSearchChange,
  } = props;

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
        </Typography>
        <Button
          size="small"
          variant={props.unreadMessage == '0' ? 'outlined' : 'contained'}
          onClick={() => {
            props.setPage(1)
    
            props.setUnReadMessage(props.unreadMessage == '1' ? '0' : '1');
            props?.onChangeUnread();
          }}
        >
          {props.unreadMessage == '1' ? 'Normal' : 'Un-read'}{' '}
        </Button>
        <Button
          size="small"
          variant="outlined"
          onClick={() => {
            props.handleReset();
          }}  ><RestartAlt/></Button>
      </Stack>
      <Box sx={{ px: 2, pb: 1.5 }}>
        <Input
          value={search}
          onChange={handleSearchChange}
          size="small"
          startAdornment={<SearchRoundedIcon />}
          endAdornment={
            <CustomToggleButton sx={{ marginBottom: 1 }} value="type" selected={props.selected} onChange={handleToggle}>
              <Truck size={18} />
            </CustomToggleButton>
          }
          placeholder="Search"
          aria-label="Search"
          fullWidth
        />
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
        {props.isFetching && <CircularProgress />}
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
                key={chat.userProfileId}
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
