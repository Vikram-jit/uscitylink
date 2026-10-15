import { useEffect, useRef } from 'react';

import { useSocket } from '@/lib/socketProvider';

// Subscribe to a socket event for the lifetime of the component, leak-free:
// - subscribes once per socket (not on every render or state change),
// - always calls the latest handler, so it never sees stale state,
// - removes exactly its own listener on unmount (never other components' listeners).
export function useSocketEvent<T extends unknown[]>(event: string, handler: (...args: T) => void, enabled = true): void {
  const { socket } = useSocket();
  const handlerRef = useRef(handler);

  useEffect(() => {
    handlerRef.current = handler;
  });

  useEffect(() => {
    if (!socket || !enabled) return undefined;
    const listener = (...args: T) => handlerRef.current(...args);
    socket.on(event, listener);
    return () => {
      socket.off(event, listener);
    };
  }, [socket, event, enabled]);
}
