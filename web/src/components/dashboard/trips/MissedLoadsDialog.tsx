'use client';

import * as React from 'react';
import { Alert, Box, Button, Chip, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, Stack, Typography } from '@mui/material';

import { useGetMissedLoadsQuery } from '@/redux/TripApiSlice';

import { RepairLoadDialog } from './RepairLoadDialog';

// "Missed loads": chat messages from the last 14 days that look like loads but are not in Loads
// (Add), and loads made from a chat message that don't match it (Repair — e.g. the one address was
// guessed as a pickup, or the assistant's old "TRIP #…" message). Each opens the same confirm dialog
// as the button on the message.

const when = (iso: string) => new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }).format(new Date(iso));

export function MissedLoadsDialog({ open, onClose }: { open: boolean; onClose: () => void }): React.JSX.Element | null {
  const { data, isFetching, refetch } = useGetMissedLoadsQuery(14, { skip: !open });
  const [target, setTarget] = React.useState<string | null>(null);
  if (!open) return null;
  const list = data?.data || [];

  return (
    <>
      <Dialog open onClose={onClose} maxWidth="sm" fullWidth data-testid="missedLoadsDialog">
        <DialogTitle>Missed loads</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
            Load messages from the last 14 days that are not in Loads, or are there with the wrong details. Nothing is sent to the driver.
          </Typography>
          {isFetching && !list.length ? (
            <Box sx={{ py: 3, display: 'flex', justifyContent: 'center' }}>
              <CircularProgress size={24} />
            </Box>
          ) : !list.length ? (
            <Alert severity="success">Nothing missed — every load message is in Loads.</Alert>
          ) : (
            <Stack spacing={1.25}>
              {list.map((l) => (
                <Box key={`${l.kind}-${l.messageId}`} sx={{ p: 1.25, border: 1, borderColor: 'divider', borderRadius: 2 }} data-testid="missedLoadRow">
                  <Stack direction="row" spacing={1} alignItems="center" sx={{ flexWrap: 'wrap' }}>
                    <Chip size="small" color={l.kind === 'missing' ? 'warning' : 'info'} label={l.kind === 'missing' ? 'Not in Loads' : 'Fix details'} />
                    <Typography variant="body2" fontWeight={700}>
                      {l.loadNo ? `Load ${l.loadNo}` : 'No Load # in the text'}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {l.driverName || 'Driver'} · {when(l.at)}
                    </Typography>
                    <Box sx={{ flexGrow: 1 }} />
                    <Button size="small" variant="outlined" onClick={() => setTarget(l.messageId)}>
                      {l.kind === 'missing' ? 'Add to loads' : 'Repair'}
                    </Button>
                  </Stack>
                  {l.kind === 'missing' ? (
                    <Typography variant="caption" color="text.secondary" noWrap sx={{ display: 'block', mt: 0.5 }}>
                      {l.firstLine}
                    </Typography>
                  ) : (
                    l.changes.map((c) => (
                      <Typography key={c} variant="caption" color="text.secondary" sx={{ display: 'block', mt: 0.25 }}>
                        {c}
                      </Typography>
                    ))
                  )}
                </Box>
              ))}
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => void refetch()}>Refresh</Button>
          <Button onClick={onClose}>Close</Button>
        </DialogActions>
      </Dialog>
      <RepairLoadDialog messageId={target} onClose={() => setTarget(null)} onDone={() => void refetch()} />
    </>
  );
}
