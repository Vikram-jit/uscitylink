'use client';

import { createContext, useContext, useEffect, useState } from 'react';
import { apiSlice } from '@/redux/apiSlice';
import { useDispatch } from 'react-redux';
import { toast } from 'react-toastify';
import { io } from 'socket.io-client';

type SocketContextType = {
  socket: any | null;
  isConnected: boolean;
};

const SocketContext = createContext<SocketContextType>({
  socket: null,
  isConnected: false,
});

export const useSocket = () => {
  return useContext(SocketContext);
};

export const SocketProvider = ({
  children,
  id = null,
  type = 'sms',
}: {
  children: React.ReactNode;
  id?: number | null;
  type?: string;
}) => {
  const [socket, setSocket] = useState<any>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [reconnectAttempts, setReconnectAttempts] = useState(0);

  const token: any = localStorage.getItem('custom-auth-token');
  const dispatch = useDispatch();
  useEffect(() => {
    const socketServer = io(process.env.SOCKET_URL, {
      query: { token: token },
      reconnection: true, // Ensure reconnection is enabled
      reconnectionAttempts: Infinity, // Unlimited attempts
      reconnectionDelay: 1000, // Delay between each attempt
      reconnectionDelayMax: 5000, // Maximum delay between attempts
      timeout: 20000, // Timeout for initial connection
    });

    if (socketServer.connected) {
      onConnect();
    }

    const onReconnectAttempt = (attempt: number) => {
      setReconnectAttempts(attempt);
      console.log(`Attempting to reconnect... Attempt ${attempt}`);
    };

    const onReconnectError = (error: any) => {
      console.error('Reconnection error:', error);
    };

    const onReconnectFailed = () => {
      console.error('Failed to reconnect after multiple attempts');
      toast.error('Unable to reconnect to the server.');
    };

    function onConnect() {
      setIsConnected(true);
      setReconnectAttempts(0); //
      setSocket(socketServer);
    }

    function onDisconnect() {
      setIsConnected(false);
    }
    socketServer.on('user_online', () => {
      dispatch(apiSlice.util.invalidateTags([{ type: 'channelUsers', id: 1 }]));
      dispatch(apiSlice.util.invalidateTags(['channels']));
      dispatch(apiSlice.util.invalidateTags([{ type: 'members', id: 1 }]));
      dispatch(apiSlice.util.invalidateTags([{ type: 'messages', id: 1 }]));
    });
    socketServer.on('connect', onConnect);
    socketServer.on('disconnect', onDisconnect);
    socketServer.on('notification_new_message', (message: string) => {
      socketServer.on('reconnect_attempt', onReconnectAttempt);
      socketServer.on('reconnect_error', onReconnectError);
      socketServer.on('reconnect_failed', onReconnectFailed);
      toast.success(message);
      dispatch(apiSlice.util.invalidateTags([{ type: 'channelUsers', id: 1 }]));
      dispatch(apiSlice.util.invalidateTags(['channels']));
      dispatch(apiSlice.util.invalidateTags([{ type: 'members', id: 1 }]));
      dispatch(apiSlice.util.invalidateTags([{ type: 'messages', id: 1 }]));
    });
    socketServer.on("notification_group",(message)=>{
      toast.success(message);
     // dispatch(apiSlice.util.invalidateTags(['groups', 'group', ]));
    })
    socketServer.on('reconnect_attempt', onReconnectAttempt);
      socketServer.on('reconnect_error', onReconnectError);
      socketServer.on('reconnect_failed', onReconnectFailed);
    socketServer.on('typingUser', (data: any) => {
      console.log(data.userId);
      // if(data.userId == props.userId){
      //   setUserTyping(data?.isTyping)
      // }
    });
    // Ping server every 5 seconds
    const pingInterval = setInterval(() => {
      if (isConnected) {
        console.log('Sending ping...');
        socketServer.emit('ping'); // Send a ping message to the server
      }
    }, 5000);

    return () => {
      //    socketServer.off("new_message_count_update_staff");
      //    socketServer.off("notification_new_message");
      //    socketServer.off("update_channel_sent_message_count");
      //  socketServer.off('staff_open_chat');
      socketServer.off('reconnect_attempt', onReconnectAttempt);
      socketServer.off('reconnect_error', onReconnectError);
      socketServer.off('reconnect_failed', onReconnectFailed);
      clearInterval(pingInterval);
      socketServer.off('pong');
      socketServer.disconnect();
    };
  }, [token, dispatch]);

  useEffect(() => {
    const handleFocus = () => {
      if (!isConnected && socket) {
        console.log('Window focused. Attempting to reconnect.');
        socket.connect(); // Attempt to reconnect if socket is disconnected
      }
    };

    window.addEventListener('focus', handleFocus);

    // Cleanup the event listener
    return () => {
      window.removeEventListener('focus', handleFocus);
    };
  }, [isConnected, socket]);

  return <SocketContext.Provider value={{ socket, isConnected }}>{children}</SocketContext.Provider>;
};
