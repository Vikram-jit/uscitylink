import * as React from 'react';
import { useGetChannelMembersQuery } from '@/redux/ChannelApiSlice';
import { SingleChannelModel } from '@/redux/models/ChannelModel';
import { MessageModel } from '@/redux/models/MessageModel';
import { Box, CircularProgress } from '@mui/material';
import { useDispatch } from 'react-redux';

import { useSocket } from '@/lib/socketProvider';

import ChatsPane from './ChatsPane';
import MessagesPane from './MessagesPane';
import useDebounce from '@/hooks/useDebounce';

export default function MyMessage() {
  const [page, setPage] = React.useState(1);
  const [hasMore, setHasMore] = React.useState<boolean>(true);
  const [search,setSearch] = React.useState<string>("")

  const searchItem = useDebounce(search,200)

  const { data, isLoading, refetch } = useGetChannelMembersQuery(
    { page, pageSize: 12,search:searchItem },
    {
      refetchOnFocus: true,
    }
  );

  const [userList, setUserList] = React.useState<SingleChannelModel | null>(null);

  const [selectedUserId, setSelectedUserId] = React.useState<string>('');
  const { socket } = useSocket();

  React.useEffect(() => {
    if (data?.status && data?.data) {
      setUserList((prev) => ({
        ...prev,
        ...data?.data, // Spread the rest of data into the state
        user_channels: [
          ...(prev?.user_channels || []), // Fallback to an empty array if prev.user_channels is undefined
          ...(data?.data?.user_channels || []), // Fallback to an empty array if data?.data?.user_channels is undefined
        ],
      }));
      setHasMore(data?.data?.pagination.currentPage < data.data.pagination?.totalPages);
    }
  }, [data, isLoading]);

  const loadMoreMessages = () => {

    if (hasMore && !isLoading) {
      setPage((prevPage) => prevPage + 1);
    }
  };

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearch(event.target.value);
    setPage(1);
    setUserList(null);
    setSelectedUserId("")
  };

  React.useEffect(() => {
    const handleFocus = () => {
      refetch();
    };

    window.addEventListener('focus', handleFocus);

    return () => {
      window.removeEventListener('focus', handleFocus);
    };
  }, [refetch]);

  React.useEffect(() => {
    if (socket) {
      socket.on(
        'new_message_count_update_staff',
        ({ channelId, userId, message }: { channelId: string; userId: string; message: MessageModel }) => {
          if (userList && userList.id === channelId) {
            setUserList((prevUserList) => {
              if (!prevUserList) return prevUserList;

              const updatedUserChannels = prevUserList.user_channels.map((channel) => {
                if (channel.userProfileId === userId) {
                  return {
                    ...channel,
                    sent_message_count: channel.sent_message_count + 1,
                    last_message: message,
                  };
                }
                return channel;
              });

              const updatedUserList = updatedUserChannels.sort((a, b) => {
                if (a.userProfileId === userId) return -1;
                if (b.userProfileId === userId) return 1;
                return 0;
              });

              return { ...prevUserList, user_channels: updatedUserList };
            });
          }
        }
      );

      socket.on('update_channel', ({ channelId, userId }: { channelId: string; userId: string }) => {
        setSelectedUserId('');
      });

      socket.on('update_channel_sent_message_count', ({ channelId, userId }: { channelId: string; userId: string }) => {
        if (userList && userList.id === channelId) {
          setUserList((prevUserList) => {
            if (!prevUserList) return prevUserList;

            const updatedUserChannels = prevUserList.user_channels.map((channel) => {
              if (channel.userProfileId === userId) {
                return {
                  ...channel,
                  sent_message_count: 0,
                };
              }
              return channel;
            });

            return { ...prevUserList, user_channels: updatedUserChannels };
          });
        }
      });
      return () => {
        // socket.off('update_channel_sent_message_count');
        //  socket.off('new_message_count_update_staff')
      };
    }
  }, [socket]);

  if (isLoading) {
    return <CircularProgress />;
  }

  return (
    <Box
      sx={{
        flex: 1,
        width: '100%',

        display: 'grid',
        gridTemplateColumns: {
          xs: '1fr',
          sm: 'minmax(min-content, min(20%, 400px)) 1fr',
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
        search={search}
        setSearch={setSearch}
        handleSearchChange={handleSearchChange}
          hasMore={hasMore}
          loadMoreMessages={loadMoreMessages}
          chats={userList!}
          selectedUserId={selectedUserId}
          setSelectedUserId={setSelectedUserId}
        />
      </Box>
      {selectedUserId && <MessagesPane userId={selectedUserId} setUserList={setUserList} userList={userList || null} />}
    </Box>
  );
}
