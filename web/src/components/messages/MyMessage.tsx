import * as React from 'react';
import { useGetChannelMembersQuery } from '@/redux/ChannelApiSlice';
import { useGetMessagesByUserIdQuery } from '@/redux/MessageApiSlice';
import { SingleChannelModel, UserChannel } from '@/redux/models/ChannelModel';
import { MessageModel } from '@/redux/models/MessageModel';
import { Box, CircularProgress } from '@mui/material';
import { useDispatch, useSelector } from 'react-redux';

import { useSocket } from '@/lib/socketProvider';
import useDebounce from '@/hooks/useDebounce';

import ChatsPane from './ChatsPane';
import MessagesPane from './MessagesPane';

export default function MyMessage() {
  const [page, setPage] = React.useState(1);
  const [hasMore, setHasMore] = React.useState<boolean>(true);
  const [search, setSearch] = React.useState<string>('');
  const [selected, setSelected] = React.useState<boolean>(false);
  const searchItem = useDebounce(search, 200);
  const { trackChannelState } = useSelector((state: any) => state.channel);
  const [unreadMessage, setUnReadMessage] = React.useState<string>('0');

  const { data, isLoading, refetch, isFetching } = useGetChannelMembersQuery(
    { page, pageSize: 12, search: searchItem, type: selected ? 'truck' : 'user', unreadMessage: unreadMessage },
    {
      refetchOnFocus: false,
    }
  );

  const [mPage, setMPage] = React.useState<number>(1);
  const [mHasMore, setMHasMore] = React.useState<boolean>(true);

  const [pinMessage, setPinMessage] = React.useState<string>('0');
  const [resetKey, setResetKey] = React.useState(Date.now()); // Unique number each time
  const [userList, setUserList] = React.useState<SingleChannelModel | null>(null);

  const [selectedUserId, setSelectedUserId] = React.useState<string>('');
  const { socket } = useSocket();

  React.useEffect(() => {
    if (searchItem == '' && page == 1) {
      setUserList(null);
    }
  }, [searchItem]);

  React.useEffect(() => {
    if (data?.status && data?.data) {
      const newUsers = data?.data?.user_channels || [];

      if (userList?.id !== data?.data?.id) {
        setUserList(data?.data);
      } else {
        if (unreadMessage == '1' && page == 1) {
          setUserList(null);
        }
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

      setHasMore(data?.data?.pagination.currentPage < data.data.pagination?.totalPages);
    }
  }, [data, isFetching]);

  const loadMoreMessages = () => {
    if (hasMore && !isLoading) {
      setPage((prevPage) => prevPage + 1);
    }
  };

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearch(event.target.value);
    setPage(1);
    setUserList(null);
    setSelectedUserId('');
  };

  React.useEffect(() => {
    if (trackChannelState > 0) {
      setSearch('');
      setPage(1);
      setUserList(null);
      setSelectedUserId('');

      socket.emit('staff_open_chat', '');
    }
  }, [trackChannelState]);

  React.useEffect(() => {
    if (socket) {
      const handleUpdateUserList = (user: UserChannel) => {
        if (data?.data?.id === user.channelId) {
          setUserList((prevUserList) => {
            if (!prevUserList) return prevUserList;

            const { channelId: newChannelId, userProfileId: newUserProfileId } = user;

            let found = false;

            const updatedUserChannels = prevUserList.user_channels.map((channel) => {
              if (channel.channelId === newChannelId && channel.userProfileId === newUserProfileId) {
                found = true;
                return {
                  ...channel,
                  ...user, // Replace with new user data
                };
              }
              return channel;
            });

            if (!found) {
              // Prepend new user to the beginning
              updatedUserChannels.unshift(user);
            }

            return {
              ...prevUserList,
              user_channels: updatedUserChannels,
            };
          });
        }
      };
      const handleNewMessageCountUpdate = ({
        channelId,
        userId,
        message,
      }: {
        channelId: string;
        userId: string;
        message: MessageModel;
      }) => {
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
                  unreadCount: channel.unreadCount + 1,
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
      socket.on('notification_new_message_with_user', (data: any) => handleUpdateUserList(data));
      // Attach the event listener when the component mounts
      socket.on('new_message_count_update_staff', handleNewMessageCountUpdate);

      socket.on('update_channel', ({ channelId, userId }: { channelId: string; userId: string }) => {
        setSelectedUserId('');
      });

      socket.on('user_online', (socketData: any) => {
        if (data && data.data?.id === socketData?.channelId) {
          setUserList((prevUserList) => {
            if (!prevUserList) return prevUserList;

            const { userId, isOnline } = socketData || {}; // Extract userId and isOnline from socketData

            if (!userId) return prevUserList; // Guard clause for missing userId

            // Create a new list by mapping through the user_channels
            const updatedUserChannels = prevUserList.user_channels.map((channel) => {
              if (channel.userProfileId === userId) {
                // Only update the UserProfile if isOnline has changed
                if (channel.UserProfile.isOnline !== isOnline) {
                  return {
                    ...channel,
                    UserProfile: {
                      ...channel.UserProfile,
                      isOnline, // Update the isOnline status
                    },
                  };
                }
              }
              return channel; // No changes to other channels
            });

            // Check if any changes occurred
            const isChanged = updatedUserChannels.some((channel, index) => {
              return channel !== prevUserList.user_channels[index];
            });

            if (!isChanged) {
              return prevUserList; // No change, return the original list
            }

            return { ...prevUserList, user_channels: updatedUserChannels }; // Return updated state
          });
        }
      });

      socket.on('update_channel_sent_message_count', ({ channelId, userId }: { channelId: string; userId: string }) => {
        if (userList && userList.id === channelId) {
          setUserList((prevUserList) => {
            if (!prevUserList) return prevUserList;

            const updatedUserChannels = prevUserList.user_channels.map((channel) => {
              if (channel.userProfileId === userId) {
                return {
                  ...channel,
                  unreadCount: 0,
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
        socket.off('new_message_count_update_staff');
      };
    }
  }, [socket, userList]);

  function onChangeUnread() {
    setUserList(null);
  }

  const handleReset = () => {
    setSearch('');
    setPage(1);
    setUserList(null);
    setSelected(false);
    setSelectedUserId('');
    setUnReadMessage('0');
    refetch();
    socket.emit('staff_open_chat', '');
  };
  const {
    data: messageData,
    isLoading: mLoader,
    refetch: mRefetch,
    isFetching: mIsFetching,
  } = useGetMessagesByUserIdQuery(
    { id: selectedUserId, page: mPage, pageSize: 10, pinMessage: pinMessage, unreadMessage: unreadMessage, resetKey },
    {
      skip: !selectedUserId,
      pollingInterval: 60000,
      refetchOnFocus: false,
      selectFromResult: ({ data, isLoading, isFetching }) => ({
        data,
        isLoading,
        isFetching,
      }),
    }
  );
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
          isFetching={isFetching}
          handleReset={handleReset}
          onChangeUnread={onChangeUnread}
          setPage={setPage}
          setUserList={setUserList}
          unreadMessage={unreadMessage}
          setUnReadMessage={setUnReadMessage}
          selected={selected}
          setSelected={setSelected}
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
      {mLoader && <CircularProgress />}
      {messageData?.status && (
        <MessagesPane
          page={mPage}
          setPage={setMPage}
          hasMore={mHasMore}
          setHasMore={setMHasMore}
          setResetKey={setResetKey}
          refetch={mRefetch}
          pinMessage={pinMessage}
          setPinMessage={setPinMessage}
          data={messageData?.data}
          isFetching={mIsFetching}
          isLoading={mLoader}
          userId={selectedUserId}
          setUserList={setUserList}
          userList={userList || null}
        />
      )}
      {/* {selectedUserId && } */}
    </Box>
  );
}
