'use client';

import * as React from 'react';
import { Alert, Button, Dialog, DialogActions, DialogContent, DialogTitle, Stack, TextField, Typography } from '@mui/material';
import { toast } from 'react-toastify';

import { useEndLoadLegMutation, useReleaseLoadLegMutation } from '@/redux/TripApiSlice';

// The load already changed hands but the driver before didn't tap it: dispatch marks the handover
// (time, default now) and the next leg goes to its driver — it becomes their active trip.

const toLocalInput = (d: Date) => new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);

export interface ReleaseTarget {
  loadId: number;
  legId: number;
  tripNo: string | null;
  driverName: string;
  prevLegNo: number;
  prevTripNo: string | null;
  prevDriver: string;
  place: string;
}

export function ReleaseLegDialog({ target, onClose }: { target: ReleaseTarget | null; onClose: () => void }): React.JSX.Element {
  const [at, setAt] = React.useState('');
  const [release, { isLoading }] = useReleaseLoadLegMutation();
  React.useEffect(() => {
    if (target) setAt(toLocalInput(new Date()));
  }, [target]);

  const save = async () => {
    if (!target) return;
    try {
      const res = await release({ id: target.loadId, legId: target.legId, at: at ? new Date(at).toISOString() : null }).unwrap();
      toast.success(res.message || 'Sent');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not send it');
    }
  };

  return (
    <Dialog open={!!target} onClose={onClose} maxWidth="sm" fullWidth onClick={(e) => e.stopPropagation()}>
      <DialogTitle>Send #{target?.tripNo} to {target?.driverName} now?</DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2}>
          <Alert severity="info" icon={false}>
            Leg {target?.prevLegNo} (#{target?.prevTripNo}, {target?.prevDriver}) is marked <b>handed over</b>
            {target?.place ? ` at ${target.place}` : ''}, and {target?.driverName} gets the full load in chat — it becomes their active trip with the Got it / Rolling / Delivered
            buttons.
          </Alert>
          <TextField
            size="small"
            type="datetime-local"
            label="Handed over at"
            InputLabelProps={{ shrink: true }}
            value={at}
            onChange={(e) => setAt(e.target.value)}
            inputProps={{ max: toLocalInput(new Date()) }}
            sx={{ maxWidth: 280 }}
          />
          <Typography variant="caption" color="text.secondary">
            {target?.prevDriver} is told the load was handed over. The time decides the miles split between the two trucks.
          </Typography>
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button variant="contained" disabled={isLoading} onClick={() => void save()} data-testid="releaseSave">
          Handed over — send to {target?.driverName}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

/** Dispatch ends a load the driver didn't end (forgot, no signal, swapped out): time, default now. */
export function EndLegDialog({
  loadId,
  leg,
  driverName,
  onClose,
}: {
  loadId: number;
  leg: { id: number; trip_no: string | null } | null;
  driverName?: string | null;
  onClose: () => void;
}): React.JSX.Element {
  const [at, setAt] = React.useState('');
  const [end, { isLoading }] = useEndLoadLegMutation();
  React.useEffect(() => {
    if (leg) setAt(toLocalInput(new Date()));
  }, [leg]);
  const save = async () => {
    if (!leg) return;
    try {
      const res = await end({ id: loadId, legId: leg.id, at: at ? new Date(at).toISOString() : null }).unwrap();
      toast.success(res.message || 'Load ended');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not end it');
    }
  };
  return (
    <Dialog open={!!leg} onClose={onClose} maxWidth="xs" fullWidth onClick={(e) => e.stopPropagation()}>
      <DialogTitle>End #{leg?.trip_no}?</DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2}>
          <Typography variant="body2">
            Marks the load delivered at this time. {driverName || 'The driver'} is told and it leaves their app; miles are counted up to then.
          </Typography>
          <TextField
            size="small"
            type="datetime-local"
            label="Ended at"
            InputLabelProps={{ shrink: true }}
            value={at}
            onChange={(e) => setAt(e.target.value)}
            inputProps={{ max: toLocalInput(new Date()) }}
          />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button variant="contained" color="warning" disabled={isLoading} onClick={() => void save()} data-testid="endSave">
          End load
        </Button>
      </DialogActions>
    </Dialog>
  );
}
