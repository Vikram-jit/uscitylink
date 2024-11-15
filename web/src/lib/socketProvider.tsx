'use client';

import { createContext, useContext, useEffect, useState } from 'react';
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

  const token: any = localStorage.getItem('custom-auth-token');

  useEffect(() => {
    const socketServer = io('http://localhost:4300', {
      query: { token: token },

    });

    if (socketServer.connected) {
      onConnect();
    }

    function onConnect() {
      setIsConnected(true);

      setSocket(socketServer);
    }

    function onDisconnect() {
      setIsConnected(false);
    }

    socketServer.on('connect', onConnect);
    socketServer.on('disconnect', onDisconnect);

    return () => {};
  }, []);

  return <SocketContext.Provider value={{ socket, isConnected }}>{children}</SocketContext.Provider>;
};
