import * as React from 'react';
import { useGetChannelMembersQuery } from '@/redux/ChannelApiSlice';
import { useGetMessagesByUserIdQuery } from '@/redux/MessageApiSlice';
import { SingleChannelModel, UserChannel } from '@/redux/models/ChannelModel';
import { MessageModel } from '@/redux/models/MessageModel';
import { Box, CircularProgress } from '@mui/material';
import { useDispatch, useSelector } from 'react-redux';

import { useSocket } from '@/lib/socketProvider';
import { scheduleBadgeRefresh } from '@/lib/badge-refresh';
import { useSocketEvent } from '@/hooks/use-socket-event';
import useDebounce from '@/hooks/useDebounce';

import ChatsPane from './ChatsPane';
import EmptyChat from './EmptyChat';
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
    { paginate:true,  page, pageSize: 12, search: searchItem, type: selected ? 'truck' : 'user', unreadMessage: unreadMessage },
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
  const { socket, isConnected, reconnectCount } = useSocket();
  const dispatch = useDispatch();

  // Selecting a driver resets the thread paging in the SAME update, so the thread query
  // runs once with its final arguments (it used to fire 3 requests per click)
  const selectUser = React.useCallback((id: string) => {
    setMPage(1);
    setMHasMore(true);
    setPinMessage('0');
    setSelectedUserId(id);
  }, []) as React.Dispatch<React.SetStateAction<string>>;

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
            return data?.data;
          }

          const existingUserIds = new Set(prevUserList?.user_channels.map((user) => user?.id));
          const uniqueUsers = newUsers.filter((user) => !existingUserIds.has(user?.id));

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
    setResetKey(Date.now())

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

  // ---- real-time list updates (leak-free; handlers always see current state via refs) ----
  const channelIdRef = React.useRef<string | undefined>(undefined);
  channelIdRef.current = data?.data?.id;
  const listChannelIdRef = React.useRef<string | undefined>(undefined);
  listChannelIdRef.current = userList?.id;

  // The server announces one driver message up to 3 times (new_message_count_update_staff twice,
  // notification_new_message_with_user once). Count every message exactly once by its id; the
  // server's own unreadCount wins when it is higher (it can lag behind, never run ahead).
  const countedMessageIdsRef = React.useRef(new Set<string>());
  const selectedUserIdRef = React.useRef(selectedUserId);
  selectedUserIdRef.current = selectedUserId;
  const countOnce = (messageId?: string): boolean => {
    if (!messageId) return false;
    const seen = countedMessageIdsRef.current;
    if (seen.has(messageId)) return false;
    if (seen.size > 1000) seen.clear();
    seen.add(messageId);
    return true;
  };

  // Full, per-staff row for the driver (unreadCount, last_message, assigned trucks)
  useSocketEvent('notification_new_message_with_user', (user: UserChannel) => {
    scheduleBadgeRefresh(dispatch);
    if (channelIdRef.current !== user?.channelId) return;
    const isOpen = user?.userProfileId === selectedUserIdRef.current;
    const isNew = countOnce((user as any)?.last_message?.id);
    setUserList((prevUserList) => {
      if (!prevUserList) return prevUserList;
      const { channelId: newChannelId, userProfileId: newUserProfileId } = user;
      let found = false;
      const updatedUserChannels = prevUserList?.user_channels?.map((channel) => {
        if (channel?.channelId === newChannelId && channel?.userProfileId === newUserProfileId) {
          found = true;
          const local = (channel.unreadCount || 0) + (isNew ? 1 : 0);
          return { ...channel, ...user, unreadCount: isOpen ? 0 : Math.max(local, user.unreadCount || 0) };
        }
        return channel;
      });
      if (!found) updatedUserChannels.unshift({ ...user, unreadCount: isOpen ? 0 : user.unreadCount });
      return { ...prevUserList, user_channels: updatedUserChannels };
    });
  });

  useSocketEvent(
    'new_message_count_update_staff',
    ({ channelId, userId, message }: { channelId: string; userId: string; message: MessageModel }) => {
      scheduleBadgeRefresh(dispatch);
      if (channelIdRef.current !== channelId) return;
      const isOpen = userId === selectedUserIdRef.current;
      const isNew = countOnce(message?.id);
      setUserList((prevUserList) => {
        if (!prevUserList) return prevUserList;
        const updatedUserChannels = prevUserList?.user_channels?.map((channel) =>
          channel?.userProfileId === userId
            ? {
                ...channel,
                unreadCount: isOpen ? 0 : (channel.unreadCount || 0) + (isNew ? 1 : 0),
                last_message: message,
              }
            : channel
        );
        const updatedUserList = updatedUserChannels.sort((a, b) => {
          if (a.userProfileId === userId) return -1;
          if (b.userProfileId === userId) return 1;
          return 0;
        });
        return { ...prevUserList, user_channels: updatedUserList };
      });
    }
  );

  useSocketEvent('update_channel', () => {
    setSelectedUserId('');
  });

  useSocketEvent('user_online', (socketData: any) => {
    if (channelIdRef.current !== socketData?.channelId) return;
    setUserList((prevUserList) => {
      if (!prevUserList) return prevUserList;
      const { userId, isOnline } = socketData || {};
      if (!userId) return prevUserList;
      let changed = false;
      const updatedUserChannels = prevUserList.user_channels.map((channel) => {
        if (channel?.userProfileId === userId && channel?.UserProfile?.isOnline !== isOnline) {
          changed = true;
          return { ...channel, UserProfile: { ...channel.UserProfile, isOnline } };
        }
        return channel;
      });
      return changed ? { ...prevUserList, user_channels: updatedUserChannels } : prevUserList;
    });
  });

  // Server ack after a conversation is marked read
  useSocketEvent('update_channel_sent_message_count', ({ channelId, userId }: { channelId: string; userId: string }) => {
    scheduleBadgeRefresh(dispatch);
    if (listChannelIdRef.current !== channelId) return;
    setUserList((prevUserList) => {
      if (!prevUserList) return prevUserList;
      const updatedUserChannels = prevUserList?.user_channels.map((channel) =>
        channel.userProfileId === userId ? { ...channel, unreadCount: 0 } : channel
      );
      return { ...prevUserList, user_channels: updatedUserChannels };
    });
  });

  // After a socket reconnect, resync once (events may have been missed while offline)
  React.useEffect(() => {
    if (reconnectCount === 0) return;
    setUserList(null);
    if (page !== 1) setPage(1);
    else refetch();
    if (selectedUserId) {
      setMPage(1);
      setResetKey(Date.now());
    }
    scheduleBadgeRefresh(dispatch);
    // eslint-disable-next-line react-hooks/exhaustive-deps -- only on reconnect
  }, [reconnectCount]);

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
    { id: selectedUserId, page: mPage, pageSize: 10, pinMessage: pinMessage, resetKey },
    {
      skip: !selectedUserId,
      // Socket delivers new messages; poll only as a fallback while it is disconnected
      pollingInterval: isConnected ? 0 : 30000,
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
        minWidth: 0,

        display: 'grid',
        // minmax(0, 1fr): the chat column must fit the screen; a plain 1fr grows to its widest content
        gridTemplateColumns: {
          xs: 'minmax(0, 1fr)',
          sm: 'minmax(min-content, min(20%, 400px)) minmax(0, 1fr)',
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
          setSelectedUserId={selectUser}
        />
      </Box>
      {mLoader && <CircularProgress />}
      {messageData?.status  && selectedUserId && (
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
      {!selectedUserId && !mLoader && <EmptyChat />}
    </Box>
  );
}
