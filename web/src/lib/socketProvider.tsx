'use client';

import { createContext, useContext, useEffect, useState } from 'react';
import { apiSlice } from '@/redux/apiSlice';
import { scheduleTagRefresh } from '@/lib/badge-refresh';
import { useDispatch } from 'react-redux';
import { toast } from 'react-toastify';
import { io } from 'socket.io-client';

type SocketContextType = {
  socket: any | null;
  isConnected: boolean;
  // Increments on every reconnect after the first connect; screens resync once when it changes
  reconnectCount: number;
};

const SocketContext = createContext<SocketContextType>({
  socket: null,
  isConnected: false,
  reconnectCount: 0,
});



export const useSocket = () => {
  return useContext(SocketContext);
};
let audioContext: AudioContext | null = null;

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
  // const [audioContext, setAudioContext] = useState<any>(null)
  const [newMessage,setNewMessage] = useState<boolean>(false)
  const [reconnectCount, setReconnectCount] = useState(0);
  // Read once in the browser; localStorage does not exist during server rendering
  const [token] = useState<string | null>(() =>
    typeof window === 'undefined' ? null : localStorage.getItem('custom-auth-token')
  );
  const dispatch = useDispatch();
  useEffect(() => {
    let hasConnectedBefore = false;
    const socketServer = io(process.env.SOCKET_URL, {
      transports: ['websocket'],
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
      // Anything missed while offline is recovered by the screens on this signal
      if (hasConnectedBefore) setReconnectCount((count) => count + 1);
      hasConnectedBefore = true;
    }

    function onDisconnect() {
      setIsConnected(false);
    }
    
    socketServer.on('connect', onConnect);
    socketServer.on('disconnect', onDisconnect);
    const onNotificationNewMessage = (message: string) => {
      toast.success(message);
      document.title = "New Message";
     // dispatch(apiSlice.util.invalidateTags([ 'messages','channels']));
      //dispatch(apiSlice.util.invalidateTags(['dashboard','channels']));
      const audio = new Audio('https://ciity-sms.s3.us-west-1.amazonaws.com/mixkit-positive-notification-951.wav')

      audio.addEventListener('canplaythrough', () => {
        // the audio is now playable; play it if permissions allow
        audio.play()
      })
    };
    socketServer.on('notification_new_message', onNotificationNewMessage);
    const onNotificationGroup = (message: string) => {
      toast.success(message);
      const audio = new Audio('https://ciity-sms.s3.us-west-1.amazonaws.com/mixkit-positive-notification-951.wav')

      audio.addEventListener('canplaythrough', () => {
        // the audio is now playable; play it if permissions allow
        audio.play()
      })
     // Coalesced: a burst of group messages refreshes the badges/dashboard once
     scheduleTagRefresh(dispatch, ['channels', 'dashboard']);
    };
    socketServer.on('notification_group', onNotificationGroup);

    // Document automation: refresh the chip on the attachment once the AI has read it
    const onDocumentAnalyzed = (doc: { message_id: string }) => {
      dispatch(apiSlice.util.invalidateTags([{ type: 'messageDocument', id: doc.message_id }, 'reviewQueue']));
    };
    socketServer.on('document_analyzed', onDocumentAnalyzed);
    const onAutomationAlert = (alert: { title?: string; body?: string; severity?: string; driverName?: string }) => {
      const text = [alert.title, alert.body].filter(Boolean).join(' — ') || 'Automation alert';
      if (alert.severity === 'critical') toast.error(text, { autoClose: false });
      else if (alert.severity === 'info') toast.info(text);
      else toast.warning(text, { autoClose: 15000 });
    };
    socketServer.on('automation_alert', onAutomationAlert);

    const onNotificationForward = (message: string) => {
      toast.success(message);
      const audio = new Audio('https://ciity-sms.s3.us-west-1.amazonaws.com/mixkit-positive-notification-951.wav')

      audio.addEventListener('canplaythrough', () => {
        // the audio is now playable; play it if permissions allow
        audio.play()
      })
     // 
      dispatch(apiSlice.util.invalidateTags(['members']));
    };
    socketServer.on('notification_forward_message', onNotificationForward);
   const createAudioContext = () => {
  if (!audioContext) {
    try {
      // Create audio context
      audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      
      // Optionally resume it if it was suspended
      if (audioContext.state === 'suspended') {
        audioContext.resume().then(() => {
          console.log('AudioContext successfully resumed');
        });
      }

      // Remove event listeners after first successful interaction
      document.removeEventListener('click', createAudioContext);
      document.removeEventListener('touchstart', createAudioContext);
    } catch (error) {
      console.error('AudioContext creation failed:', error);
    }
  }
};

// Add event listeners for both mouse and touch
document.addEventListener('click', createAudioContext, { once: true });
document.addEventListener('touchstart', createAudioContext, { once: true });


    socketServer.on('reconnect_attempt', onReconnectAttempt);
      socketServer.on('reconnect_error', onReconnectError);
      socketServer.on('reconnect_failed', onReconnectFailed);

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
      socketServer.off('connect', onConnect);
      socketServer.off('disconnect', onDisconnect);
      socketServer.off('notification_new_message', onNotificationNewMessage);
      socketServer.off('notification_group', onNotificationGroup);
      socketServer.off('notification_forward_message', onNotificationForward);
      socketServer.off('document_analyzed', onDocumentAnalyzed);
      socketServer.off('automation_alert', onAutomationAlert);
      socketServer.off('reconnect_attempt', onReconnectAttempt);
      socketServer.off('reconnect_error', onReconnectError);
      socketServer.off('reconnect_failed', onReconnectFailed);
      document.removeEventListener('click', createAudioContext);
      document.removeEventListener('touchstart', createAudioContext);
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

  return <SocketContext.Provider value={{ socket, isConnected, reconnectCount }}> {children}</SocketContext.Provider>;
};
