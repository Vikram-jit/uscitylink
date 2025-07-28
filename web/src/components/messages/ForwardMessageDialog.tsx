'use client';

import React, { useEffect, useState } from 'react';
import { useGetChannelMembersQuery } from '@/redux/ChannelApiSlice';
import { SingleChannelModel } from '@/redux/models/ChannelModel';
import { MessageModel } from '@/redux/models/MessageModel';
import SearchIcon from '@mui/icons-material/Search';
import {
  Box,
  Button,
  Checkbox,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  InputAdornment,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Paper,
  Stack,
  styled,
  TextField,
  ToggleButton,
  Typography,
} from '@mui/material';
import { Truck } from '@phosphor-icons/react';
import moment from 'moment';
import InfiniteScroll from 'react-infinite-scroll-component';

import { useSocket } from '@/lib/socketProvider';
import useDebounce from '@/hooks/useDebounce';

import LinkifyText from '../LinkifyText';
import MediaComponent from './MediaComment';

interface ForwardMessageDialogProps {
  open: boolean;
  onClose: () => void;
  message: MessageModel;
}
const CustomToggleButton = styled(ToggleButton)(({ theme }) => ({
  '&.Mui-selected, &.Mui-selected:hover': {
    color: theme.palette.common.white,
    backgroundColor: theme.palette.primary.main,
  },
}));
const ForwardMessageDialog: React.FC<ForwardMessageDialogProps> = ({ open, onClose, message }) => {
  const { socket, isConnected } = useSocket();
  const [page, setPage] = useState<number>(1);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [userList, setUserList] = useState<SingleChannelModel | null>(null);
  const [hasMore, setHasMore] = useState<boolean>(true);
  const [selected, setSelected] = React.useState<boolean>(false);

  const debouncedSearchTerm = useDebounce(searchTerm, 200);
  const { data, isLoading, isFetching } = useGetChannelMembersQuery(
    {
      page,
      pageSize: 12,
      search: debouncedSearchTerm,
      type: selected ? 'truck' : 'user',
      unreadMessage: '0',
    },
    { refetchOnFocus: false }
  );

  useEffect(() => {
    if (data?.status && data?.data) {
      if (page === 1) {
        setUserList(data.data);
      } else {
        setUserList((prev) => ({
          ...data.data,
          user_channels: [...(prev?.user_channels || []), ...(data.data.user_channels || [])],
        }));
      }
      setHasMore(data.data.pagination?.currentPage < data.data.pagination?.totalPages);
    }
  }, [data, page]);

  useEffect(() => {
    // Reset to first page when search term changes
    setPage(1);
    setHasMore(true);
  }, [debouncedSearchTerm]);

  const loadMoreUsers = () => {
    if (!isFetching && hasMore) {
      setPage((prev) => prev + 1);
    }
  };

  const handleToggleUser = (userId: string) => {
    setSelectedUsers((prev) => (prev.includes(userId) ? prev.filter((id) => id !== userId) : [...prev, userId]));
  };

  const handleSend = () => {
    if (selectedUsers.length === 0) return;

    console.log('Sending message to users:', selectedUsers);
    // Add your send logic here

    if (socket && isConnected) {
      socket.emit('FORWARD_MESSAGE_TO_DRIVERS', {
        body: message.body,
        userId: selectedUsers,
        direction: 'S',
        url: message.url,
        thumbnail: message?.thumbnail,
        url_upload_type: message.url_upload_type,
      });
      setPage(1);
      setSelectedUsers([]);
      onClose();
    }
  };

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setUserList(null);
    setPage(1);
    setSearchTerm(e.target.value);
  };
  const handleToggle = () => {
    if (!selected == false) {
      setSearchTerm('');
    }
    setSelected((prev) => !prev);
  };
  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>Forward Message</DialogTitle>

      {/* Top area - Selected message */}
      <Box sx={{ px: 3, pt: 2 }}>
        {message && (
          <Box>
            <Stack direction="row" spacing={2} sx={{ justifyContent: 'space-between', mb: 0.25 }}>
              <Typography variant="body2">
                {message.messageDirection === 'S'
                  ? message.sender?.username
                    ? `${message.sender?.username}(staff)`
                    : '(staff)'
                  : `${message.sender?.username}(${message?.sender?.user?.driver_number})`}
              </Typography>
              <Typography variant="caption">
                {moment(message.messageTimestampUtc).format('MM-DD-YYYY HH:mm A')}
              </Typography>
            </Stack>
            {message.url ? (
              <Paper
                variant="outlined"
                sx={{
                  //   px: 1.75,
                  //   py: 1.25,
                  bgcolor: 'background.paper',

                  borderLeft: '4px solid #ffbf00',
                  mb: 2,
                }}
              >
                {message.url_upload_type == 'not-upload' || message.url_upload_type == 'local' ? (
                  <MediaComponent
                    height={20}
                    messageDirection={message.messageDirection}
                    type={'server'}
                    thumbnail={`http://52.9.12.189:4300/${message.url}`}
                    url={`http://52.9.12.189:4300/${message.url}`}
                    name={message.url ? message.url : ' '}
                  />
                ) : (
                  <MediaComponent
                    height={100}
                    thumbnail={`https://ciity-sms.s3.us-west-1.amazonaws.com/${message.thumbnail}`}
                    url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${message.url}`}
                    name={message.url ? message.url : ' '}
                  />
                )}

                {message.body && <LinkifyText text={message.body} />}
              </Paper>
            ) : (
              <Box sx={{ position: 'relative', mb: 2 }}>
                <Paper
                  sx={{
                    p: 1.25,

                    bgcolor: 'background.paper',

                    borderLeft: '4px solid #ffbf00',
                  }}
                >
                  <LinkifyText text={message.body} />
                </Paper>
              </Box>
            )}
          </Box>
        )}
      </Box>

      <Divider sx={{ my: 2 }} />

      {/* Body - Search and Driver list with checkboxes */}
      <DialogContent>
        <TextField
          fullWidth
          variant="outlined"
          placeholder="Search drivers by name or vehicle..."
          value={searchTerm}
          onChange={handleSearchChange}
          sx={{ mb: 2 }}
          InputProps={{
            endAdornment: (
              <CustomToggleButton sx={{ marginBottom: 1 }} value="type" selected={selected} onChange={handleToggle}>
                <Truck size={18} />
              </CustomToggleButton>
            ),
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
        />

        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
          Select Drivers:
        </Typography>

        {isLoading && page === 1 ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
            <CircularProgress />
          </Box>
        ) : userList?.user_channels?.length === 0 ? (
          <Typography variant="body2" color="text.secondary" sx={{ textAlign: 'center', py: 2 }}>
            No drivers found matching your search
          </Typography>
        ) : (
          <Box id="scrollable-drivers-container" sx={{ maxHeight: 300, overflow: 'auto' }}>
            <InfiniteScroll
              dataLength={userList?.user_channels?.length || 0}
              next={loadMoreUsers}
              hasMore={hasMore}
              loader={
                <Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
                  <CircularProgress size={24} />
                </Box>
              }
              scrollThreshold={0.95}
              scrollableTarget="scrollable-drivers-container"
            >
              <List>
                {userList?.user_channels?.map((user) => (
                  <ListItem key={user.id} button onClick={() => handleToggleUser(user.UserProfile.id)}>
                    <ListItemIcon>
                      <Checkbox
                        edge="start"
                        checked={selectedUsers.includes(user.userProfileId)}
                        tabIndex={-1}
                        disableRipple
                      />
                    </ListItemIcon>
                    <ListItemText
                      primary={user.UserProfile?.username || 'Unknown'}
                      secondary={`Vehicle: ${user.assginTrucks || 'Not assigned'}`}
                    />
                  </ListItem>
                ))}
              </List>
            </InfiniteScroll>
          </Box>
        )}
      </DialogContent>

      <Divider sx={{ my: 1 }} />

      {/* Footer - Action buttons */}
      <DialogActions sx={{ p: 2 }}>
        <Button onClick={onClose} color="secondary">
          Cancel
        </Button>
        <Button onClick={handleSend} variant="contained" color="primary" disabled={selectedUsers.length === 0}>
          Send
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ForwardMessageDialog;
