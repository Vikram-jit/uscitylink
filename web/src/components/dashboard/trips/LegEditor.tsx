'use client';

import * as React from 'react';
import {
  FleetDriver,
  FleetTrailer,
  FleetTruck,
  LegRef,
  StopInput,
  StopType,
  TruckAssignment,
  useGetFleetDriversQuery,
  useGetFleetTrailersQuery,
  useGetFleetTrucksQuery,
  useGetTruckAssignmentsQuery,
  useLazyGetDriverAssignmentQuery,
} from '@/redux/TripApiSlice';
import { useGetUsersQuery } from '@/redux/UserApiSlice';
import { Add, ArrowDownward, ArrowUpward, Delete, Edit, MoreVert, Tune } from '@mui/icons-material';
import {
  Alert,
  Autocomplete,
  Box,
  Button,
  Checkbox,
  Chip,
  Collapse,
  FormControlLabel,
  Grid,
  IconButton,
  Link,
  ListItemIcon,
  Menu,
  MenuItem,
  Stack,
  TextField,
  Typography,
} from '@mui/material';

import { AddressSearch } from './AddressSearch';
import { minutesText, STOP_LABEL } from './tripFormat';

// One leg of a load: who moves it (truck first — its truck group fills in the driver(s); trailer;
// team) and its route (stops found with Google, each with its local appointment time). Every truck,
// trailer and driver shows whether it's free, already on a load, or in the yard, so dispatch doesn't
// double-book.

export interface Person {
  id: string;
  name: string;
}

export interface LegState {
  key: string;
  driver: Person | null;
  team: Person | null;
  truck: string;
  trailers: string[];
  temperature: string;
  loaded: boolean;
  notes: string;
  stops: StopInput[];
}

export const emptyStop = (type: StopType): StopInput => ({
  type,
  name: '',
  street: '',
  city: '',
  state: '',
  zip: '',
  appointment: '',
});

let legKey = 0;
export const newLeg = (stops: StopInput[], patch: Partial<LegState> = {}): LegState => ({
  key: `leg${++legKey}`,
  driver: null,
  team: null,
  truck: '',
  trailers: [],
  temperature: '',
  loaded: false,
  notes: '',
  stops,
  ...patch,
});

/** The leg as the API takes it. */
export const legBody = (leg: LegState) => ({
  driverProfileId: leg.driver?.id || null,
  truckNumber: leg.truck.trim() || null,
  teamDriverProfileId: leg.team?.id || null,
  trailerNumbers: leg.trailers.map((t) => t.trim()).filter(Boolean),
  temperature: leg.temperature.trim() || null,
  loadedTrailer: leg.loaded,
  notes: leg.notes.trim() || null,
  stops: leg.stops.map((s) => ({ ...s, state: s.state?.toUpperCase(), appointment: s.appointment || null })),
});

/** Stop colours on the route line */
export const STOP_COLOR: Record<StopType, string> = {
  pickup: 'success.main',
  drop: 'error.main',
  yard: 'warning.main',
  switch: 'info.main',
};

// ---------- availability ----------

const refText = (leg: LegRef | null) =>
  leg ? `${leg.tripNo || `trip ${leg.tripId}`}${leg.invoiceNo ? ` · load ${leg.invoiceNo}` : ''}` : '';
const since = (iso?: string | null) => (iso ? minutesText((Date.now() - new Date(iso).getTime()) / 60000) : '');

export function truckState(
  t?: FleetTruck | null
): { label: string; color: 'success' | 'error' | 'warning' | 'default' } | null {
  if (!t) return null;
  if (t.state === 'on_load') return { label: `On load ${refText(t.leg)}`, color: 'error' };
  if (t.state === 'lined_up') return { label: `Lined up ${refText(t.leg)}`, color: 'warning' };
  return { label: 'Free', color: 'success' };
}

export function trailerState(
  t?: FleetTrailer | null
): { label: string; color: 'success' | 'error' | 'warning' | 'info' | 'default' } | null {
  if (!t) return null;
  if (t.state === 'on_load') return { label: `On load ${refText(t.leg)}`, color: 'error' };
  if (t.state === 'waiting_transfer') return { label: `Waiting for next leg ${refText(t.leg)}`, color: 'warning' };
  if (t.state === 'in_yard')
    return {
      label: `In yard · ${t.gate?.loaded || 'empty?'} · ${since(t.gate?.at)}`,
      color: t.gate?.loaded === 'loaded' ? 'info' : 'success',
    };
  if (t.state === 'out') return { label: `Out of yard · ${since(t.gate?.at)}`, color: 'default' };
  return { label: 'No gate record', color: 'default' };
}

export function driverState(
  d?: FleetDriver | null
): { label: string; color: 'success' | 'error' | 'warning' | 'default' } | null {
  if (!d) return null;
  const more = d.lineup ? ` · ${d.lineup} next` : '';
  if (d.state === 'on_load') return { label: `On load ${refText(d.leg)}${more}`, color: 'error' };
  if (d.state === 'lined_up') return { label: `${d.lineup} lined up · #1 ${refText(d.next)}`, color: 'warning' };
  return { label: 'Free', color: 'success' };
}

const StateChip = ({ s }: { s: { label: string; color: any } | null }) =>
  s ? (
    <Chip
      size="small"
      variant={s.color === 'default' ? 'outlined' : 'filled'}
      color={s.color}
      label={s.label}
      sx={{ maxWidth: 260 }}
    />
  ) : null;

/** Equipment used by another load (not this one) */
const otherLoad = (leg: LegRef | null, loadId?: number | null) => !!leg && (!loadId || leg.loadId !== loadId);

// ---------- pickers ----------

const truckLabel = (t: TruckAssignment) =>
  `${t.truck}${t.drivers.length ? ` · ${t.drivers.map((d) => d.name).join(' + ')}` : ' · no driver assigned'}`;

/** Trucks with their assigned drivers; a number not in the list can still be typed. */
function TruckPicker({
  value,
  onPick,
  fleet,
}: {
  value: string;
  onPick: (truck: string, a: TruckAssignment | null) => void;
  fleet: Map<string, FleetTruck>;
}) {
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
          <Stack direction="row" spacing={1} alignItems="center" sx={{ width: '100%' }}>
            <Typography variant="body2" sx={{ flexGrow: 1 }}>
              {truckLabel(o)}
            </Typography>
            <StateChip s={truckState(fleet.get(o.truck.trim().toUpperCase()))} />
          </Stack>
        </li>
      )}
      filterOptions={(x) => x}
      renderInput={(params) => <TextField {...params} label="Truck #" placeholder="Fills the driver" />}
    />
  );
}

/** Fleet trailers, the ones in the yard first; several allowed, a number not in the list can be typed. */
function TrailerPicker({
  value,
  onChange,
  fleet,
}: {
  value: string[];
  onChange: (v: string[]) => void;
  fleet: FleetTrailer[];
}) {
  const order = { in_yard: 0, unknown: 1, out: 2, waiting_transfer: 3, on_load: 4 } as const;
  const options = React.useMemo(
    () =>
      [...fleet]
        .sort((a, b) => order[a.state] - order[b.state] || a.number.localeCompare(b.number))
        .map((t) => t.number),
    [fleet]
  );
  const byNumber = React.useMemo(() => new Map(fleet.map((t) => [t.number.toUpperCase(), t])), [fleet]);
  return (
    <Autocomplete
      size="small"
      multiple
      freeSolo
      options={options}
      value={value}
      onChange={(_, v) => onChange((v as string[]).map((x) => x.trim()).filter(Boolean))}
      renderOption={(props, o) => (
        <li {...props} key={o}>
          <Stack direction="row" spacing={1} alignItems="center" sx={{ width: '100%' }}>
            <Typography variant="body2" sx={{ minWidth: 70 }}>
              {o}
            </Typography>
            <StateChip s={trailerState(byNumber.get(o.toUpperCase()))} />
          </Stack>
        </li>
      )}
      renderTags={(v, getTagProps) =>
        v.map((o, i) => {
          const s = trailerState(byNumber.get(o.toUpperCase()));
          return (
            <Chip
              size="small"
              label={o}
              color={s?.color === 'error' ? 'error' : 'default'}
              {...getTagProps({ index: i })}
              key={o}
            />
          );
        })
      }
      renderInput={(params) => (
        <TextField {...params} label="Trailer #" placeholder={value.length ? '' : 'In-yard first'} />
      )}
    />
  );
}

function DriverPicker({
  label,
  value,
  onChange,
  fleet,
}: {
  label: string;
  value: Person | null;
  onChange: (p: Person | null) => void;
  fleet: Map<string, FleetDriver>;
}) {
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
      renderOption={(props, o) => (
        <li {...props} key={o.id}>
          <Stack direction="row" spacing={1} alignItems="center" sx={{ width: '100%' }}>
            <Typography variant="body2" sx={{ flexGrow: 1 }}>
              {o.name}
            </Typography>
            <StateChip s={driverState(fleet.get(o.id))} />
          </Stack>
        </li>
      )}
      renderInput={(params) => <TextField {...params} label={label} />}
    />
  );
}

// ---------- the route ----------

const addressLine = (s: StopInput) =>
  [s.street, [s.city, [s.state, s.zip].filter(Boolean).join(' ')].filter(Boolean).join(', ')]
    .filter(Boolean)
    .join(', ');

/** The dot and line of the route timeline */
function RouteDot({ color, last }: { color: string; last?: boolean }) {
  return (
    <Box
      sx={{ width: 20, display: 'flex', flexDirection: 'column', alignItems: 'center', alignSelf: 'stretch', pt: 1.25 }}
    >
      <Box
        sx={{
          width: 12,
          height: 12,
          borderRadius: '50%',
          bgcolor: color,
          boxShadow: (t) => `0 0 0 3px ${t.palette.background.paper}`,
          flexShrink: 0,
        }}
      />
      {!last && <Box sx={{ flexGrow: 1, width: 2, bgcolor: 'divider', mt: 0.5 }} />}
    </Box>
  );
}

function StopRow({
  stop,
  index,
  count,
  onChange,
  onMove,
  onRemove,
  last,
}: {
  stop: StopInput;
  index: number;
  count: number;
  onChange: (patch: Partial<StopInput>) => void;
  onMove: (by: number) => void;
  onRemove: () => void;
  last: boolean;
}) {
  const filled = !!(stop.city?.trim() && stop.state?.trim());
  const [manual, setManual] = React.useState(false);
  const [menu, setMenu] = React.useState<HTMLElement | null>(null);
  const showFields = manual;

  return (
    <Stack direction="row" spacing={1.5} data-testid={`stop-${index + 1}`}>
      <RouteDot color={STOP_COLOR[stop.type]} last={last} />
      <Box sx={{ flexGrow: 1, pb: last ? 0 : 2, minWidth: 0 }}>
        <Stack direction="row" spacing={1} alignItems="center">
          <TextField
            select
            size="small"
            variant="standard"
            value={stop.type}
            onChange={(e) => onChange({ type: e.target.value as StopType })}
            InputProps={{ disableUnderline: true, sx: { fontWeight: 700, fontSize: 13, color: STOP_COLOR[stop.type] } }}
            sx={{ minWidth: 110 }}
          >
            {(Object.keys(STOP_LABEL) as StopType[]).map((k) => (
              <MenuItem key={k} value={k}>
                {STOP_LABEL[k]}
              </MenuItem>
            ))}
          </TextField>
          <Box sx={{ flexGrow: 1 }} />
          <TextField
            size="small"
            type="datetime-local"
            label="Appointment (local)"
            InputLabelProps={{ shrink: true }}
            value={stop.appointment || ''}
            onChange={(e) => onChange({ appointment: e.target.value })}
            sx={{ width: 230 }}
          />
          <IconButton size="small" onClick={(e) => setMenu(e.currentTarget)} aria-label="Stop options">
            <MoreVert fontSize="small" />
          </IconButton>
          <Menu anchorEl={menu} open={!!menu} onClose={() => setMenu(null)}>
            <MenuItem disabled={index === 0} onClick={() => (onMove(-1), setMenu(null))}>
              <ListItemIcon>
                <ArrowUpward fontSize="small" />
              </ListItemIcon>
              Move up
            </MenuItem>
            <MenuItem disabled={index === count - 1} onClick={() => (onMove(1), setMenu(null))}>
              <ListItemIcon>
                <ArrowDownward fontSize="small" />
              </ListItemIcon>
              Move down
            </MenuItem>
            <MenuItem disabled={count === 1} onClick={() => (onRemove(), setMenu(null))}>
              <ListItemIcon>
                <Delete fontSize="small" />
              </ListItemIcon>
              Remove stop
            </MenuItem>
          </Menu>
        </Stack>

        {filled && !showFields ? (
          <Stack direction="row" spacing={1} alignItems="flex-start" sx={{ mt: 0.5 }} data-testid="stopSummary">
            <Box sx={{ flexGrow: 1, minWidth: 0 }}>
              <Typography variant="body2" fontWeight={700} noWrap>
                {stop.name || addressLine(stop)}
              </Typography>
              {stop.name && (
                <Typography variant="caption" color="text.secondary" noWrap component="div">
                  {addressLine(stop)}
                </Typography>
              )}
            </Box>
            <Button
              size="small"
              startIcon={<Edit sx={{ fontSize: 16 }} />}
              onClick={() => setManual(true)}
              sx={{ flexShrink: 0 }}
            >
              Edit
            </Button>
          </Stack>
        ) : (
          <Stack spacing={1} sx={{ mt: 0.75 }}>
            <AddressSearch
              onPick={(patch) => {
                onChange(patch);
                setManual(false);
              }}
            />
            {!showFields && (
              <Link
                component="button"
                type="button"
                variant="caption"
                onClick={() => setManual(true)}
                sx={{ alignSelf: 'flex-start' }}
              >
                or type the address
              </Link>
            )}
            <Collapse in={showFields} unmountOnExit>
              <Grid container spacing={1}>
                <Grid item xs={12} md={5}>
                  <TextField
                    size="small"
                    fullWidth
                    label="Name"
                    value={stop.name}
                    onChange={(e) => onChange({ name: e.target.value })}
                  />
                </Grid>
                <Grid item xs={12} md={7}>
                  <TextField
                    size="small"
                    fullWidth
                    label="Street"
                    value={stop.street}
                    onChange={(e) => onChange({ street: e.target.value })}
                  />
                </Grid>
                <Grid item xs={6} md={5}>
                  <TextField
                    size="small"
                    fullWidth
                    label="City"
                    value={stop.city}
                    onChange={(e) => onChange({ city: e.target.value })}
                  />
                </Grid>
                <Grid item xs={3} md={2}>
                  <TextField
                    size="small"
                    fullWidth
                    label="ST"
                    inputProps={{ maxLength: 2, style: { textTransform: 'uppercase' } }}
                    value={stop.state}
                    onChange={(e) => onChange({ state: e.target.value })}
                  />
                </Grid>
                <Grid item xs={3} md={3}>
                  <TextField
                    size="small"
                    fullWidth
                    label="ZIP"
                    value={stop.zip}
                    onChange={(e) => onChange({ zip: e.target.value })}
                  />
                </Grid>
                <Grid item xs={12} md={2}>
                  <Button
                    fullWidth
                    size="small"
                    variant="outlined"
                    sx={{ height: 40 }}
                    disabled={!filled}
                    onClick={() => setManual(false)}
                  >
                    Done
                  </Button>
                </Grid>
              </Grid>
            </Collapse>
          </Stack>
        )}
      </Box>
    </Stack>
  );
}

// ---------- the leg ----------

interface Props {
  leg: LegState;
  onChange: (patch: Partial<LegState>) => void;
  /** Leg 2+: where it starts (the yard / meet point the leg before ends at) — not edited here */
  startsAt?: StopInput | null;
  /** Leg 2+ can be saved before the driver is known */
  assignLater?: boolean;
  /** The load being edited: its own legs don't count as "busy" */
  loadId?: number | null;
  /** Hide the people (editing stops only) */
  hidePeople?: boolean;
  /** Only the people (assigning a driver / truck / trailer to a leg) */
  peopleOnly?: boolean;
}

export function LegEditor({
  leg,
  onChange,
  startsAt,
  assignLater,
  loadId,
  hidePeople,
  peopleOnly,
}: Props): React.JSX.Element {
  const trucks = useGetFleetTrucksQuery();
  const trailers = useGetFleetTrailersQuery();
  const drivers = useGetFleetDriversQuery();
  const truckMap = React.useMemo(
    () => new Map((trucks.data?.data || []).map((t) => [t.number.trim().toUpperCase(), t])),
    [trucks.data]
  );
  const trailerList = trailers.data?.data || [];
  const trailerMap = React.useMemo(
    () => new Map(trailerList.map((t) => [t.number.trim().toUpperCase(), t])),
    [trailerList]
  );
  const driverMap = React.useMemo(
    () => new Map((drivers.data?.data || []).filter((d) => d.profileId).map((d) => [d.profileId!, d])),
    [drivers.data]
  );
  const [lookupDriverTruck] = useLazyGetDriverAssignmentQuery();
  const [more, setMore] = React.useState(!!(leg.temperature || leg.notes));

  const pickTruck = (number: string, a: TruckAssignment | null) => {
    if (!a) return onChange({ truck: number });
    const [first, second] = a.drivers;
    onChange({ truck: number, ...(first ? { driver: first } : {}), team: second || null });
  };

  const pickDriver = async (p: Person | null) => {
    onChange({ driver: p });
    if (!p) return;
    try {
      const a = (await lookupDriverTruck(p.id, true).unwrap()).data;
      if (!a) return;
      const mate = a.drivers.find((d) => d.id !== p.id);
      onChange({
        driver: p,
        ...(leg.truck.trim() ? {} : { truck: a.truck }),
        ...(mate && !leg.team ? { team: mate } : {}),
      });
    } catch {
      // no truck group: dispatch types the truck
    }
  };

  // Already on another load
  const warnings: { text: string; severity: 'error' | 'warning' }[] = [];
  const t = truckMap.get(leg.truck.trim().toUpperCase());
  if (t && t.state !== 'free' && otherLoad(t.leg, loadId))
    warnings.push({
      text: `Truck ${t.number}: ${truckState(t)!.label}`,
      severity: t.state === 'on_load' ? 'error' : 'warning',
    });
  for (const n of leg.trailers) {
    const tr = trailerMap.get(n.trim().toUpperCase());
    if (tr && (tr.state === 'on_load' || tr.state === 'waiting_transfer') && otherLoad(tr.leg, loadId)) {
      warnings.push({
        text: `Trailer ${tr.number}: ${trailerState(tr)!.label}`,
        severity: tr.state === 'on_load' ? 'error' : 'warning',
      });
    }
  }
  for (const p of [leg.driver, leg.team].filter(Boolean) as Person[]) {
    const d = driverMap.get(p.id);
    if (d && d.state !== 'free' && otherLoad(d.leg, loadId))
      warnings.push({
        text: `${d.name}: ${driverState(d)!.label}`,
        severity: d.state === 'on_load' ? 'error' : 'warning',
      });
  }

  const setStop = (i: number) => (patch: Partial<StopInput>) =>
    onChange({ stops: leg.stops.map((s, j) => (j === i ? { ...s, ...patch } : s)) });
  const move = (i: number) => (by: number) => {
    const next = [...leg.stops];
    const [s] = next.splice(i, 1);
    next.splice(i + by, 0, s);
    onChange({ stops: next });
  };
  const truckChip = truckState(t);
  const driverChip = leg.driver ? driverState(driverMap.get(leg.driver.id)) : null;

  return (
    <Stack spacing={2}>
      {!hidePeople && (
        <Box>
          {!peopleOnly && (
            <Typography variant="overline" color="text.secondary">
              Driver &amp; equipment
            </Typography>
          )}
          <Grid container spacing={1.5}>
            <Grid item xs={12} sm={6} md={3}>
              <TruckPicker value={leg.truck} onPick={pickTruck} fleet={truckMap} />
              {truckChip && (
                <Box sx={{ mt: 0.5 }}>
                  <StateChip s={truckChip} />
                </Box>
              )}
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <DriverPicker
                label={assignLater ? 'Driver (or later)' : 'Driver'}
                value={leg.driver}
                onChange={(p) => void pickDriver(p)}
                fleet={driverMap}
              />
              {driverChip && (
                <Box sx={{ mt: 0.5 }}>
                  <StateChip s={driverChip} />
                </Box>
              )}
              {!loadId && leg.driver && (driverMap.get(leg.driver.id)?.lineup || 0) > 0 && (
                <Typography variant="caption" color="text.secondary" component="div" data-testid="lineupNote">
                  {leg.driver.name.split(' (')[0]} has {driverMap.get(leg.driver.id)!.lineup} load
                  {driverMap.get(leg.driver.id)!.lineup === 1 ? '' : 's'} lined up — this one goes after them (#{driverMap.get(leg.driver.id)!.lineup + 1})
                </Typography>
              )}
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <DriverPicker
                label="Team driver"
                value={leg.team}
                onChange={(p) => onChange({ team: p })}
                fleet={driverMap}
              />
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <TrailerPicker value={leg.trailers} onChange={(v) => onChange({ trailers: v })} fleet={trailerList} />
              {!peopleOnly && (
                <FormControlLabel
                  sx={{ mt: 0.25, ml: 0 }}
                  control={
                    <Checkbox
                      size="small"
                      checked={leg.loaded}
                      onChange={(e) => onChange({ loaded: e.target.checked })}
                      sx={{ p: 0.5 }}
                    />
                  }
                  label={
                    <Typography variant="caption">
                      {startsAt ? 'Already loaded (from leg before)' : 'Already loaded'}
                    </Typography>
                  }
                />
              )}
            </Grid>
          </Grid>
        </Box>
      )}
      {warnings.map((w) => (
        <Alert key={w.text} severity={w.severity} sx={{ py: 0 }} data-testid="legBusyWarning">
          {w.text} — already {w.severity === 'error' ? 'in use' : 'lined up'} on another load. You can still save it.
        </Alert>
      ))}

      {!peopleOnly && (
        <Box>
          <Typography variant="overline" color="text.secondary">
            Route
          </Typography>
          <Box sx={{ mt: 0.5 }}>
            {startsAt && (
              <Stack direction="row" spacing={1.5} data-testid="legStartsAt">
                <RouteDot color={STOP_COLOR[startsAt.type]} />
                <Box sx={{ pb: 2 }}>
                  <Typography variant="caption" fontWeight={700} sx={{ color: STOP_COLOR[startsAt.type] }}>
                    Starts at {STOP_LABEL[startsAt.type]}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {[startsAt.name, [startsAt.city, startsAt.state].filter(Boolean).join(', ')]
                      .filter(Boolean)
                      .join(' · ') || 'Set in the leg before'}
                  </Typography>
                </Box>
              </Stack>
            )}
            {leg.stops.map((s, i) => (
              <StopRow
                key={i}
                stop={s}
                index={i}
                count={leg.stops.length}
                onChange={setStop(i)}
                onMove={move(i)}
                onRemove={() => onChange({ stops: leg.stops.filter((_, j) => j !== i) })}
                last={i === leg.stops.length - 1}
              />
            ))}
          </Box>
          <Stack direction="row" spacing={1} sx={{ mt: 1, ml: 4 }}>
            <Button
              size="small"
              startIcon={<Add />}
              onClick={() => onChange({ stops: [...leg.stops, emptyStop('drop')] })}
            >
              Add stop
            </Button>
            {!hidePeople && !more && (
              <Button
                size="small"
                color="inherit"
                startIcon={<Tune />}
                onClick={() => setMore(true)}
                sx={{ color: 'text.secondary' }}
              >
                Temperature &amp; notes
              </Button>
            )}
          </Stack>
        </Box>
      )}

      {!hidePeople && !peopleOnly && (
        <Collapse in={more} unmountOnExit>
          <Grid container spacing={1.5}>
            <Grid item xs={12} md={4}>
              <TextField
                size="small"
                fullWidth
                label="Temperature"
                placeholder="34 CONT. / REFER ON BILLS"
                value={leg.temperature}
                onChange={(e) => onChange({ temperature: e.target.value })}
              />
            </Grid>
            <Grid item xs={12} md={8}>
              <TextField
                size="small"
                fullWidth
                label="Notes for the driver"
                multiline
                maxRows={4}
                value={leg.notes}
                onChange={(e) => onChange({ notes: e.target.value })}
              />
            </Grid>
          </Grid>
        </Collapse>
      )}
    </Stack>
  );
}
