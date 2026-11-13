'use client';

import * as React from 'react';
import { Alert, Box, Button, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, Stack, Typography } from '@mui/material';
import { toast } from 'react-toastify';

import { MessageLoad, useDeleteLoadOfMessageMutation, useLazyGetLoadsOfMessageQuery } from '@/redux/TripApiSlice';

import { STATUS } from './tripFormat';

// Deleting a chat message that made a load (the load message, or a load typed in the chat): the load
// isn't left behind by accident — dispatch chooses: delete the load too, keep it, or cancel.
// A message with no load is deleted straight away, as before.

type Props = {
  /** The message to delete; null = closed */
  messageId: string | null;
  onClose: () => void;
  /** Deletes the chat message itself (the socket "delete_message") */
  deleteMessage: (messageId: string) => void;
};

export function DeleteMessageDialog({ messageId, onClose, deleteMessage }: Props): React.JSX.Element | null {
  const [check, { isFetching }] = useLazyGetLoadsOfMessageQuery();
  const [removeLoad, { isLoading }] = useDeleteLoadOfMessageMutation();
  const [loads, setLoads] = React.useState<MessageLoad[] | null>(null);

  React.useEffect(() => {
    if (!messageId) {
      setLoads(null);
      return;
    }
    let live = true;
    check(messageId)
      .unwrap()
      .then((r) => {
        if (!live) return;
        const found = r.data || [];
        if (!found.length) {
          deleteMessage(messageId);
          onClose();
        } else setLoads(found);
      })
      .catch(() => {
        // Can't tell (offline / older server): ask plainly rather than lose a load silently
        if (live) setLoads([]);
      });
    return () => {
      live = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [messageId]);

  if (!messageId) return null;
  const deletable = (loads || []).filter((l) => l.canDelete);

  const messageOnly = () => {
    deleteMessage(messageId);
    onClose();
  };
  const withLoad = async () => {
    try {
      for (const l of deletable) await removeLoad({ messageId, legId: l.legId }).unwrap();
      deleteMessage(messageId);
      toast.success(deletable.length === 1 ? `${deletable[0].onlyLeg ? 'Load' : `Leg ${deletable[0].legNo} of load`} ${deletable[0].loadNo || ''} deleted with the message` : 'Loads deleted with the message');
      onClose();
    } catch (e: any) {
      toast.error(e?.data?.message || 'Could not delete the load');
    }
  };

  return (
    <Dialog open onClose={onClose} maxWidth="xs" fullWidth data-testid="deleteMessageDialog">
      <DialogTitle>{loads && loads.length ? 'This message made a load' : 'Delete message?'}</DialogTitle>
      <DialogContent>
        {loads === null || isFetching ? (
          <Box sx={{ py: 3, display: 'flex', justifyContent: 'center' }}>
            <CircularProgress size={24} />
          </Box>
        ) : loads.length === 0 ? (
          <Typography variant="body2">Couldn't check for a load on this message. Delete the message only?</Typography>
        ) : (
          <Stack spacing={1.5}>
            {loads.map((l) => (
              <Box key={l.legId} sx={{ p: 1.5, borderRadius: 2, border: 1, borderColor: 'divider', bgcolor: 'action.hover' }}>
                <Typography variant="body2" fontWeight={700}>
                  Load {l.loadNo || `#${l.tripNo}`}
                  {l.onlyLeg ? '' : ` · leg ${l.legNo}`}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {l.driverName || 'No driver'} · {STATUS[l.status as keyof typeof STATUS]?.label || l.status}
                </Typography>
                {!l.canDelete && (
                  <Typography variant="caption" color="warning.main">
                    {l.why}
                  </Typography>
                )}
              </Box>
            ))}
            {deletable.length > 0 && (
              <Alert severity="warning">
                Delete the {deletable.some((l) => !l.onlyLeg) ? 'leg' : 'load'} too? It's removed from Loads and from the driver's app, with its history. This can't be undone.
              </Alert>
            )}
          </Stack>
        )}
      </DialogContent>
      <DialogActions sx={{ flexWrap: 'wrap', gap: 1 }}>
        <Button onClick={onClose}>Cancel</Button>
        {loads !== null && (
          <Button onClick={messageOnly} data-testid="deleteMessageOnly">
            {loads.length ? 'Delete message only' : 'Delete message'}
          </Button>
        )}
        {deletable.length > 0 && (
          <Button variant="contained" color="error" onClick={withLoad} disabled={isLoading} data-testid="deleteMessageAndLoad">
            {deletable.some((l) => !l.onlyLeg) ? 'Delete message & leg' : 'Delete message & load'}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
}
