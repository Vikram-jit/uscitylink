'use client';

import * as React from 'react';
import { Button, Dialog, DialogActions, DialogContent, DialogTitle, Typography } from '@mui/material';
import { toast } from 'react-toastify';

import { useSocketEvent } from '@/hooks/use-socket-event';
import { LegBrief, useAnswerTypedLoadMutation } from '@/redux/TripApiSlice';

import { STATUS } from './tripFormat';

// A load pasted / typed straight into a driver's chat is handled like Add load → Send now. The server
// tells the dispatcher who sent it: sent / no Load # in the text / a question to answer (the previous
// leg of this load still open, or the driver already on another load) — same buttons as the form.

interface Typed {
  kind: 'sent' | 'noLoadNo' | 'question';
  id?: string;
  needs?: 'endPrevious' | 'driverBusy' | 'replaceLinedUp';
  info?: { prev?: LegBrief; current?: LegBrief | null; linedUp?: LegBrief };
  loadNo?: string | null;
  tripNo?: string | null;
  legNo?: number;
  driverName?: string;
}

export function TypedLoadQuestion({ enabled }: { enabled: boolean }): React.JSX.Element {
  const [q, setQ] = React.useState<Typed | null>(null);
  const [answer, { isLoading }] = useAnswerTypedLoadMutation();

  const handle = React.useCallback((d: Typed) => {
    if (d.kind === 'sent') {
      toast.success(`Load ${d.loadNo}${d.legNo && d.legNo > 1 ? ` (leg ${d.legNo})` : ''} sent to ${d.driverName || 'the driver'} — from your message`);
    } else if (d.kind === 'noLoadNo') {
      toast.warning(`The load you typed to ${d.driverName || 'the driver'} has no Load # — add a line "LOAD # 1234" and send it again, or use Add load`, { autoClose: 20000 });
    } else {
      setQ(d);
    }
  }, []);
  useSocketEvent<[Typed]>('load:typed', handle, enabled);

  const reply = async (a: { endPrevious?: boolean; endDriverCurrent?: boolean; lineUp?: boolean; replace?: boolean }) => {
    if (!q?.id) return;
    try {
      const res = await answer({ id: q.id, ...a }).unwrap();
      setQ(null);
      handle({ ...res.data, driverName: q.driverName });
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not send the load');
      setQ(null);
    }
  };

  const prev = q?.info?.prev;
  const cur = q?.info?.current;
  const lined = q?.info?.linedUp;
  return (
    <Dialog open={!!q} onClose={() => setQ(null)} maxWidth="sm" fullWidth>
      {q?.needs === 'replaceLinedUp' && lined && (
        <>
          <DialogTitle>Load {q.loadNo} is already lined up</DialogTitle>
          <DialogContent dividers>
            <Typography variant="body2" data-testid="typedAskReplace">
              You sent load {q.loadNo} to <b>{q.driverName}</b> in chat. It&apos;s already lined up (not sent) as <b>#{lined.tripNo}</b> for{' '}
              {lined.driverName || 'no driver'} ({lined.from} → {lined.to}). Replace that copy with this one?
            </Typography>
            {cur && (
              <Typography variant="body2" sx={{ mt: 1 }} color="warning.main">
                {cur.driverName || q.driverName} is on load <b>#{cur.tripNo}</b> now ({STATUS[cur.status]?.label.toLowerCase() || cur.status}).
              </Typography>
            )}
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setQ(null)}>Not now</Button>
            {cur ? (
              <>
                <Button variant="outlined" disabled={isLoading} onClick={() => void reply({ replace: true, lineUp: true })}>
                  Replace &amp; line up after #{cur.tripNo}
                </Button>
                <Button variant="contained" color="warning" disabled={isLoading} onClick={() => void reply({ replace: true, endDriverCurrent: true })}>
                  End #{cur.tripNo} &amp; send
                </Button>
              </>
            ) : (
              <Button variant="contained" disabled={isLoading} onClick={() => void reply({ replace: true })}>
                Replace &amp; send now
              </Button>
            )}
          </DialogActions>
        </>
      )}
      {q?.needs === 'endPrevious' && prev && (
        <>
          <DialogTitle>Load {q.loadNo}: end leg {prev.legNo} first?</DialogTitle>
          <DialogContent dividers>
            <Typography variant="body2" data-testid="typedAskEndPrevious">
              You sent load {q.loadNo} to <b>{q.driverName}</b> in chat. <b>{prev.driverName || 'The driver'}</b> hasn&apos;t ended leg {prev.legNo} (#{prev.tripNo},{' '}
              {prev.from} → {prev.to}) yet. End it now and send this as leg {prev.legNo + 1}?
            </Typography>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setQ(null)}>Not now</Button>
            <Button variant="contained" color="warning" disabled={isLoading} onClick={() => void reply({ endPrevious: true })}>
              End leg {prev.legNo} &amp; send
            </Button>
          </DialogActions>
        </>
      )}
      {q?.needs === 'driverBusy' && cur && (
        <>
          <DialogTitle>{cur.driverName || 'The driver'} is on another load</DialogTitle>
          <DialogContent dividers>
            <Typography variant="body2" data-testid="typedAskDriverBusy">
              You sent load {q.loadNo} in chat, but {cur.driverName || 'the driver'} has load <b>#{cur.tripNo}</b> ({cur.from} → {cur.to},{' '}
              {STATUS[cur.status]?.label.toLowerCase() || cur.status}). End it now and send this one, or line this one up after it?
            </Typography>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setQ(null)}>Not now</Button>
            <Button variant="outlined" disabled={isLoading} onClick={() => void reply({ lineUp: true })}>
              Line up after #{cur.tripNo}
            </Button>
            <Button variant="contained" color="warning" disabled={isLoading} onClick={() => void reply({ endDriverCurrent: true })}>
              End #{cur.tripNo} &amp; send
            </Button>
          </DialogActions>
        </>
      )}
    </Dialog>
  );
}
