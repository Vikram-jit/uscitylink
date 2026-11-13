'use client';

import * as React from 'react';
import { Alert, Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, Stack, Typography } from '@mui/material';

import { LegBrief } from '@/redux/TripApiSlice';

import { STATUS } from './tripFormat';

// The questions the server asks before a load goes out (409 { needs, info }): the previous leg of
// this load is still open, the driver is on another load, or this Load # is already lined up.

export type LoadAnswers = { endPrevious?: boolean; endDriverCurrent?: boolean; lineUp?: boolean; replace?: boolean };
export type LoadQuestion = {
  needs: 'endPrevious' | 'driverBusy' | 'replaceLinedUp';
  info: { prev?: LegBrief; current?: LegBrief | null; linedUp?: LegBrief };
};

const statusText = (l: LegBrief) => STATUS[l.status]?.label.toLowerCase() || l.status;

function LegBox({ label, leg }: { label: string; leg: LegBrief }) {
  return (
    <Box sx={{ p: 1.5, borderRadius: 2, border: 1, borderColor: 'divider', bgcolor: 'action.hover' }}>
      <Typography variant="caption" color="text.secondary" sx={{ textTransform: 'uppercase', letterSpacing: 0.6 }}>
        {label}
      </Typography>
      <Typography variant="body2" fontWeight={700}>
        #{leg.tripNo} · {leg.driverName || 'No driver'}
        {leg.truck ? ` · Truck ${leg.truck}` : ''}
      </Typography>
      <Typography variant="body2" color="text.secondary">
        {leg.from} → {leg.to}
      </Typography>
    </Box>
  );
}

export function LoadQuestionDialog({
  question,
  loadNo,
  driverName,
  busy,
  onAnswer,
  onClose,
}: {
  question: LoadQuestion | null;
  loadNo: string;
  driverName: string;
  busy?: boolean;
  onAnswer: (a: LoadAnswers) => void;
  onClose: () => void;
}): React.JSX.Element {
  const q = question;
  const prev = q?.info.prev;
  const cur = q?.info.current || null;
  const lined = q?.info.linedUp;
  return (
    <Dialog open={!!q} onClose={onClose} maxWidth="sm" fullWidth>
      {q?.needs === 'replaceLinedUp' && lined && (
        <>
          <DialogTitle>Load {loadNo} is already lined up</DialogTitle>
          <DialogContent dividers>
            <Stack spacing={1.5} data-testid="askReplaceLinedUp">
              <LegBox label="Lined up · not sent yet" leg={lined} />
              <Typography variant="body2">
                Sending this load replaces that copy — it comes off the lineup (kept in the load&apos;s history) and this one takes its place with the same number.
              </Typography>
              {cur && (
                <Alert severity="warning" icon={false}>
                  <b>{cur.driverName || driverName}</b> is on load <b>#{cur.tripNo}</b> now ({cur.from} → {cur.to}, {statusText(cur)}). End it and send this one, or line
                  this one up after it?
                </Alert>
              )}
            </Stack>
          </DialogContent>
          <DialogActions>
            <Button onClick={onClose}>Cancel</Button>
            {cur ? (
              <>
                <Button variant="outlined" disabled={busy} onClick={() => onAnswer({ replace: true, lineUp: true })} data-testid="qReplaceLineUp">
                  Replace &amp; line up after #{cur.tripNo}
                </Button>
                <Button variant="contained" color="warning" disabled={busy} onClick={() => onAnswer({ replace: true, endDriverCurrent: true })} data-testid="qReplaceEnd">
                  End #{cur.tripNo} &amp; send
                </Button>
              </>
            ) : (
              <Button variant="contained" disabled={busy} onClick={() => onAnswer({ replace: true })} data-testid="qReplaceSend">
                Replace &amp; send now
              </Button>
            )}
          </DialogActions>
        </>
      )}
      {q?.needs === 'endPrevious' && prev && (
        <>
          <DialogTitle>End leg {prev.legNo} first?</DialogTitle>
          <DialogContent dividers>
            <Stack spacing={1.5}>
              <LegBox label={`Leg ${prev.legNo} · ${statusText(prev)}`} leg={prev} />
              <Typography variant="body2">
                {prev.driverName || 'The driver'} hasn&apos;t ended leg {prev.legNo} of load {loadNo}. End it now and send this leg to <b>{driverName}</b>?
              </Typography>
            </Stack>
          </DialogContent>
          <DialogActions>
            <Button onClick={onClose}>Cancel</Button>
            <Button variant="contained" color="warning" disabled={busy} onClick={() => onAnswer({ endPrevious: true })} data-testid="qEndPrevious">
              End leg {prev.legNo} &amp; send
            </Button>
          </DialogActions>
        </>
      )}
      {q?.needs === 'driverBusy' && cur && (
        <>
          <DialogTitle>{cur.driverName || driverName} is on another load</DialogTitle>
          <DialogContent dividers>
            <Stack spacing={1.5}>
              <LegBox label={`Current load · ${statusText(cur)}`} leg={cur} />
              <Typography variant="body2">
                End it now and send load <b>{loadNo}</b>, or line {loadNo} up to go out by itself when #{cur.tripNo} is delivered? Lined up, the driver doesn&apos;t see it
                yet.
              </Typography>
            </Stack>
          </DialogContent>
          <DialogActions>
            <Button onClick={onClose}>Cancel</Button>
            <Button variant="outlined" disabled={busy} onClick={() => onAnswer({ lineUp: true })} data-testid="qLineUp">
              Line up after #{cur.tripNo}
            </Button>
            <Button variant="contained" color="warning" disabled={busy} onClick={() => onAnswer({ endDriverCurrent: true })} data-testid="qEndCurrent">
              End #{cur.tripNo} &amp; send
            </Button>
          </DialogActions>
        </>
      )}
    </Dialog>
  );
}
