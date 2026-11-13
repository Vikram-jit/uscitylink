'use client';

import * as React from 'react';
import {
  Box,
  Button,
  Card,
  Chip,
  IconButton,
  InputAdornment,
  LinearProgress,
  Stack,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TablePagination,
  TableRow,
  Tabs,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import { Add, LocalParking, Refresh, Search, Visibility } from '@mui/icons-material';
import { toast } from 'react-toastify';

import { useSocketEvent } from '@/hooks/use-socket-event';
import { Load, Trip, useGetMissedLoadsQuery, useListLoadBoardQuery, useSendTripMutation } from '@/redux/TripApiSlice';

import { AssignLegDialog } from './AssignLegDialog';
import { CompleteTripButton } from './CompleteTripButton';
import { LegChain } from './LegChain';
import { LoadDrawer } from './LoadDrawer';
import { LineupDrawer } from './LineupDrawer';
import { LoadFormDialog } from './LoadFormDialog';
import { MissedLoadsDialog } from './MissedLoadsDialog';
import { appointment, currentLeg, isLate, legsInOrder, LOAD_STATUS, LOAD_TABS, LOAD_TYPE } from './tripFormat';

// Dispatch's Loads screen. A load is tracked by its invoice # and moved by one or more legs (direct,
// via our yard, relay, trailer move). Loads that need dispatch come first: a driver waiting for a
// confirm, and loads sitting in the yard / at a meet point waiting for the next driver. Each row has
// the one button it needs now.

const WIDE = { display: { xs: 'none', md: 'table-cell' } } as const;

/** When the load was added: "Nov 12, 2026" / "3:40 PM" */
const created = (iso: string | null | undefined, part: 'date' | 'time') =>
  iso
    ? new Intl.DateTimeFormat('en-US', part === 'date' ? { month: 'short', day: 'numeric', year: 'numeric' } : { hour: 'numeric', minute: '2-digit' }).format(new Date(iso))
    : '—';
const HANDED_OVER = ['ended', 'paperwork', 'completed', 'routed'];

/** What dispatch does next on this load, and on which leg */
function nextAction(load: Load): { kind: 'assign' | 'send' | 'confirm' | 'complete'; leg: Trip; isLast: boolean } | null {
  const legs = legsInOrder(load.legs).filter((l) => l.status !== 'cancelled');
  const last = legs[legs.length - 1];
  const offered = legs.find((l) => l.status === 'offered');
  if (offered) return { kind: offered.driver_profile_id ? 'confirm' : 'assign', leg: offered, isLast: offered.id === last?.id };
  const ready = legs.find((l, i) => l.status === 'scheduled' && (i === 0 || HANDED_OVER.includes(legs[i - 1].status)));
  if (ready) return { kind: ready.driver_profile_id ? 'send' : 'assign', leg: ready, isLast: ready.id === last?.id };
  const done = legs.find((l) => l.status === 'ended' || l.status === 'paperwork');
  if (done) return { kind: 'complete', leg: done, isLast: done.id === last?.id };
  return null;
}

export function LoadsBoard(): React.JSX.Element {
  const [tab, setTab] = React.useState('all');
  const [q, setQ] = React.useState('');
  const [query, setQuery] = React.useState('');
  const [page, setPage] = React.useState(0);
  const [adding, setAdding] = React.useState(false);
  // Chat load messages not in Loads (or in with wrong details) — the badge on the Missed loads button
  const [missedOpen, setMissedOpen] = React.useState(false);
  const missed = (useGetMissedLoadsQuery(14, { pollingInterval: 300_000 }).data?.data || []).length;
  const [openLoad, setOpenLoad] = React.useState<number | null>(null);
  const [lineupOf, setLineupOf] = React.useState<string | null>(null);
  const [assigning, setAssigning] = React.useState<{ loadId: number; leg: Trip; canSend: boolean } | null>(null);
  const limit = 25;

  const status = LOAD_TABS.find((t) => t.key === tab)?.status || '';
  const { data, isFetching, refetch } = useListLoadBoardQuery({ status: status || undefined, q: query || undefined, page: page + 1, limit });
  const [sendTrip, { isLoading: sending }] = useSendTripMutation();

  // Search after typing stops
  React.useEffect(() => {
    const t = setTimeout(() => {
      setQuery(q.trim());
      setPage(0);
    }, 350);
    return () => clearTimeout(t);
  }, [q]);

  // Live: any trip change refreshes the list; drivers waiting / loads ready to transfer are called out
  const refresh = React.useCallback(() => void refetch(), [refetch]);
  useSocketEvent('trip:updated', refresh);
  useSocketEvent('load:updated', refresh);
  useSocketEvent<[any]>('trip:offer', (d) => {
    refresh();
    toast.warning(`${d?.driverName || 'A driver'}${d?.truck ? ` (truck ${d.truck})` : ''} is waiting for the next load — confirm it`, { autoClose: 15000 });
  });
  useSocketEvent<[any]>('load:transfer', (d) => {
    refresh();
    toast.warning(`Load ${d?.tripNo} is ${d?.atYard ? 'in the yard' : 'at the meet point'} — assign the next driver`, {
      onClick: () => d?.loadId && setOpenLoad(Number(d.loadId)),
      autoClose: 15000,
    });
  });
  useSocketEvent<[any]>('trip:no_load', (d) => {
    toast.info(`${d?.driverName || 'A driver'}${d?.truck ? ` (truck ${d.truck})` : ''} asked for a next load — none is lined up`, { autoClose: 15000 });
  });
  useSocketEvent<[any]>('trip:problem', (d) => {
    refresh();
    toast.error(`Problem on trip #${(d?.tripNo) || d?.tripId}: ${d?.note || d?.kind || ''}`);
  });

  const loads = data?.data?.loads || [];
  const names = data?.data?.driverNames || {};
  const counts = data?.data?.counts || {};
  const tabCount = (st: string) => (st ? st.split(',').reduce((sum, x) => sum + (counts[x] || 0), 0) : Object.values(counts).reduce((a, b) => a + b, 0));

  const send = async (leg: Trip) => {
    try {
      await sendTrip(leg.id).unwrap();
      toast.success(`Trip #${leg.trip_no} sent to ${names[leg.driver_profile_id || ''] || 'the driver'}`);
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not send');
    }
  };

  return (
    <Card>
      <MissedLoadsDialog open={missedOpen} onClose={() => setMissedOpen(false)} />
      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ p: 2 }} alignItems={{ sm: 'center' }}>
        <TextField
          size="small"
          placeholder="Load #, truck, trailer or driver"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          sx={{ flexGrow: 1, maxWidth: { sm: 420 } }}
          inputProps={{ 'data-testid': 'loadSearch' }}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search fontSize="small" />
              </InputAdornment>
            ),
          }}
        />
        <Box sx={{ flexGrow: 1 }} />
        <Tooltip title="Refresh">
          <IconButton onClick={refresh}>
            <Refresh />
          </IconButton>
        </Tooltip>
        <Button variant="outlined" color={missed ? 'warning' : 'inherit'} onClick={() => setMissedOpen(true)} data-testid="missedLoadsButton">
          Missed loads{missed ? ` (${missed})` : ''}
        </Button>
        <Button variant="contained" startIcon={<Add />} onClick={() => setAdding(true)}>
          Add load
        </Button>
      </Stack>
      <Tabs
        value={tab}
        onChange={(_, v) => {
          setTab(v);
          setPage(0);
        }}
        variant="scrollable"
        sx={{ px: 2 }}
      >
        {LOAD_TABS.map((t) => {
          const n = tabCount(t.status);
          const urgent = (t.key === 'waiting' || t.key === 'transfer') && n > 0;
          return (
            <Tab
              key={t.key}
              value={t.key}
              label={
                urgent ? (
                  <Box component="span" sx={{ color: 'warning.main', fontWeight: 700 }}>
                    {`${t.label} (${n})`}
                  </Box>
                ) : (
                  `${t.label} (${n})`
                )
              }
            />
          );
        })}
      </Tabs>
      {isFetching && <LinearProgress />}
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Load #</TableCell>
            <TableCell sx={WIDE}>Created</TableCell>
            <TableCell>Legs</TableCell>
            <TableCell sx={WIDE}>Route</TableCell>
            <TableCell sx={WIDE}>Delivery appt</TableCell>
            <TableCell>Status</TableCell>
            <TableCell align="right" />
          </TableRow>
        </TableHead>
        <TableBody>
          {loads.map((load) => {
            const legs = legsInOrder(load.legs).filter((l) => l.status !== 'cancelled');
            const stops = legs.flatMap((l) => [...(l.stops || [])].sort((a, b) => a.seq - b.seq));
            const first = stops[0];
            const last = stops[stops.length - 1];
            const leg = currentLeg(load.legs);
            const late = legs.some(isLate);
            const atYard = legs.filter((l) => l.ends_at_yard && l.ended_at).length;
            const action = nextAction(load);
            const st = LOAD_STATUS[load.status];
            return (
              <TableRow key={load.id} hover sx={{ cursor: 'pointer' }} onClick={() => setOpenLoad(load.id)} data-testid={`loadRow-${load.id}`}>
                <TableCell>
                  <Typography variant="body2" fontWeight={700}>
                    Load {load.invoice_no || load.load_no}
                  </Typography>
                  <Typography variant="caption" color="text.secondary" component="div">
                    {LOAD_TYPE[load.type].short}
                    {legs.length > 1 ? ` · ${legs.length} legs` : ''}
                  </Typography>
                  <Typography variant="caption" color="text.secondary" component="div" sx={{ display: { xs: 'block', md: 'none' } }}>
                    Created {created(load.created_at, 'date')}, {created(load.created_at, 'time')}
                  </Typography>
                </TableCell>
                <TableCell sx={WIDE} data-testid="loadCreated">
                  <Typography variant="body2" sx={{ whiteSpace: 'nowrap' }}>
                    {created(load.created_at, 'date')}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {created(load.created_at, 'time')}
                  </Typography>
                </TableCell>
                <TableCell>
                  <LegChain legs={load.legs} names={names} dense />
                </TableCell>
                <TableCell sx={WIDE}>
                  <Typography variant="body2">
                    {first ? `${first.city}, ${first.state}` : '—'} → {last ? `${last.city}, ${last.state}` : '—'}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {last?.name || ''}
                    {atYard ? ` · yard ×${atYard}` : ''}
                  </Typography>
                </TableCell>
                <TableCell sx={WIDE}>{appointment(last?.appointment_local)}</TableCell>
                <TableCell>
                  <Stack direction="row" spacing={0.5} flexWrap="wrap" useFlexGap>
                    <Chip size="small" label={st.label} color={st.color} icon={load.status === 'transfer' ? <LocalParking /> : undefined} />
                    {legs.length > 1 && leg && <Chip size="small" variant="outlined" label={`Leg ${leg.leg_no}/${legs.length}`} />}
                    {leg && ['scheduled', 'offered'].includes(leg.status) && leg.driver_profile_id && leg.queue_pos && (
                      <Chip
                        size="small"
                        color="info"
                        variant="outlined"
                        label={`#${leg.queue_pos} for ${(names[leg.driver_profile_id] || 'driver').split(' ')[0]}`}
                        onClick={(e) => {
                          e.stopPropagation();
                          setLineupOf(leg.driver_profile_id);
                        }}
                        data-testid="lineupChip"
                      />
                    )}
                    {late && <Chip size="small" color="error" variant="outlined" label="Late" />}
                    {legs.some((l) => l.needs_review) && <Chip size="small" color="warning" variant="outlined" label="Check" />}
                  </Stack>
                </TableCell>
                <TableCell align="right" onClick={(e) => e.stopPropagation()} sx={{ whiteSpace: 'nowrap' }}>
                  {action?.kind === 'assign' && (
                    <Button
                      size="small"
                      variant="contained"
                      color="warning"
                      onClick={() => setAssigning({ loadId: load.id, leg: action.leg, canSend: true })}
                    >
                      Assign driver
                    </Button>
                  )}
                  {(action?.kind === 'send' || action?.kind === 'confirm') && (
                    <Button
                      size="small"
                      variant={action.kind === 'confirm' ? 'contained' : 'outlined'}
                      color={action.kind === 'confirm' ? 'warning' : 'primary'}
                      disabled={sending}
                      onClick={() => void send(action.leg)}
                    >
                      {action.kind === 'confirm' ? 'Confirm & send' : legs.length > 1 ? `Send leg ${action.leg.leg_no}` : 'Send'}
                    </Button>
                  )}
                  {action?.kind === 'complete' && <CompleteTripButton trip={action.leg} size="small" requireInvoice={action.isLast} legs={load.legs} names={names} />}
                  <Tooltip title="Open">
                    <IconButton size="small" onClick={() => setOpenLoad(load.id)}>
                      <Visibility fontSize="small" />
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            );
          })}
          {!loads.length && !isFetching && (
            <TableRow>
              <TableCell colSpan={7} align="center" sx={{ py: 6, color: 'text.secondary' }}>
                {tab === 'all' && !query ? "No loads yet — use Add load, or the truck button in a driver's chat" : 'No loads here'}
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
      <TablePagination
        component="div"
        count={data?.data?.total || 0}
        page={page}
        onPageChange={(_, p) => setPage(p)}
        rowsPerPage={limit}
        rowsPerPageOptions={[limit]}
      />
      <LoadFormDialog
        open={adding}
        onClose={() => setAdding(false)}
        onSaved={() => {
          setTab('all');
          setPage(0);
        }}
      />
      <AssignLegDialog
        open={!!assigning}
        onClose={() => setAssigning(null)}
        loadId={assigning?.loadId || 0}
        leg={assigning?.leg || null}
        canSend={!!assigning?.canSend}
        driverName={assigning?.leg.driver_profile_id ? names[assigning.leg.driver_profile_id] : null}
      />
      <LoadDrawer loadId={openLoad} onClose={() => setOpenLoad(null)} />
      <LineupDrawer profileId={lineupOf} onClose={() => setLineupOf(null)} />
    </Card>
  );
}
