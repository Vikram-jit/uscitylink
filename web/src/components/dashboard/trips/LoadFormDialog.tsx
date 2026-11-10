'use client';

import * as React from 'react';
import {
  Alert,
  Autocomplete,
  Box,
  Button,
  Collapse,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  Grid,
  IconButton,
  MenuItem,
  Stack,
  Switch,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import { Add, ArrowDownward, ArrowUpward, ContentPaste, Delete } from '@mui/icons-material';
import { toast } from 'react-toastify';

import { useGetUsersQuery } from '@/redux/UserApiSlice';
import {
  StopInput,
  StopType,
  Trip,
  TruckAssignment,
  useCreateTripMutation,
  useEditTripMutation,
  useGetTruckAssignmentsQuery,
  useLazyGetDriverAssignmentQuery,
  useParseTripTextMutation,
} from '@/redux/TripApiSlice';

import { STOP_LABEL } from './tripFormat';

// Add a load (Loads screen) or send one from a driver's chat. Truck first: picking a truck fills in
// the driver(s) its truck group assigns (both for a team); from a driver's chat their truck is
// already filled in. Then stops with their local appointment times, and either save it for later
// (it's offered to the driver when they ask / finish the current load) or send it now.
// A load typed the old way can be pasted in and read into the form.

interface Person {
  id: string;
  name: string;
}

interface Props {
  open: boolean;
  onClose: () => void;
  /** Editing a trip that isn't closed */
  trip?: Trip | null;
  /** Opened from a driver's chat */
  driver?: Person | null;
  onSaved?: (trip: Trip) => void;
}

const emptyStop = (type: StopType): StopInput => ({ type, name: '', street: '', city: '', state: '', zip: '', appointment: '' });

const truckLabel = (t: TruckAssignment) => `${t.truck}${t.drivers.length ? ` · ${t.drivers.map((d) => d.name).join(' + ')}` : ' · no driver assigned'}`;

/** Trucks with their assigned drivers; a number not in the list can still be typed. */
function TruckPicker({ value, onPick }: { value: string; onPick: (truck: string, assignment: TruckAssignment | null) => void }) {
  const [search, setSearch] = React.useState('');
  const { data, isFetching } = useGetTruckAssignmentsQuery(search);
  const options = data?.data || [];
  return (
    <Autocomplete
      size="small"
      freeSolo
      options={options}
      loading={isFetching}
      inputValue={value}
      onInputChange={(_, v, reason) => {
        if (reason === 'input') {
          setSearch(v);
          onPick(v, null);
        }
      }}
      onChange={(_, v) => {
        if (v && typeof v !== 'string') onPick(v.truck, v);
      }}
      getOptionLabel={(o) => (typeof o === 'string' ? o : o.truck)}
      renderOption={(props, o) => (
        <li {...props} key={o.truck}>
          {truckLabel(o)}
        </li>
      )}
      filterOptions={(x) => x}
      renderInput={(params) => <TextField {...params} label="Truck #" helperText="Picks the truck's assigned driver(s)" />}
    />
  );
}

function DriverPicker({ label, value, onChange }: { label: string; value: Person | null; onChange: (p: Person | null) => void }) {
  const [search, setSearch] = React.useState('');
  const { data, isFetching } = useGetUsersQuery({ role: 'driver', page: 1, search });
  const options: Person[] = (data?.data?.users || []).map((u: any) => ({
    id: u.id,
    name: `${u.username || 'Driver'}${u.user?.driver_number ? ` (${u.user.driver_number})` : ''}`,
  }));
  return (
    <Autocomplete
      size="small"
      options={value && !options.some((o) => o.id === value.id) ? [value, ...options] : options}
      loading={isFetching}
      value={value}
      onChange={(_, v) => onChange(v)}
      onInputChange={(_, v, reason) => reason === 'input' && setSearch(v)}
      getOptionLabel={(o) => o.name}
      isOptionEqualToValue={(a, b) => a.id === b.id}
      filterOptions={(x) => x}
      renderInput={(params) => <TextField {...params} label={label} />}
    />
  );
}

export function LoadFormDialog({ open, onClose, trip, driver, onSaved }: Props): React.JSX.Element {
  const editing = !!trip;
  const [driverPick, setDriverPick] = React.useState<Person | null>(driver || null);
  const [team, setTeam] = React.useState<Person | null>(null);
  const [truck, setTruck] = React.useState('');
  const [trailers, setTrailers] = React.useState('');
  const [temperature, setTemperature] = React.useState('');
  const [loaded, setLoaded] = React.useState(false);
  const [notes, setNotes] = React.useState('');
  const [stops, setStops] = React.useState<StopInput[]>([emptyStop('pickup'), emptyStop('drop')]);
  const [pasteOpen, setPasteOpen] = React.useState(false);
  const [pasted, setPasted] = React.useState('');
  const [readNotes, setReadNotes] = React.useState<string[]>([]);

  const [createTrip, { isLoading: creating }] = useCreateTripMutation();
  const [editTrip, { isLoading: saving }] = useEditTripMutation();
  const [parseText, { isLoading: reading }] = useParseTripTextMutation();
  const [lookupDriverTruck] = useLazyGetDriverAssignmentQuery();

  /** A truck was picked: its driver(s) from the truck group. */
  const pickTruck = (number: string, assignment: TruckAssignment | null) => {
    setTruck(number);
    if (!assignment) return;
    const [first, second] = assignment.drivers;
    if (first) setDriverPick(first);
    setTeam(second || null);
  };

  /** A driver was picked (or the form opened from their chat): their truck and team mate. */
  const fillFromDriver = async (person: Person | null, onlyIfEmpty: boolean) => {
    if (!person) return;
    try {
      const res = await lookupDriverTruck(person.id, true).unwrap();
      const a = res.data;
      if (!a) return;
      setTruck((current) => (onlyIfEmpty && current.trim() ? current : a.truck));
      const mate = a.drivers.find((d) => d.id !== person.id);
      if (mate) setTeam((current) => current || mate);
    } catch {
      // no truck group: dispatch types the truck
    }
  };

  // Fill from the trip being edited (or reset for a new one)
  React.useEffect(() => {
    if (!open) return;
    setReadNotes([]);
    setPasted('');
    setPasteOpen(false);
    if (trip) {
      setDriverPick(driver || (trip.driver_profile_id ? { id: trip.driver_profile_id, name: 'Current driver' } : null));
      setTeam(null);
      setTruck(trip.truck_number || '');
      setTrailers(trip.trailer_numbers || '');
      setTemperature(trip.temperature || '');
      setLoaded(!!trip.loaded_trailer);
      setNotes(trip.notes || '');
      setStops(
        [...(trip.stops || [])]
          .sort((a, b) => a.seq - b.seq)
          .map((s) => ({
            type: s.type,
            name: s.name || '',
            street: s.street || '',
            city: s.city || '',
            state: s.state || '',
            zip: s.zip || '',
            appointment: s.appointment_local || '',
            ref: s.ref || '',
          }))
      );
    } else {
      setDriverPick(driver || null);
      setTeam(null);
      setTruck('');
      setTrailers('');
      setTemperature('');
      setLoaded(false);
      setNotes('');
      setStops([emptyStop('pickup'), emptyStop('drop')]);
      if (driver) void fillFromDriver(driver, false);
    }
    // Once per opening (or a different trip / driver). The parent passes a new `driver` object on
    // every render and its name arrives a moment later: depending on the object reset the form —
    // and closed "Paste a typed load" — each time.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, trip?.id, driver?.id]);

  // The driver's name loaded after opening: show it without resetting anything
  React.useEffect(() => {
    if (!driver?.name) return;
    setDriverPick((current) => (current && current.id === driver.id ? { ...current, name: driver.name } : current));
  }, [driver?.id, driver?.name]);

  const setStop = (i: number, patch: Partial<StopInput>) => setStops((all) => all.map((s, j) => (j === i ? { ...s, ...patch } : s)));
  const move = (i: number, by: number) =>
    setStops((all) => {
      const next = [...all];
      const [s] = next.splice(i, 1);
      next.splice(i + by, 0, s);
      return next;
    });

  const readPasted = async () => {
    try {
      const res = await parseText(pasted).unwrap();
      const l = res.data;
      setStops(l.stops.map((s) => ({ ...s, appointment: s.appointment || '' })));
      if (l.truck) setTruck(l.truck);
      if (l.trailers.length) setTrailers(l.trailers.join(', '));
      if (l.temperature) setTemperature(l.temperature);
      setLoaded(l.loadedTrailer);
      setReadNotes([...l.reasons, ...(l.team.length > 1 ? [`Team in the text: ${l.team.join(' + ')} — pick the second driver above`] : [])]);
      setPasteOpen(false);
      toast.success('Load read — check the fields');
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not read that text');
    }
  };

  const problems = (): string | null => {
    if (!driverPick && !truck.trim()) return 'Choose a driver or enter a truck number';
    if (!stops.length) return 'Add at least one stop';
    if (stops.some((s) => !s.city?.trim() || !s.state?.trim())) return 'Every stop needs a city and state';
    if (!stops.some((s) => s.type === 'drop')) return 'Add the delivery';
    return null;
  };

  const save = async (send: boolean) => {
    const problem = problems();
    if (problem) {
      toast.error(problem);
      return;
    }
    const body = {
      driverProfileId: driverPick?.id || null,
      truckNumber: truck.trim() || null,
      teamDriverProfileId: team?.id || null,
      trailerNumbers: trailers.split(/[,\s]+/).map((t) => t.trim()).filter(Boolean),
      temperature: temperature.trim() || null,
      loadedTrailer: loaded,
      notes: notes.trim() || null,
      stops: stops.map((s) => ({ ...s, state: s.state?.toUpperCase(), appointment: s.appointment || null })),
    };
    try {
      const res = editing
        ? await editTrip({ id: trip!.id, ...body, needsReview: false }).unwrap()
        : await createTrip({ ...body, send }).unwrap();
      toast.success(res.message || (send ? 'Load sent to the driver' : 'Load saved'));
      onSaved?.(res.data);
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save the load');
    }
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md">
      <DialogTitle>{editing ? `Edit trip #${trip?.trip_no || trip?.id}` : driver ? `Send load to ${driver.name}` : 'Add load'}</DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2}>
          {!editing && (
            <Box>
              <Button size="small" startIcon={<ContentPaste />} onClick={() => setPasteOpen((v) => !v)}>
                Paste a typed load
              </Button>
              <Collapse in={pasteOpen}>
                <Stack spacing={1} sx={{ mt: 1 }}>
                  <TextField
                    multiline
                    minRows={6}
                    placeholder={'PICK #\nCOLD LINK - ELLISVILLE\n609 DACETOWN RD\nELLISVILLE, MS 39437\n\nDROP #\n…'}
                    value={pasted}
                    onChange={(e) => setPasted(e.target.value)}
                  />
                  <Box>
                    <Button variant="outlined" size="small" disabled={!pasted.trim() || reading} onClick={() => void readPasted()}>
                      Read into the form
                    </Button>
                  </Box>
                </Stack>
              </Collapse>
            </Box>
          )}
          {readNotes.length > 0 && (
            <Alert severity="warning">
              {readNotes.map((n) => (
                <div key={n}>{n}</div>
              ))}
            </Alert>
          )}

          <Grid container spacing={2}>
            <Grid item xs={12} md={6}>
              <TruckPicker value={truck} onPick={pickTruck} />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField size="small" fullWidth label="Trailer #" helperText="Several: 10265, 10266" value={trailers} onChange={(e) => setTrailers(e.target.value)} />
            </Grid>
            <Grid item xs={12} md={6}>
              <DriverPicker
                label="Driver"
                value={driverPick}
                onChange={(p) => {
                  setDriverPick(p);
                  void fillFromDriver(p, true);
                }}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <DriverPicker label="Team driver (optional)" value={team} onChange={setTeam} />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField size="small" fullWidth label="Temperature" placeholder="34 CONT. / REFER ON BILLS" value={temperature} onChange={(e) => setTemperature(e.target.value)} />
            </Grid>
            <Grid item xs={12} md={6}>
              <FormControlLabel control={<Switch checked={loaded} onChange={(e) => setLoaded(e.target.checked)} />} label="Loaded trailer (pick up already loaded)" />
            </Grid>
          </Grid>

          <Typography variant="subtitle2">Stops — appointment in the stop's own local time</Typography>
          {stops.map((s, i) => (
            <Box key={i} sx={{ border: 1, borderColor: 'divider', borderRadius: 1, p: 1.5 }}>
              <Grid container spacing={1} alignItems="center">
                <Grid item xs={6} md={2}>
                  <TextField select size="small" fullWidth label={`Stop ${i + 1}`} value={s.type} onChange={(e) => setStop(i, { type: e.target.value as StopType })}>
                    {(Object.keys(STOP_LABEL) as StopType[]).map((t) => (
                      <MenuItem key={t} value={t}>
                        {STOP_LABEL[t]}
                      </MenuItem>
                    ))}
                  </TextField>
                </Grid>
                <Grid item xs={6} md={4}>
                  <TextField size="small" fullWidth label="Name" value={s.name} onChange={(e) => setStop(i, { name: e.target.value })} />
                </Grid>
                <Grid item xs={12} md={6}>
                  <TextField size="small" fullWidth label="Street" value={s.street} onChange={(e) => setStop(i, { street: e.target.value })} />
                </Grid>
                <Grid item xs={6} md={3}>
                  <TextField size="small" fullWidth label="City" value={s.city} onChange={(e) => setStop(i, { city: e.target.value })} />
                </Grid>
                <Grid item xs={3} md={1}>
                  <TextField
                    size="small"
                    fullWidth
                    label="ST"
                    inputProps={{ maxLength: 2, style: { textTransform: 'uppercase' } }}
                    value={s.state}
                    onChange={(e) => setStop(i, { state: e.target.value })}
                  />
                </Grid>
                <Grid item xs={3} md={2}>
                  <TextField size="small" fullWidth label="ZIP" value={s.zip} onChange={(e) => setStop(i, { zip: e.target.value })} />
                </Grid>
                <Grid item xs={9} md={4}>
                  <TextField
                    size="small"
                    fullWidth
                    type="datetime-local"
                    label="Appointment"
                    InputLabelProps={{ shrink: true }}
                    value={s.appointment || ''}
                    onChange={(e) => setStop(i, { appointment: e.target.value })}
                  />
                </Grid>
                <Grid item xs={3} md={2}>
                  <Stack direction="row" justifyContent="flex-end">
                    <Tooltip title="Move up">
                      <span>
                        <IconButton size="small" disabled={i === 0} onClick={() => move(i, -1)}>
                          <ArrowUpward fontSize="small" />
                        </IconButton>
                      </span>
                    </Tooltip>
                    <Tooltip title="Move down">
                      <span>
                        <IconButton size="small" disabled={i === stops.length - 1} onClick={() => move(i, 1)}>
                          <ArrowDownward fontSize="small" />
                        </IconButton>
                      </span>
                    </Tooltip>
                    <Tooltip title="Remove stop">
                      <span>
                        <IconButton size="small" disabled={stops.length === 1} onClick={() => setStops((all) => all.filter((_, j) => j !== i))}>
                          <Delete fontSize="small" />
                        </IconButton>
                      </span>
                    </Tooltip>
                  </Stack>
                </Grid>
              </Grid>
            </Box>
          ))}
          <Box>
            <Button size="small" startIcon={<Add />} onClick={() => setStops((all) => [...all, emptyStop('drop')])}>
              Add stop
            </Button>
          </Box>
          <TextField size="small" label="Notes for the driver" multiline minRows={2} value={notes} onChange={(e) => setNotes(e.target.value)} />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Close</Button>
        {editing ? (
          <Button variant="contained" disabled={saving} onClick={() => void save(false)}>
            Save changes
          </Button>
        ) : (
          <>
            <Button variant="outlined" disabled={creating} onClick={() => void save(false)}>
              Save for later
            </Button>
            <Button variant="contained" disabled={creating} onClick={() => void save(true)}>
              Send now
            </Button>
          </>
        )}
      </DialogActions>
    </Dialog>
  );
}
