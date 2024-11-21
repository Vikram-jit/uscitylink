'use client';

import { apiSlice } from '@/redux/apiSlice';
import { createContext, useContext, useEffect, useState } from 'react';
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
  const [reconnectAttempts, setReconnectAttempts] = useState(0); // Track number of reconnection attempts

  const token: any = localStorage.getItem('custom-auth-token');
  const dispatch  = useDispatch()
  useEffect(() => {
    const socketServer = io('http://52.8.75.98:4300', {
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

    socketServer.on('connect', onConnect);
    socketServer.on('disconnect', onDisconnect);
    socketServer.on("notification_new_message",(message:string)=>{
      socketServer.on('reconnect_attempt', onReconnectAttempt);
      socketServer.on('reconnect_error', onReconnectError);
      socketServer.on('reconnect_failed', onReconnectFailed);
      toast.success(message)
      dispatch(apiSlice.util.invalidateTags(['channelUsers',"channels","members"]))
    })
    socketServer.on("typingUser",(data:any)=>{
      console.log(data.userId)
      // if(data.userId == props.userId){
      //   setUserTyping(data?.isTyping)
      // }
    })
    return () => {

    //    socketServer.off("new_message_count_update_staff");
    //    socketServer.off("notification_new_message");
    //    socketServer.off("update_channel_sent_message_count");
    //  socketServer.off('staff_open_chat');
    socketServer.off('reconnect_attempt', onReconnectAttempt);
    socketServer.off('reconnect_error', onReconnectError);
    socketServer.off('reconnect_failed', onReconnectFailed);
    socketServer.close();
    };
  }, [token,dispatch]);

  return <SocketContext.Provider value={{ socket, isConnected }}>{children}</SocketContext.Provider>;
};
