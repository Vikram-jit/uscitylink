'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Grid,
  IconButton,
  MenuItem,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import { ArrowDown, ArrowUp, Plus, Trash } from '@phosphor-icons/react';
import { toast } from 'react-toastify';

import { useCloseDriverTripMutation, useGetDriverTripQuery, useSaveDriverTripMutation } from '@/redux/AutomationApiSlice';
import type { DriverTrip, RoadClass } from '@/redux/models/AutomationModel';

export const ROAD_LABELS: Record<RoadClass, string> = {
  interstate: 'Interstate',
  state_highway: 'State highway',
  local: 'Local road',
};

const STATES =
  'AL AZ AR CA CO CT DE FL GA ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY DC'.split(
    ' ',
  );

const EMPTY: DriverTrip = { segments: [{ state: '', road_class: 'interstate' }], permits: [] };

// Dispatch enters the route a driver is on: every state and road type in order, and any permits.
// The scale agent checks tickets against the rules of every segment (lowest limit wins).
export function TripDialog({
  driverId,
  driverName,
  defaults,
  onClose,
}: {
  driverId: string;
  driverName?: string | null;
  defaults?: Partial<DriverTrip>;
  onClose: () => void;
}): React.JSX.Element {
  const { data, isLoading } = useGetDriverTripQuery({ driverId });
  const [save, { isLoading: saving }] = useSaveDriverTripMutation();
  const [closeTrip] = useCloseDriverTripMutation();
  const [trip, setTrip] = React.useState<DriverTrip | null>(null);

  React.useEffect(() => {
    if (isLoading || trip) return;
    const current = data?.data;
    setTrip(
      current
        ? { ...current, segments: current.segments?.length ? current.segments : EMPTY.segments, permits: current.permits || [] }
        : { ...EMPTY, ...defaults },
    );
  }, [data, isLoading, trip, defaults]);

  if (!trip) {
    return (
      <Dialog onClose={onClose} open>
        <DialogContent>
          <CircularProgress />
        </DialogContent>
      </Dialog>
    );
  }

  const set = (patch: Partial<DriverTrip>) => setTrip((t) => ({ ...(t as DriverTrip), ...patch }));
  const setSegment = (i: number, patch: Partial<DriverTrip['segments'][number]>) =>
    set({ segments: trip.segments.map((s, j) => (j === i ? { ...s, ...patch } : s)) });
  const moveSegment = (i: number, by: number) => {
    const list = [...trip.segments];
    const [item] = list.splice(i, 1);
    list.splice(i + by, 0, item);
    set({ segments: list });
  };
  const setPermit = (i: number, patch: Partial<DriverTrip['permits'][number]>) =>
    set({ permits: trip.permits.map((p, j) => (j === i ? { ...p, ...patch } : p)) });

  const submit = async () => {
    try {
      const res = await save({ driverId, ...trip }).unwrap();
      toast.success(res.message || 'Route saved');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save the route');
    }
  };

  return (
    <Dialog fullWidth maxWidth="md" onClose={onClose} open>
      <DialogTitle>Route for {driverName || 'driver'}</DialogTitle>
      <DialogContent>
        <Stack spacing={2.5} sx={{ mt: 1 }}>
          <Alert severity="info">
            List every state in driving order with the road type. Scale tickets are checked against the rules for each segment and
            the lowest limit applies. Open tickets for this driver are re-checked when you save.
          </Alert>
          <Grid container spacing={2}>
            {(
              [
                ['truck', 'Tractor #'],
                ['trailer', 'Trailer #'],
                ['origin', 'Origin'],
                ['destination', 'Destination'],
                ['cargo', 'Cargo / commodity'],
              ] as const
            ).map(([key, label]) => (
              <Grid item key={key} md={key === 'cargo' ? 4 : 2} sm={4} xs={6}>
                <TextField fullWidth label={label} onChange={(e) => set({ [key]: e.target.value })} size="small" value={trip[key] || ''} />
              </Grid>
            ))}
          </Grid>

          <Stack spacing={1}>
            <Typography variant="subtitle2">Route segments</Typography>
            {trip.segments.map((seg, i) => (
              <Stack alignItems="center" direction="row" key={i} spacing={1}>
                <Typography color="text.secondary" sx={{ width: 22 }} variant="body2">
                  {i + 1}.
                </Typography>
                <TextField label="State" onChange={(e) => setSegment(i, { state: e.target.value })} select size="small" sx={{ width: 110 }} value={seg.state}>
                  {STATES.map((s) => (
                    <MenuItem key={s} value={s}>
                      {s}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  label="Road type"
                  onChange={(e) => setSegment(i, { road_class: e.target.value as RoadClass })}
                  select
                  size="small"
                  sx={{ width: 170 }}
                  value={seg.road_class}
                >
                  {Object.entries(ROAD_LABELS).map(([k, v]) => (
                    <MenuItem key={k} value={k}>
                      {v}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  label="Note (e.g. I-10 west)"
                  onChange={(e) => setSegment(i, { note: e.target.value })}
                  size="small"
                  sx={{ flex: 1 }}
                  value={seg.note || ''}
                />
                <IconButton disabled={i === 0} onClick={() => moveSegment(i, -1)} size="small">
                  <ArrowUp />
                </IconButton>
                <IconButton disabled={i === trip.segments.length - 1} onClick={() => moveSegment(i, 1)} size="small">
                  <ArrowDown />
                </IconButton>
                <IconButton disabled={trip.segments.length === 1} onClick={() => set({ segments: trip.segments.filter((_, j) => j !== i) })} size="small">
                  <Trash />
                </IconButton>
              </Stack>
            ))}
            <Box>
              <Button onClick={() => set({ segments: [...trip.segments, { state: '', road_class: 'interstate' }] })} size="small" startIcon={<Plus />}>
                Add segment
              </Button>
            </Box>
          </Stack>

          <Divider />
          <Stack spacing={1}>
            <Typography variant="subtitle2">Permits</Typography>
            {trip.permits.length ? null : (
              <Typography color="text.secondary" variant="body2">
                No permits. A valid permit replaces the limits it lists for that state; an expired one is ignored.
              </Typography>
            )}
            {trip.permits.map((p, i) => (
              <Stack alignItems="center" direction="row" flexWrap="wrap" gap={1} key={i}>
                <TextField label="State" onChange={(e) => setPermit(i, { state: e.target.value })} select size="small" sx={{ width: 100 }} value={p.state}>
                  {STATES.map((s) => (
                    <MenuItem key={s} value={s}>
                      {s}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField label="Permit #" onChange={(e) => setPermit(i, { number: e.target.value })} size="small" sx={{ width: 140 }} value={p.number} />
                <TextField
                  InputLabelProps={{ shrink: true }}
                  label="Expires"
                  onChange={(e) => setPermit(i, { expires_at: e.target.value })}
                  size="small"
                  type="date"
                  value={p.expires_at}
                />
                {(
                  [
                    ['gross_lb', 'Gross (lb)'],
                    ['tandem_lb', 'Tandem (lb)'],
                    ['single_axle_lb', 'Single (lb)'],
                  ] as const
                ).map(([key, label]) => (
                  <TextField
                    key={key}
                    label={label}
                    onChange={(e) => setPermit(i, { [key]: e.target.value === '' ? null : Number(e.target.value) })}
                    size="small"
                    sx={{ width: 120 }}
                    type="number"
                    value={p[key] ?? ''}
                  />
                ))}
                <IconButton onClick={() => set({ permits: trip.permits.filter((_, j) => j !== i) })} size="small">
                  <Trash />
                </IconButton>
              </Stack>
            ))}
            <Box>
              <Button
                onClick={() => set({ permits: [...trip.permits, { state: '', number: '', expires_at: '', gross_lb: null }] })}
                size="small"
                startIcon={<Plus />}
              >
                Add permit
              </Button>
            </Box>
          </Stack>
        </Stack>
      </DialogContent>
      <DialogActions>
        {data?.data ? (
          <Button
            color="inherit"
            onClick={async () => {
              await closeTrip({ driverId });
              toast.success('Trip closed');
              onClose();
            }}
            sx={{ mr: 'auto' }}
          >
            Close trip
          </Button>
        ) : null}
        <Button onClick={onClose}>Cancel</Button>
        <Button disabled={saving} onClick={() => void submit()} variant="contained">
          Save route
        </Button>
      </DialogActions>
    </Dialog>
  );
}
