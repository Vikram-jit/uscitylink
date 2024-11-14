import { Box, CircularProgress } from '@mui/material';
import * as React from 'react';
import ChatsPane from './ChatsPane';


import MessagesPane from './MessagesPane';
import { useGetChannelMembersQuery } from '@/redux/ChannelApiSlice';
import { SingleChannelModel } from '@/redux/models/ChannelModel';
import { useSocket } from '@/lib/socketProvider';
import { MessageModel } from '@/redux/models/MessageModel';
import { toast } from 'react-toastify';

export default function MyMessage() {

  const {data,isLoading} = useGetChannelMembersQuery();

  const [userList,setUserList] = React.useState<SingleChannelModel|null>(null);

  const [selectedUserId, setSelectedUserId] = React.useState<string>("");
  const {socket} = useSocket()
   // Effect to set the user list from data
   React.useEffect(() => {
    if (data?.status && data?.data) {
      setUserList(data?.data); // Assuming data.data is of type SingleChannelModel
    }
  }, [data, isLoading]);

  // Effect to handle new messages and update the user list when a socket event is received
  React.useEffect(() => {
    if (socket) {
      socket.on("new_message_count_update_staff", ({ channelId, userId,message }: { channelId: string; userId: string,message:MessageModel }) => {
        if (userList && userList.id === channelId) {

          setUserList((prevUserList) => {
            if (!prevUserList) return prevUserList;


            const updatedUserChannels = prevUserList.user_channels.map((channel) => {

              if (channel.userProfileId === userId) {
                return {
                  ...channel,
                  sent_message_count: channel.sent_message_count + 1,
                  last_message:message
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
      });
      socket.on("notification_new_message",(message:string)=>{
        toast.success(message)
      })

      socket.on("update_channel",({channelId,userId}:{channelId:string,userId:string})=>{
        setSelectedUserId("")
      })

      socket.on("update_channel_sent_message_count",({channelId,userId}:{channelId:string,userId:string})=>{
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
      })
      return () => {
        socket.off("new_message_count_update_staff");
        socket.off("notification_new_message");
        socket.off("update_channel_sent_message_count");
      };
    }
  }, [socket, userList]);




  if(isLoading){
    return <CircularProgress/>
  }

  return (
    <Box
      sx={{
        flex: 1,
        width: '100%',

        display: 'grid',
        gridTemplateColumns: {
          xs: '1fr',
          sm: 'minmax(min-content, min(30%, 400px)) 1fr',
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

          chats={userList!}
          selectedUserId={selectedUserId}
          setSelectedUserId={setSelectedUserId}
        />
      </Box>
      <MessagesPane userId={selectedUserId} />
    </Box>
  );
}
