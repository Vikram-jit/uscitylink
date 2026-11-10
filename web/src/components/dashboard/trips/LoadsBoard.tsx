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
import { Add, Refresh, Search, Visibility } from '@mui/icons-material';
import { toast } from 'react-toastify';

import { useSocketEvent } from '@/hooks/use-socket-event';
import { Trip, useGetLoadsQuery, useSendTripMutation, useTripActionMutation } from '@/redux/TripApiSlice';

import { LoadFormDialog } from './LoadFormDialog';
import { TripDrawer } from './TripDrawer';
import { appointment, firstLast, isLate, STATUS, TABS, tabOf, tripLabel } from './tripFormat';

// Dispatch's Loads screen: every load with its truck and driver, lined up / waiting / on the road /
// delivered, and Send (or Confirm & send when the driver is waiting) straight to the driver's chat.

const WIDE = { display: { xs: 'none', md: 'table-cell' } } as const;

export function LoadsBoard(): React.JSX.Element {
  const [tab, setTab] = React.useState('all');
  const [q, setQ] = React.useState('');
  const [query, setQuery] = React.useState('');
  const [page, setPage] = React.useState(0);
  const [adding, setAdding] = React.useState(false);
  const [openTrip, setOpenTrip] = React.useState<number | null>(null);
  const limit = 25;

  const status = TABS.find((t) => t.key === tab)?.status || '';
  const { data, isFetching, refetch } = useGetLoadsQuery({ status: status || undefined, q: query || undefined, page: page + 1, limit });
  const waiting = useGetLoadsQuery({ status: 'offered', limit: 1 });
  const [sendTrip, { isLoading: sending }] = useSendTripMutation();
  const [tripAction, { isLoading: completing }] = useTripActionMutation();

  // Search after typing stops
  React.useEffect(() => {
    const t = setTimeout(() => {
      setQuery(q.trim());
      setPage(0);
    }, 350);
    return () => clearTimeout(t);
  }, [q]);

  // Live: any trip change refreshes the list; a driver waiting for a load is called out
  const refresh = React.useCallback(() => {
    void refetch();
    void waiting.refetch();
  }, [refetch, waiting]);
  useSocketEvent('trip:updated', refresh);
  useSocketEvent<[any]>('trip:offer', (d) => {
    refresh();
    toast.warning(`${d?.driverName || 'A driver'}${d?.truck ? ` (truck ${d.truck})` : ''} is waiting for the next load — confirm it`, {
      onClick: () => d?.tripId && setOpenTrip(Number(d.tripId)),
      autoClose: 15000,
    });
  });
  useSocketEvent<[any]>('trip:no_load', (d) => {
    toast.info(`${d?.driverName || 'A driver'}${d?.truck ? ` (truck ${d.truck})` : ''} asked for a next load — none is lined up`, { autoClose: 15000 });
  });
  useSocketEvent<[any]>('trip:problem', (d) => {
    refresh();
    toast.error(`Problem on trip #${d?.tripNo || d?.tripId}: ${d?.note || d?.kind || ''}`, { onClick: () => d?.tripId && setOpenTrip(Number(d.tripId)) });
  });

  const trips = data?.data?.trips || [];
  const names = data?.data?.driverNames || {};
  const waitingCount = waiting.data?.data?.total || 0;
  const counts = data?.data?.counts || {};
  const tabCount = (status: string) =>
    status ? status.split(',').reduce((sum, st) => sum + (counts[st] || 0), 0) : Object.values(counts).reduce((a, b) => a + b, 0);

  const send = async (trip: Trip) => {
    try {
      await sendTrip(trip.id).unwrap();
      toast.success(`Trip ${tripLabel(trip)} sent to ${names[trip.driver_profile_id || ''] || 'the driver'}`);
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not send');
    }
  };

  // Delivered by the driver → dispatch confirms: the trip leaves the driver's app and is ready to price
  const complete = async (trip: Trip) => {
    try {
      await tripAction({ id: trip.id, action: 'complete' }).unwrap();
      toast.success(`Trip ${tripLabel(trip)} completed — Route List entry created, off the driver's app`);
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not complete');
    }
  };

  return (
    <Card>
      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ p: 2 }} alignItems={{ sm: 'center' }}>
        <TextField
          size="small"
          placeholder="Truck #, driver or trip #"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          sx={{ flexGrow: 1, maxWidth: { sm: 360 } }}
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
        {TABS.map((t) => (
          <Tab
            key={t.key}
            value={t.key}
            label={
              t.key === 'waiting' && waitingCount ? (
                <Box component="span" sx={{ color: 'warning.main', fontWeight: 700 }}>
                  {`${t.label} (${waitingCount})`}
                </Box>
              ) : (
                `${t.label} (${tabCount(t.status)})`
              )
            }
          />
        ))}
      </Tabs>
      {isFetching && <LinearProgress />}
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Trip</TableCell>
            <TableCell>Truck · Driver</TableCell>
            <TableCell>Route</TableCell>
            <TableCell sx={WIDE}>Appointment</TableCell>
            <TableCell>Status</TableCell>
            <TableCell align="right" />
          </TableRow>
        </TableHead>
        <TableBody>
          {trips.map((t) => {
            const { first, last, count } = firstLast(t);
            const late = isLate(t);
            return (
              <TableRow key={t.id} hover sx={{ cursor: 'pointer' }} onClick={() => setOpenTrip(t.id)}>
                <TableCell>
                  <Typography variant="body2" fontWeight={600}>
                    {tripLabel(t)}
                  </Typography>
                  {t.route_trip_no && (
                    <Typography variant="caption" color="success.main" component="div">
                      Route List {t.route_trip_no}
                    </Typography>
                  )}
                  {t.source === 'typed' && (
                    <Typography variant="caption" color="text.secondary" component="div">
                      from chat
                    </Typography>
                  )}
                </TableCell>
                <TableCell>
                  <Typography variant="body2">{t.truck_number ? `Truck ${t.truck_number}` : '—'}</Typography>
                  <Typography variant="caption" color="text.secondary">
                    {names[t.driver_profile_id || ''] || '—'}
                    {t.driver_id_2 ? ' + team' : ''}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {first ? `${first.city}, ${first.state}` : '—'} → {last ? `${last.city}, ${last.state}` : '—'}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {count} stop{count === 1 ? '' : 's'}
                    {last?.name ? ` · ${last.name}` : ''}
                  </Typography>
                </TableCell>
                <TableCell sx={WIDE}>{appointment(last?.appointment_local)}</TableCell>
                <TableCell>
                  <Stack direction="row" spacing={0.5} flexWrap="wrap" useFlexGap>
                    <Chip size="small" label={STATUS[t.status].label} color={STATUS[t.status].color} />
                    {late && <Chip size="small" color="error" variant="outlined" label="Late" />}
                    {t.needs_review && <Chip size="small" color="warning" variant="outlined" label="Check" />}
                  </Stack>
                </TableCell>
                <TableCell align="right" onClick={(e) => e.stopPropagation()}>
                  {(t.status === 'scheduled' || t.status === 'offered') && (
                    <Button size="small" variant={t.status === 'offered' ? 'contained' : 'outlined'} color={t.status === 'offered' ? 'warning' : 'primary'} disabled={sending} onClick={() => void send(t)}>
                      {t.status === 'offered' ? 'Confirm & send' : 'Send'}
                    </Button>
                  )}
                  {(t.status === 'ended' || t.status === 'paperwork') && (
                    <Button size="small" variant="contained" color="success" disabled={completing} onClick={() => void complete(t)}>
                      Mark completed
                    </Button>
                  )}
                  <Tooltip title="Open">
                    <IconButton size="small" onClick={() => setOpenTrip(t.id)}>
                      <Visibility fontSize="small" />
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            );
          })}
          {!trips.length && !isFetching && (
            <TableRow>
              <TableCell colSpan={6} align="center" sx={{ py: 6, color: 'text.secondary' }}>
                {tab === 'all' && !query ? 'No loads yet — use Add load, or the truck button in a driver\'s chat' : 'No loads here'}
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
        onSaved={(trip) => {
          // Show the load where it landed (Scheduled when saved for later, Active when sent)
          setTab(tabOf(trip.status));
          setPage(0);
          setOpenTrip(trip.id);
        }}
      />
      <TripDrawer tripId={openTrip} onClose={() => setOpenTrip(null)} />
    </Card>
  );
}
