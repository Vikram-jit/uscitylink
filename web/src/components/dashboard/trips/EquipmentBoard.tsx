'use client';

import * as React from 'react';
import {
  Box,
  Button,
  Card,
  Chip,
  Dialog,
  DialogContent,
  DialogTitle,
  IconButton,
  InputAdornment,
  LinearProgress,
  List,
  ListItemButton,
  ListItemText,
  Stack,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Tabs,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import { Refresh, Search } from '@mui/icons-material';

import {
  LegRef,
  Load,
  Trip,
  useGetFleetDriversQuery,
  useGetFleetTrailersQuery,
  useGetFleetTrucksQuery,
  useListLoadBoardQuery,
} from '@/redux/TripApiSlice';
import { useSocketEvent } from '@/hooks/use-socket-event';

import { AssignLegDialog } from './AssignLegDialog';
import { LineupDrawer } from './LineupDrawer';
import { driverState, LegState, trailerState, truckState } from './LegEditor';
import { LoadDrawer } from './LoadDrawer';
import { legsInOrder } from './tripFormat';

// Who and what is free right now: the fleet's trucks, trailers and drivers against the loads they're
// on, and where trailers are by the yard's gate log (in the yard loaded / empty, out). A free one can
// go straight onto a load waiting for its next leg.

type Kind = 'trucks' | 'trailers' | 'drivers';

const FILTERS: Record<Kind, { key: string; label: string }[]> = {
  trucks: [
    { key: 'all', label: 'All' },
    { key: 'free', label: 'Free' },
    { key: 'on_load', label: 'On load' },
    { key: 'lined_up', label: 'Lined up' },
  ],
  trailers: [
    { key: 'all', label: 'All' },
    { key: 'in_yard', label: 'In yard' },
    { key: 'waiting_transfer', label: 'Waiting for next leg' },
    { key: 'on_load', label: 'On load' },
    { key: 'out', label: 'Out of yard' },
  ],
  drivers: [
    { key: 'all', label: 'All' },
    { key: 'free', label: 'Free' },
    { key: 'on_load', label: 'On load' },
    { key: 'lined_up', label: 'Lined up' },
  ],
};

const LegLink = ({ leg, onOpen }: { leg: LegRef | null; onOpen: (loadId: number) => void }) =>
  leg?.loadId ? (
    <Button size="small" onClick={() => onOpen(leg.loadId!)} sx={{ textTransform: 'none' }}>
      #{leg.tripNo}
      {leg.invoiceNo ? ` · ${leg.invoiceNo}` : ''}
    </Button>
  ) : (
    <Typography variant="caption" color="text.disabled">
      —
    </Typography>
  );

/** Loads waiting for a driver on their next leg (in the yard / at a meet point, or not sent yet). */
function waitingLegs(loads: Load[]): { load: Load; leg: Trip; canSend: boolean }[] {
  const out: { load: Load; leg: Trip; canSend: boolean }[] = [];
  for (const load of loads) {
    const legs = legsInOrder(load.legs).filter((l) => l.status !== 'cancelled');
    const i = legs.findIndex((l) => ['scheduled', 'offered'].includes(l.status));
    if (i < 0) continue;
    const prev = legs[i - 1];
    out.push({ load, leg: legs[i], canSend: !prev || ['ended', 'paperwork', 'completed', 'routed'].includes(prev.status) });
  }
  return out;
}

export function EquipmentBoard(): React.JSX.Element {
  const [kind, setKind] = React.useState<Kind>('trailers');
  const [filter, setFilter] = React.useState('all');
  const [q, setQ] = React.useState('');
  const [openLoad, setOpenLoad] = React.useState<number | null>(null);
  const [lineupOf, setLineupOf] = React.useState<string | null>(null);
  const [useFor, setUseFor] = React.useState<{ label: string; prefill: Partial<LegState> } | null>(null);
  const [assigning, setAssigning] = React.useState<{ loadId: number; leg: Trip; canSend: boolean; prefill: Partial<LegState> } | null>(null);

  const trucks = useGetFleetTrucksQuery();
  const trailers = useGetFleetTrailersQuery();
  const drivers = useGetFleetDriversQuery();
  const waiting = useListLoadBoardQuery({ status: 'transfer,scheduled,waiting', limit: 50 }, { skip: !useFor });
  const refresh = React.useCallback(() => {
    void trucks.refetch();
    void trailers.refetch();
    void drivers.refetch();
  }, [trucks, trailers, drivers]);
  useSocketEvent('load:updated', refresh);

  const term = q.trim().toUpperCase();
  const match = (...texts: (string | null | undefined)[]) => !term || texts.some((t) => (t || '').toUpperCase().includes(term));
  const fetching = trucks.isFetching || trailers.isFetching || drivers.isFetching;

  const truckRows = (trucks.data?.data || []).filter((t) => (filter === 'all' || t.state === filter) && match(t.number, ...t.drivers.map((d) => d.name), t.leg?.tripNo, t.leg?.invoiceNo));
  const trailerRows = (trailers.data?.data || []).filter((t) => (filter === 'all' || t.state === filter) && match(t.number, t.type, t.leg?.tripNo, t.leg?.invoiceNo));
  const driverRows = (drivers.data?.data || []).filter((d) => (filter === 'all' || d.state === filter) && match(d.name, d.truck, d.leg?.tripNo, d.leg?.invoiceNo));

  const count = (k: Kind, state: string) => {
    const list: { state: string }[] = k === 'trucks' ? trucks.data?.data || [] : k === 'trailers' ? trailers.data?.data || [] : drivers.data?.data || [];
    return state === 'all' ? list.length : list.filter((x) => x.state === state).length;
  };
  const since = (iso?: string | null) => (iso ? new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }).format(new Date(iso)) : '');

  return (
    <Card data-testid="equipmentBoard">
      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ p: 2 }} alignItems={{ sm: 'center' }}>
        <Tabs
          value={kind}
          onChange={(_, v) => {
            setKind(v);
            setFilter('all');
          }}
        >
          <Tab value="trailers" label={`Trailers (${count('trailers', 'all')})`} />
          <Tab value="trucks" label={`Trucks (${count('trucks', 'all')})`} />
          <Tab value="drivers" label={`Drivers (${count('drivers', 'all')})`} />
        </Tabs>
        <Box sx={{ flexGrow: 1 }} />
        <TextField
          size="small"
          placeholder={kind === 'drivers' ? 'Driver, truck or load' : `${kind === 'trucks' ? 'Truck' : 'Trailer'} #, load or invoice`}
          value={q}
          onChange={(e) => setQ(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search fontSize="small" />
              </InputAdornment>
            ),
          }}
        />
        <Tooltip title="Refresh">
          <IconButton onClick={refresh}>
            <Refresh />
          </IconButton>
        </Tooltip>
      </Stack>
      <Stack direction="row" spacing={1} sx={{ px: 2, pb: 1.5 }} flexWrap="wrap" useFlexGap>
        {FILTERS[kind].map((f) => (
          <Chip
            key={f.key}
            label={`${f.label} (${count(kind, f.key)})`}
            color={filter === f.key ? 'primary' : 'default'}
            variant={filter === f.key ? 'filled' : 'outlined'}
            onClick={() => setFilter(f.key)}
          />
        ))}
      </Stack>
      {fetching && <LinearProgress />}

      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>{kind === 'trucks' ? 'Truck' : kind === 'trailers' ? 'Trailer' : 'Driver'}</TableCell>
            <TableCell>Now</TableCell>
            <TableCell>{kind === 'trucks' ? 'Assigned driver(s)' : kind === 'trailers' ? 'Last gate record' : 'Truck'}</TableCell>
            <TableCell>Load</TableCell>
            <TableCell align="right" />
          </TableRow>
        </TableHead>
        <TableBody>
          {kind === 'trucks' &&
            truckRows.map((t) => {
              const s = truckState(t)!;
              return (
                <TableRow key={t.id} hover>
                  <TableCell>
                    <Typography variant="body2" fontWeight={600}>
                      {t.number}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip size="small" color={s.color} label={t.state === 'free' ? 'Free' : t.state === 'on_load' ? 'On load' : 'Lined up'} />
                  </TableCell>
                  <TableCell>{t.drivers.map((d) => d.name).join(' + ') || <Typography variant="caption" color="text.disabled">No driver in its truck group</Typography>}</TableCell>
                  <TableCell>
                    <LegLink leg={t.leg} onOpen={setOpenLoad} />
                  </TableCell>
                  <TableCell align="right">
                    {t.state === 'free' && (
                      <Button size="small" onClick={() => setUseFor({ label: `truck ${t.number}`, prefill: { truck: t.number, ...(t.drivers[0] ? { driver: t.drivers[0] } : {}), team: t.drivers[1] || null } })}>
                        Use for a waiting load
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              );
            })}
          {kind === 'trailers' &&
            trailerRows.map((t) => {
              const s = trailerState(t)!;
              return (
                <TableRow key={t.id} hover>
                  <TableCell>
                    <Typography variant="body2" fontWeight={600}>
                      {t.number}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {[t.type, t.readiness && t.readiness !== 'not-ready' ? t.readiness : null].filter(Boolean).join(' · ')}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip size="small" color={s.color} label={s.label} sx={{ maxWidth: 280 }} />
                  </TableCell>
                  <TableCell>
                    {t.gate ? (
                      <Typography variant="caption">
                        {t.gate.status === 'entry' ? 'Entered' : 'Left'} {since(t.gate.at)}
                        {t.gate.loaded ? ` · ${t.gate.loaded}` : ''}
                      </Typography>
                    ) : (
                      <Typography variant="caption" color="text.disabled">
                        No gate record
                      </Typography>
                    )}
                  </TableCell>
                  <TableCell>
                    <LegLink leg={t.leg} onOpen={setOpenLoad} />
                  </TableCell>
                  <TableCell align="right">
                    {(t.state === 'in_yard' || t.state === 'unknown') && (
                      <Button size="small" onClick={() => setUseFor({ label: `trailer ${t.number}`, prefill: { trailers: [t.number], loaded: t.gate?.loaded === 'loaded' } })}>
                        Use for a waiting load
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              );
            })}
          {kind === 'drivers' &&
            driverRows.map((d) => {
              const s = driverState(d)!;
              return (
                <TableRow key={d.yardId} hover>
                  <TableCell>
                    <Typography variant="body2" fontWeight={600}>
                      {d.name}
                    </Typography>
                    {!d.profileId && (
                      <Typography variant="caption" color="text.disabled">
                        Not on the app
                      </Typography>
                    )}
                  </TableCell>
                  <TableCell>
                    <Stack direction="row" spacing={0.5}>
                      <Chip size="small" color={s.color} label={d.state === 'free' ? 'Free' : d.state === 'on_load' ? 'On load' : 'Lined up'} />
                      {d.lineup > 0 && <Chip size="small" variant="outlined" label={`${d.lineup} next`} />}
                    </Stack>
                  </TableCell>
                  <TableCell>{d.truck || <Typography variant="caption" color="text.disabled">—</Typography>}</TableCell>
                  <TableCell>
                    <LegLink leg={d.leg} onOpen={setOpenLoad} />
                  </TableCell>
                  <TableCell align="right" sx={{ whiteSpace: 'nowrap' }}>
                    {d.profileId && (
                      <Button size="small" onClick={() => setLineupOf(d.profileId)} data-testid={`lineupBtn-${d.yardId}`}>
                        Lineup{d.lineup ? ` (${d.lineup})` : ''}
                      </Button>
                    )}
                    {d.state === 'free' && d.profileId && (
                      <Button size="small" onClick={() => setUseFor({ label: d.name, prefill: { driver: { id: d.profileId!, name: d.name }, ...(d.truck ? { truck: d.truck } : {}) } })}>
                        Use for a waiting load
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              );
            })}
          {!fetching && (kind === 'trucks' ? truckRows : kind === 'trailers' ? trailerRows : driverRows).length === 0 && (
            <TableRow>
              <TableCell colSpan={5} align="center" sx={{ py: 6, color: 'text.secondary' }}>
                Nothing here
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>

      {/* Pick the load that gets it */}
      <Dialog open={!!useFor} onClose={() => setUseFor(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Use {useFor?.label} for…</DialogTitle>
        <DialogContent dividers sx={{ p: 0 }}>
          {waiting.isFetching && <LinearProgress />}
          <List dense>
            {waitingLegs(waiting.data?.data?.loads || []).map(({ load, leg, canSend }) => {
              const stops = [...(leg.stops || [])].sort((a, b) => a.seq - b.seq);
              return (
                <ListItemButton
                  key={leg.id}
                  onClick={() => {
                    setAssigning({ loadId: load.id, leg, canSend, prefill: useFor!.prefill });
                    setUseFor(null);
                  }}
                >
                  <ListItemText
                    primary={`${load.invoice_no || 'No load #'} · #${leg.trip_no}${legsInOrder(load.legs).length > 1 ? ` (leg ${leg.leg_no})` : ''}`}
                    secondary={`${stops[0]?.city || '—'}, ${stops[0]?.state || ''} → ${stops[stops.length - 1]?.city || '—'}, ${stops[stops.length - 1]?.state || ''} · ${
                      load.status === 'transfer' ? 'ready to transfer' : leg.driver_profile_id ? 'driver set' : 'no driver yet'
                    }`}
                  />
                </ListItemButton>
              );
            })}
            {!waiting.isFetching && !waitingLegs(waiting.data?.data?.loads || []).length && (
              <Typography variant="body2" color="text.secondary" sx={{ p: 3, textAlign: 'center' }}>
                No load is waiting for a driver, truck or trailer
              </Typography>
            )}
          </List>
        </DialogContent>
      </Dialog>
      <AssignLegDialog
        open={!!assigning}
        onClose={() => setAssigning(null)}
        loadId={assigning?.loadId || 0}
        leg={assigning?.leg || null}
        canSend={!!assigning?.canSend}
        prefill={assigning?.prefill}
      />
      <LoadDrawer loadId={openLoad} onClose={() => setOpenLoad(null)} />
      <LineupDrawer profileId={lineupOf} onClose={() => setLineupOf(null)} />
    </Card>
  );
}
