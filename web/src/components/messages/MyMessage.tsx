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

  const { data, isLoading, refetch ,isFetching} = useGetChannelMembersQuery(
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
      const newUsers = data?.data?.user_channels || [];

      if (userList?.id !== data?.data?.id) {
        setUserList(data?.data);
      } else {

        setUserList((prevUserList) => {
          if (!prevUserList) {

            return data.data;
          }

          const existingUserIds = new Set(prevUserList.user_channels.map((user) => user.id));

          const uniqueUsers = newUsers.filter((user) => !existingUserIds.has(user.id));

          return {
            ...prevUserList,
            user_channels: [...prevUserList.user_channels, ...uniqueUsers],
          };
        });
      }

      // Check if there are more pages
      setHasMore(data?.data?.pagination.currentPage < data.data.pagination?.totalPages);
    }
  }, [data,isFetching]); // Make sure to track userList in the dependency array

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
      const handleNewMessageCountUpdate = ({
        channelId,
        userId,
        message,
      }: {
        channelId: string;
        userId: string;
        message: MessageModel;
      }) => {
        console.log(userList?.id ,channelId, userId, message);

        // Check if the current channel matches the one receiving the socket update
        if (data?.data?.id === channelId) {
          // Update the user list with the new message count
          setUserList((prevUserList) => {
            if (!prevUserList) return prevUserList; // Return if no user list exists

            // Map through the user channels to find and update the user
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

            // Sort the user channels so that the updated user is at the top
            const updatedUserList = updatedUserChannels.sort((a, b) => {
              if (a.userProfileId === userId) return -1;
              if (b.userProfileId === userId) return 1;
              return 0;
            });

            return { ...prevUserList, user_channels: updatedUserList };
          });
        }
      };

      // Attach the event listener when the component mounts
      socket.on('new_message_count_update_staff', handleNewMessageCountUpdate);

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
         socket.off('update_channel_sent_message_count');
          socket.off('new_message_count_update_staff')
      };
    }
  }, [socket,isFetching]);

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
