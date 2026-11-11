'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Button,
  Checkbox,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  MenuItem,
  Paper,
  Stack,
  TextField,
  ToggleButton,
  ToggleButtonGroup,
  Typography,
} from '@mui/material';
import { GpsFixed, LocalParking, Search } from '@mui/icons-material';
import { toast } from 'react-toastify';

import { HandoverPlace, Trip, useLazyGetLegTruckPlaceQuery, useLazyGetYardStopQuery, useSplitLoadLegMutation } from '@/redux/TripApiSlice';

import { AddressSearch } from './AddressSearch';
import { legBody, LegEditor, LegState, newLeg } from './LegEditor';
import { STOP_LABEL } from './tripFormat';

// Hand a load to another driver and / or truck: on the road (breakdown, out of hours, swap at the
// yard) the leg ends where it is and a new leg takes the rest of the stops; before it starts, the
// leg is split after a stop. Same driver on a new truck, or a new driver on the same truck, work too.

export const HANDOVER_REASONS: Record<string, string> = {
  breakdown: 'Breakdown',
  out_of_hours: 'Out of hours',
  swap_at_yard: 'Swap at the yard',
  driver_request: 'Driver request',
  planned: 'Planned relay',
  other: 'Other',
};

const ON_ROAD = ['started', 'rolling', 'on_hold'];
const toLocalInput = (d: Date) => new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);

interface Props {
  open: boolean;
  onClose: () => void;
  loadId: number;
  leg: Trip | null;
  driverName?: string | null;
}

export function HandoverDialog({ open, onClose, loadId, leg, driverName }: Props): React.JSX.Element {
  const onRoad = !!leg && ON_ROAD.includes(leg.status) && !!leg.started_at;
  const stops = [...(leg?.stops || [])].sort((a, b) => a.seq - b.seq);
  const [when, setWhen] = React.useState<'now' | 'at' | 'plan'>('now');
  const [at, setAt] = React.useState('');
  const [afterSeq, setAfterSeq] = React.useState<number | ''>('');
  const [place, setPlace] = React.useState<HandoverPlace | null>(null);
  const [placeFrom, setPlaceFrom] = React.useState<'truck' | 'yard' | 'search' | null>(null);
  const [people, setPeople] = React.useState<LegState>(newLeg([]));
  const [reason, setReason] = React.useState('breakdown');
  const [note, setNote] = React.useState('');
  const [send, setSend] = React.useState(true);
  const [truckPlace, { isFetching: locating }] = useLazyGetLegTruckPlaceQuery();
  const [yardStop] = useLazyGetYardStopQuery();
  const [split, { isLoading }] = useSplitLoadLegMutation();

  React.useEffect(() => {
    if (!open || !leg) return;
    setWhen(onRoad ? 'now' : 'plan');
    setAt(toLocalInput(new Date()));
    const lastPickup = [...stops].reverse().find((s) => s.type === 'pickup');
    setAfterSeq(onRoad ? '' : lastPickup?.seq ?? stops[0]?.seq ?? '');
    setPlace(null);
    setPlaceFrom(null);
    setPeople(newLeg([], { trailers: leg.trailer_numbers ? leg.trailer_numbers.split(/,\s*/).filter(Boolean) : [], loaded: true }));
    setReason(onRoad ? 'breakdown' : 'planned');
    setNote('');
    setSend(true);
    // once per opening
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, leg?.id]);

  const useTruck = async () => {
    if (!leg) return;
    setPlaceFrom('truck');
    try {
      const p = (await truckPlace(leg.id).unwrap()).data;
      if (!p?.city) {
        toast.warning("Couldn't read where the truck is — pick the place another way");
        setPlaceFrom('search');
        return;
      }
      setPlace({ type: 'switch', name: p.name || p.address || null, street: p.street, city: p.city, state: p.state, zip: p.zip });
    } catch (err: any) {
      toast.error(err?.data?.message || 'Truck location not available');
      setPlaceFrom('search');
    }
  };
  const useYard = async () => {
    setPlaceFrom('yard');
    try {
      const y = (await yardStop().unwrap()).data;
      setPlace({ ...y, type: 'yard' });
    } catch {
      toast.error('No yard address yet — search it once');
      setPlaceFrom('search');
    }
  };

  // What the new leg will take
  // Rolling = loaded: pickups and where this leg took the load over are behind the truck (same rule as the server)
  const originDone = (s: (typeof stops)[number]) =>
    leg?.status === 'rolling' && (s.type === 'pickup' || (s.id === stops[0]?.id && (s.type === 'yard' || s.type === 'switch')));
  const moving = onRoad && when !== 'plan' ? stops.filter((s) => !s.arrived_at && !originDone(s)) : stops.filter((s) => afterSeq !== '' && s.seq > Number(afterSeq));
  const sameDriver = () => leg?.driver_profile_id && setPeople((p) => ({ ...p, driver: { id: leg.driver_profile_id!, name: driverName || 'Same driver' } }));
  const sameTruck = () => leg?.truck_number && setPeople((p) => ({ ...p, truck: leg.truck_number! }));

  const save = async () => {
    if (!leg) return;
    if (!place?.city || !place?.state) return toast.error('Where does the load change hands?');
    if (!moving.length) return toast.error('No stops left for the next driver');
    const body = legBody(people);
    try {
      const res = await split({
        id: loadId,
        legId: leg.id,
        when: onRoad ? when : 'plan',
        at: onRoad && when === 'at' ? new Date(at).toISOString() : null,
        afterSeq: !onRoad || when === 'plan' ? Number(afterSeq) : null,
        place,
        driverProfileId: body.driverProfileId,
        truckNumber: body.truckNumber,
        teamDriverProfileId: body.teamDriverProfileId,
        trailerNumbers: body.trailerNumbers,
        reason,
        note: note.trim() || null,
        send: onRoad && send,
      }).unwrap();
      toast.success(res.message || 'Load handed over');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not hand it over');
    }
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md" onClick={(e) => e.stopPropagation()}>
      <DialogTitle>Change driver / truck · #{leg?.trip_no}</DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2.5}>
          {/* When */}
          <Box>
            <Typography variant="overline" color="text.secondary">
              When
            </Typography>
            {onRoad ? (
              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} alignItems={{ sm: 'center' }}>
                <ToggleButtonGroup exclusive size="small" value={when} onChange={(_, v) => v && setWhen(v)}>
                  <ToggleButton value="now">Now</ToggleButton>
                  <ToggleButton value="at">It happened at…</ToggleButton>
                  <ToggleButton value="plan">Later, after a stop</ToggleButton>
                </ToggleButtonGroup>
                {when === 'at' && (
                  <TextField size="small" type="datetime-local" value={at} onChange={(e) => setAt(e.target.value)} inputProps={{ max: toLocalInput(new Date()) }} />
                )}
              </Stack>
            ) : (
              <Typography variant="body2" color="text.secondary">
                This leg hasn&apos;t started — it&apos;s split into two legs.
              </Typography>
            )}
            {(!onRoad || when === 'plan') && (
              <TextField select size="small" label="Changes hands after" value={afterSeq} onChange={(e) => setAfterSeq(Number(e.target.value))} sx={{ mt: 1.5, minWidth: 320 }}>
                {stops.slice(0, -1).map((s) => (
                  <MenuItem key={s.id} value={s.seq}>
                    {STOP_LABEL[s.type]} · {s.name || s.city} {s.arrived_at ? '(done)' : ''}
                  </MenuItem>
                ))}
              </TextField>
            )}
          </Box>

          {/* Where */}
          <Box>
            <Typography variant="overline" color="text.secondary">
              Where
            </Typography>
            <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
              {onRoad && (
                <Button size="small" variant={placeFrom === 'truck' ? 'contained' : 'outlined'} startIcon={locating ? <CircularProgress size={14} /> : <GpsFixed />} onClick={() => void useTruck()}>
                  Where the truck is now
                </Button>
              )}
              <Button size="small" variant={placeFrom === 'yard' ? 'contained' : 'outlined'} startIcon={<LocalParking />} onClick={() => void useYard()}>
                Our yard
              </Button>
              <Button size="small" variant={placeFrom === 'search' ? 'contained' : 'outlined'} startIcon={<Search />} onClick={() => setPlaceFrom('search')}>
                Another place
              </Button>
            </Stack>
            {placeFrom === 'search' && (
              <Box sx={{ mt: 1.5 }}>
                <AddressSearch onPick={(p) => setPlace({ type: 'switch', name: p.name || null, street: p.street, city: p.city, state: p.state, zip: p.zip })} />
              </Box>
            )}
            {place?.city && (
              <Paper variant="outlined" sx={{ mt: 1.5, p: 1.25 }} data-testid="handoverPlace">
                <Stack direction="row" spacing={1} alignItems="center">
                  <Chip size="small" color="warning" label={place.type === 'yard' ? 'Our yard' : 'Meet point'} />
                  <Typography variant="body2" fontWeight={600} sx={{ flexGrow: 1 }}>
                    {[place.name, place.street, [place.city, place.state].filter(Boolean).join(', ')].filter(Boolean).join(' · ')}
                  </Typography>
                </Stack>
              </Paper>
            )}
          </Box>

          {/* Who */}
          <Box>
            <Stack direction="row" alignItems="center" spacing={1}>
              <Typography variant="overline" color="text.secondary" sx={{ flexGrow: 1 }}>
                Who takes it from there
              </Typography>
              {leg?.driver_profile_id && (
                <Button size="small" onClick={sameDriver}>
                  Same driver (new truck)
                </Button>
              )}
              {leg?.truck_number && (
                <Button size="small" onClick={sameTruck}>
                  Same truck (new driver)
                </Button>
              )}
            </Stack>
            <LegEditor leg={people} onChange={(p) => setPeople((s) => ({ ...s, ...p }))} assignLater loadId={loadId} peopleOnly />
          </Box>

          {/* Why */}
          <Box>
            <Typography variant="overline" color="text.secondary">
              Why
            </Typography>
            <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
              {Object.entries(HANDOVER_REASONS).map(([k, label]) => (
                <Chip key={k} label={label} color={reason === k ? 'primary' : 'default'} variant={reason === k ? 'filled' : 'outlined'} onClick={() => setReason(k)} />
              ))}
            </Stack>
            <TextField size="small" fullWidth label="Note (optional)" value={note} onChange={(e) => setNote(e.target.value)} sx={{ mt: 1.5 }} />
          </Box>

          <Alert severity={moving.length ? 'info' : 'warning'} data-testid="handoverSummary">
            {moving.length ? (
              <>
                {onRoad && when !== 'plan' ? `Leg ${leg?.leg_no} ends ${when === 'now' ? 'now' : 'at that time'}` : `Leg ${leg?.leg_no} keeps the stops before`}
                {place?.city ? ` at ${place.city}, ${place.state}` : ''}. The new leg takes {moving.length} stop{moving.length > 1 ? 's' : ''}:{' '}
                {moving.map((s) => `${STOP_LABEL[s.type]} ${s.name || s.city}`).join(', ')}.
              </>
            ) : (
              'Every stop is done — nothing left to hand over.'
            )}
          </Alert>
          {onRoad && when !== 'plan' && (
            <FormControlLabel control={<Checkbox checked={send} onChange={(e) => setSend(e.target.checked)} />} label="Send the rest of the load to the new driver now (otherwise it waits for you to confirm)" />
          )}
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button variant="contained" disabled={isLoading || !moving.length} onClick={() => void save()} data-testid="handoverSave">
          Hand over
        </Button>
      </DialogActions>
    </Dialog>
  );
}
