'use client';

import * as React from 'react';
import { Alert, Box, Button, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, Stack, TextField, Typography } from '@mui/material';
import { toast } from 'react-toastify';

import { RepairPreview, useApplyRepairMutation, useLazyGetRepairPreviewQuery } from '@/redux/TripApiSlice';

import { loadNoIn } from './loadText';

// Add to loads / Repair on a chat message. The server re-reads the message with today's rules and says
// what it would do; nothing changes until dispatch confirms here.
//   add:    the message never became a load → it is ADDED to Loads (lined up). Nothing is sent to the
//           driver. A text with no address becomes a plan (stops added later).
//   repair: a load exists but differs from the message (e.g. the one address was guessed as a pickup) →
//           shows before → after, then fixes the load and replaces the assistant's old message text.
//   ok:     the load already matches.

const Row = ({ label, before, after }: { label: string; before: string; after: string }) => (
  <Stack direction="row" spacing={1} alignItems="baseline" sx={{ flexWrap: 'wrap' }}>
    <Typography variant="body2" fontWeight={700} sx={{ minWidth: 96 }}>
      {label}
    </Typography>
    <Typography variant="body2" color="text.secondary" sx={{ textDecoration: 'line-through' }}>
      {before}
    </Typography>
    <Typography variant="body2">→</Typography>
    <Typography variant="body2" fontWeight={700} color="success.main">
      {after}
    </Typography>
  </Stack>
);

const Text = ({ children, dim }: { children: string; dim?: boolean }) => (
  <Typography
    variant="body2"
    sx={{ whiteSpace: 'pre-line', maxHeight: 130, overflow: 'auto', p: 1, bgcolor: 'action.hover', borderRadius: 1, color: dim ? 'text.secondary' : 'text.primary', fontFamily: 'monospace', fontSize: 12 }}
  >
    {children}
  </Typography>
);

export function RepairLoadDialog({ messageId, onClose, onDone }: { messageId: string | null; onClose: () => void; onDone?: () => void }): React.JSX.Element | null {
  const [load, { data, isFetching, isError }] = useLazyGetRepairPreviewQuery();
  const [apply, { isLoading: applying }] = useApplyRepairMutation();
  const [loadNo, setLoadNo] = React.useState('');
  const pv: RepairPreview | null = data?.data && data.data.messageId === messageId ? data.data : null;

  React.useEffect(() => {
    if (messageId) void load(messageId, false);
  }, [messageId, load]);
  React.useEffect(() => {
    if (pv?.mode === 'add') setLoadNo(pv.loadNo || loadNoIn(pv.text) || '');
  }, [pv?.messageId, pv?.mode, pv?.loadNo, pv?.text]);

  if (!messageId) return null;

  const go = async () => {
    try {
      const res = await apply({ messageId, loadNo: loadNo.trim() || null }).unwrap();
      toast.success(res.message || 'Done');
      onDone?.();
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not do that', { autoClose: 10000 });
    }
  };

  const title = !pv ? 'Add to loads / Repair' : pv.mode === 'add' ? 'Add this message to Loads' : pv.mode === 'repair' ? 'Repair this load' : 'Nothing to repair';
  const label = pv?.mode === 'add' ? 'Add to loads' : 'Replace & update';

  return (
    <Dialog open onClose={onClose} maxWidth="sm" fullWidth data-testid="repairLoadDialog">
      <DialogTitle>{title}</DialogTitle>
      <DialogContent>
        {isError ? (
          <Alert severity="error">Could not read this message.</Alert>
        ) : !pv || isFetching ? (
          <Box sx={{ py: 3, display: 'flex', justifyContent: 'center' }}>
            <CircularProgress size={24} />
          </Box>
        ) : pv.mode === 'add' ? (
          <Stack spacing={2} sx={{ pt: 0.5 }}>
            <Text dim>{pv.text}</Text>
            <TextField
              label="Load #"
              size="small"
              value={loadNo}
              onChange={(e) => setLoadNo(e.target.value)}
              required
              error={!loadNo.trim()}
              helperText={loadNo.trim() ? ' ' : 'No Load # in the message — type it'}
              inputProps={{ 'data-testid': 'repairLoadNo' }}
            />
            {pv.plan && (
              <Alert severity="warning" sx={{ py: 0.25 }}>
                No address found in this message — it is added as a <b>plan</b> (Load # only). Add the stops from Loads before sending it.
              </Alert>
            )}
            <Alert severity="info" sx={{ py: 0.25 }}>
              Added to Loads as <b>saved for later</b> — <b>nothing is sent</b> to the driver. A single address with no pickup / drop label is the <b>drop</b>.
            </Alert>
          </Stack>
        ) : pv.mode === 'ok' ? (
          <Alert severity="success">Load {pv.load?.loadNo} already matches this message.</Alert>
        ) : (
          <Stack spacing={2} sx={{ pt: 0.5 }}>
            <Typography variant="body2" fontWeight={700}>
              Load {pv.load?.loadNo}
              {pv.load && !pv.load.onlyLeg ? ` · leg ${pv.load.legNo}` : ''} · {pv.load?.driverName || 'No driver'}
            </Typography>
            {pv.changes.length > 0 && (
              <Stack spacing={0.75} data-testid="repairChanges">
                <Typography variant="caption" color="text.secondary">
                  LOAD DETAILS THAT WILL CHANGE
                </Typography>
                {pv.changes.map((c) => (
                  <Row key={c.label} {...c} />
                ))}
              </Stack>
            )}
            {pv.message && (
              <Stack spacing={0.75} data-testid="repairMessage">
                <Typography variant="caption" color="text.secondary">
                  THE ASSISTANT&apos;S MESSAGE IN THE CHAT WILL BE REPLACED
                </Typography>
                <Text dim>{pv.message.before}</Text>
                <Typography variant="caption">↓</Typography>
                <Text>{pv.message.after}</Text>
              </Stack>
            )}
            {!pv.canApply && pv.why && <Alert severity="warning">{pv.why}</Alert>}
            <Alert severity="info" sx={{ py: 0.25 }}>
              Dispatch&apos;s own typed text is never rewritten. The driver sees the new message text when their chat reloads.
            </Alert>
          </Stack>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>{pv?.mode === 'ok' ? 'Close' : 'Cancel'}</Button>
        {pv && pv.mode !== 'ok' && (
          <Button variant="contained" onClick={go} disabled={applying || !pv.canApply || (pv.mode === 'add' && !loadNo.trim())} data-testid="repairSubmit">
            {label}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
}
