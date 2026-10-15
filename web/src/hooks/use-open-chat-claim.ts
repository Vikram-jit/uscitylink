import { useEffect, useRef } from 'react';

import { useSocket } from '@/lib/socketProvider';

// The server keeps ONE "staff is viewing driver X" entry per staff account (staff_open_chat), and marks
// that driver's new messages as seen. Every open chat pane in this tab registers a claim here; the most
// recent one (e.g. the notification popup over the Messages pane) is the one reported. Only the tab the
// staff member is actually looking at reports it, so a background tab or second window with another
// driver open can no longer make messages "seen" that nobody looked at.
type Claim = { userId: string };

const claims: Claim[] = [];
let attachedSocket: any = null;

const isViewing = () => typeof document === 'undefined' || document.visibilityState === 'visible';

function report(socket: any) {
  if (!socket) return;
  const top = claims[claims.length - 1];
  socket.emit('staff_open_chat', top && isViewing() ? top.userId : '');
}

function attach(socket: any) {
  if (!socket || attachedSocket === socket) return;
  attachedSocket = socket;
  // The server forgets the open chat on disconnect; claim it again once reconnected
  socket.on('connect', () => report(socket));
  document.addEventListener('visibilitychange', () => report(attachedSocket));
  // Two windows can both be visible; the one being used wins
  window.addEventListener('focus', () => report(attachedSocket));
}

export function useOpenChatClaim(userId: string | null | undefined): void {
  const { socket } = useSocket();
  const claimRef = useRef<Claim | null>(null);

  useEffect(() => {
    if (!socket) return undefined;
    attach(socket);
    const claim: Claim = { userId: '' };
    claimRef.current = claim;
    claims.push(claim);
    return () => {
      const index = claims.indexOf(claim);
      if (index !== -1) claims.splice(index, 1);
      claimRef.current = null;
      report(socket);
    };
  }, [socket]);

  useEffect(() => {
    if (!socket || !claimRef.current) return;
    claimRef.current.userId = userId || '';
    if (claims[claims.length - 1] === claimRef.current) report(socket);
  }, [socket, userId]);
}
