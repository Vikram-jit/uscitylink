'use client';

import * as React from 'react';
import { Alert, Button, Dialog, DialogActions, DialogContent, DialogTitle, Grid, Stack, TextField, Typography } from '@mui/material';
import { toast } from 'react-toastify';

import { Trip, useCorrectLegTimesMutation, useSetLegMilesMutation } from '@/redux/TripApiSlice';

import { STOP_LABEL } from './tripFormat';

// Fix the times of a leg (the driver tapped late, forgot, or came back online later) and its miles.
// Every change needs a reason and is kept with the old value; changing start / end re-reads the miles
// from Samsara unless they were typed.

const toLocalInput = (iso?: string | null) => {
  if (!iso) return '';
  const d = new Date(iso);
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
};
const toIso = (v: string) => (v ? new Date(v).toISOString() : null);

export function CorrectTimesDialog({ open, onClose, loadId, leg }: { open: boolean; onClose: () => void; loadId: number; leg: Trip | null }): React.JSX.Element {
  const stops = [...(leg?.stops || [])].sort((a, b) => a.seq - b.seq);
  const [started, setStarted] = React.useState('');
  const [ended, setEnded] = React.useState('');
  const [stopTimes, setStopTimes] = React.useState<Record<number, { arrived: string; departed: string }>>({});
  const [reason, setReason] = React.useState('');
  const [correct, { isLoading }] = useCorrectLegTimesMutation();

  React.useEffect(() => {
    if (!open || !leg) return;
    setStarted(toLocalInput(leg.started_at));
    setEnded(toLocalInput(leg.ended_at));
    setStopTimes(Object.fromEntries((leg.stops || []).map((s) => [s.id, { arrived: toLocalInput(s.arrived_at), departed: toLocalInput(s.departed_at) }])));
    setReason('');
    // once per opening
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, leg?.id]);

  const save = async () => {
    if (!leg) return;
    if (!reason.trim()) return toast.error('Say why the times are changed');
    const body: any = { id: loadId, legId: leg.id, reason: reason.trim() };
    if (started !== toLocalInput(leg.started_at)) body.startedAt = toIso(started);
    if (ended !== toLocalInput(leg.ended_at)) body.endedAt = toIso(ended);
    const changedStops = stops
      .map((s) => {
        const v = stopTimes[s.id] || { arrived: '', departed: '' };
        const c: any = { id: s.id };
        if (v.arrived !== toLocalInput(s.arrived_at)) c.arrivedAt = toIso(v.arrived);
        if (v.departed !== toLocalInput(s.departed_at)) c.departedAt = toIso(v.departed);
        return Object.keys(c).length > 1 ? c : null;
      })
      .filter(Boolean);
    if (changedStops.length) body.stops = changedStops;
    if (Object.keys(body).length === 3) return toast.info('Nothing changed');
    try {
      const res = await correct(body).unwrap();
      toast.success(res.message || 'Times corrected');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not correct the times');
    }
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm" onClick={(e) => e.stopPropagation()}>
      <DialogTitle>Correct times · #{leg?.trip_no}</DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2}>
          <Typography variant="caption" color="text.secondary">
            Times are in your computer&apos;s time zone. Changing start / end re-reads the Samsara miles for this leg.
          </Typography>
          <Grid container spacing={1.5}>
            <Grid item xs={6}>
              <TextField size="small" fullWidth type="datetime-local" label="Started (rolling)" InputLabelProps={{ shrink: true }} value={started} onChange={(e) => setStarted(e.target.value)} />
            </Grid>
            <Grid item xs={6}>
              <TextField size="small" fullWidth type="datetime-local" label="Ended (delivered / handed over)" InputLabelProps={{ shrink: true }} value={ended} onChange={(e) => setEnded(e.target.value)} />
            </Grid>
          </Grid>
          {stops.map((s) => (
            <Grid container spacing={1.5} key={s.id} alignItems="center">
              <Grid item xs={12} sm={4}>
                <Typography variant="body2" fontWeight={600} noWrap>
                  {STOP_LABEL[s.type]} · {s.name || s.city}
                </Typography>
              </Grid>
              <Grid item xs={6} sm={4}>
                <TextField
                  size="small"
                  fullWidth
                  type="datetime-local"
                  label="Arrived"
                  InputLabelProps={{ shrink: true }}
                  value={stopTimes[s.id]?.arrived || ''}
                  onChange={(e) => setStopTimes((all) => ({ ...all, [s.id]: { ...all[s.id], arrived: e.target.value } }))}
                />
              </Grid>
              <Grid item xs={6} sm={4}>
                <TextField
                  size="small"
                  fullWidth
                  type="datetime-local"
                  label="Left"
                  InputLabelProps={{ shrink: true }}
                  value={stopTimes[s.id]?.departed || ''}
                  onChange={(e) => setStopTimes((all) => ({ ...all, [s.id]: { ...all[s.id], departed: e.target.value } }))}
                />
              </Grid>
            </Grid>
          ))}
          <TextField size="small" required label="Why (kept on the record)" placeholder="Driver tapped Delivered late" value={reason} onChange={(e) => setReason(e.target.value)} />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button variant="contained" disabled={isLoading} onClick={() => void save()} data-testid="timesSave">
          Save times
        </Button>
      </DialogActions>
    </Dialog>
  );
}

/** Type the miles of a leg (Samsara missing / wrong), or go back to Samsara. */
export function MilesDialog({ open, onClose, loadId, leg }: { open: boolean; onClose: () => void; loadId: number; leg: Trip | null }): React.JSX.Element {
  const [miles, setMiles] = React.useState('');
  const [note, setNote] = React.useState('');
  const [save, { isLoading }] = useSetLegMilesMutation();
  React.useEffect(() => {
    if (!open || !leg) return;
    setMiles(leg.total_mileage ? String(Number(leg.total_mileage)) : '');
    setNote(leg.miles_note || '');
  }, [open, leg]);
  const submit = async (back: boolean) => {
    if (!leg) return;
    try {
      const res = await save({ id: loadId, legId: leg.id, miles: back ? null : Number(miles), note: back ? null : note.trim() }).unwrap();
      toast.success(res.message || 'Miles saved');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save the miles');
    }
  };
  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth onClick={(e) => e.stopPropagation()}>
      <DialogTitle>Miles · #{leg?.trip_no}</DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2}>
          <Alert severity="info" icon={false}>
            Now: <b>{leg?.total_mileage ? `${Number(leg.total_mileage)} mi` : 'none'}</b> {leg?.miles_source === 'manual' ? '(typed)' : leg?.total_mileage ? '(Samsara)' : ''}
          </Alert>
          <TextField size="small" type="number" label="Miles" value={miles} onChange={(e) => setMiles(e.target.value)} inputProps={{ min: 0, step: 0.1 }} />
          <TextField size="small" label="Why (kept on the record)" placeholder="Samsara offline — odometer photo" value={note} onChange={(e) => setNote(e.target.value)} />
        </Stack>
      </DialogContent>
      <DialogActions>
        {leg?.miles_source === 'manual' && <Button onClick={() => void submit(true)}>Use Samsara again</Button>}
        <Button onClick={onClose}>Cancel</Button>
        <Button variant="contained" disabled={isLoading || miles === '' || !note.trim()} onClick={() => void submit(false)}>
          Save miles
        </Button>
      </DialogActions>
    </Dialog>
  );
}
