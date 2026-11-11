'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Drawer,
  IconButton,
  LinearProgress,
  Stack,
  Tooltip,
  Typography,
} from '@mui/material';
import { Add, ArrowDownward, ArrowUpward, Close, OpenInNew, PersonRemove, WarningAmber } from '@mui/icons-material';
import { toast } from 'react-toastify';

import { LineupLeg, useGetDriverLineupQuery, useRemoveFromDriverLineupMutation, useReorderDriverLineupMutation } from '@/redux/TripApiSlice';

import { LoadDrawer } from './LoadDrawer';
import { LoadFormDialog } from './LoadFormDialog';
import { appointment, STATUS } from './tripFormat';

// A driver's lineup: the load they're on now and the loads lined up after it (#1 is next). When the
// current load is delivered, #1 is offered to the driver — dispatch confirms before it's sent.
// Reorder with the arrows; take a load off the driver; add one at the end.

const when = (iso?: string | null) =>
  iso ? new Intl.DateTimeFormat('en-US', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }).format(new Date(iso)) : '—';

const place = (s: LineupLeg['first']) => (s ? `${s.city || ''}${s.state ? `, ${s.state}` : ''}` || s.name || '—' : '—');

function LegLine({ leg }: { leg: LineupLeg }) {
  return (
    <>
      <Stack direction="row" spacing={1} alignItems="center">
        <Typography variant="body2" fontWeight={700} sx={{ flexGrow: 1 }} noWrap>
          {leg.invoiceNo || 'No invoice #'} · #{leg.tripNo}
          {leg.legCount > 1 ? ` (leg ${leg.legNo}/${leg.legCount})` : ''}
        </Typography>
        <Chip size="small" label={STATUS[leg.status].label} color={STATUS[leg.status].color} />
      </Stack>
      <Typography variant="caption" color="text.secondary" component="div">
        {place(leg.first)} → {place(leg.last)}
        {leg.truck ? ` · truck ${leg.truck}` : ''}
        {leg.trailers ? ` · trailer ${leg.trailers}` : ''}
      </Typography>
      <Typography variant="caption" color="text.secondary" component="div">
        Pickup {appointment(leg.first?.appointmentLocal)} · Delivery {appointment(leg.last?.appointmentLocal)}
      </Typography>
    </>
  );
}

export function LineupDrawer({ profileId, onClose }: { profileId: string | null; onClose: () => void }): React.JSX.Element {
  const { data, isFetching } = useGetDriverLineupQuery(profileId as string, { skip: !profileId });
  const lineup = data?.data;
  const [reorder, { isLoading: saving }] = useReorderDriverLineupMutation();
  const [remove] = useRemoveFromDriverLineupMutation();
  const [order, setOrder] = React.useState<number[]>([]);
  const [openLoad, setOpenLoad] = React.useState<number | null>(null);
  const [adding, setAdding] = React.useState(false);
  const [removing, setRemoving] = React.useState<LineupLeg | null>(null);

  React.useEffect(() => setOrder((lineup?.next || []).map((x) => x.tripId)), [lineup]);
  const items = order.map((id) => lineup?.next.find((x) => x.tripId === id)).filter(Boolean) as NonNullable<typeof lineup>['next'];

  const move = async (i: number, by: number) => {
    if (!profileId) return;
    const next = [...order];
    const [id] = next.splice(i, 1);
    next.splice(i + by, 0, id);
    setOrder(next);
    try {
      await reorder({ profileId, tripIds: next }).unwrap();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save the order');
      setOrder((lineup?.next || []).map((x) => x.tripId));
    }
  };

  const takeOff = async () => {
    if (!profileId || !removing) return;
    try {
      const res = await remove({ profileId, tripId: removing.tripId }).unwrap();
      toast.success(res.message || 'Taken off the lineup');
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not take it off');
    }
    setRemoving(null);
  };

  const name = lineup?.driver.name || 'Driver';

  return (
    <Drawer anchor="right" open={!!profileId} onClose={onClose} sx={{ zIndex: (t) => t.zIndex.modal }} PaperProps={{ sx: { width: { xs: '100%', md: 520 } } }}>
      {(isFetching || saving) && <LinearProgress />}
      <Stack spacing={2} sx={{ p: 2.5 }} data-testid="lineupDrawer">
        <Stack direction="row" alignItems="center">
          <Box sx={{ flexGrow: 1 }}>
            <Typography variant="h6">{name}&apos;s lineup</Typography>
            <Typography variant="caption" color="text.secondary">
              {lineup?.driver.truck ? `Truck ${lineup.driver.truck} · ` : ''}
              {items.length} load{items.length === 1 ? '' : 's'} lined up
            </Typography>
          </Box>
          <IconButton onClick={onClose}>
            <Close />
          </IconButton>
        </Stack>

        <Box>
          <Typography variant="overline" color="text.secondary">
            Now
          </Typography>
          {lineup?.now ? (
            <Box sx={{ p: 1.5, borderRadius: 2, border: 1.5, borderColor: 'primary.main' }} data-testid="lineupNow">
              <LegLine leg={lineup.now} />
              <Stack direction="row" alignItems="center" sx={{ mt: 0.5 }}>
                <Typography variant="caption" color="primary.main" fontWeight={600} sx={{ flexGrow: 1 }}>
                  {lineup.now.finishAt ? `Expected done ${when(lineup.now.finishAt)}` : ''}
                </Typography>
                {lineup.now.loadId && (
                  <Button size="small" startIcon={<OpenInNew fontSize="small" />} onClick={() => setOpenLoad(lineup.now!.loadId)}>
                    Open
                  </Button>
                )}
              </Stack>
            </Box>
          ) : (
            <Box sx={{ p: 1.5, borderRadius: 2, border: 1, borderColor: 'divider', borderStyle: 'dashed' }}>
              <Typography variant="body2" color="success.main" fontWeight={600}>
                Free — not on a load
              </Typography>
            </Box>
          )}
        </Box>

        <Box>
          <Stack direction="row" alignItems="center">
            <Typography variant="overline" color="text.secondary" sx={{ flexGrow: 1 }}>
              Up next
            </Typography>
            <Button size="small" startIcon={<Add />} onClick={() => setAdding(true)}>
              Add a load for {name.split(' ')[0]}
            </Button>
          </Stack>
          <Stack spacing={1}>
            {items.map((item, i) => (
              <Stack
                key={item.tripId}
                direction="row"
                spacing={1.25}
                sx={{ p: 1.25, borderRadius: 2, border: 1, borderColor: item.fit ? 'warning.main' : 'divider', bgcolor: i === 0 ? 'action.hover' : 'background.paper' }}
                data-testid={`lineupItem-${i + 1}`}
              >
                <Box
                  sx={{
                    width: 28,
                    height: 28,
                    flexShrink: 0,
                    borderRadius: '50%',
                    display: 'grid',
                    placeItems: 'center',
                    fontWeight: 700,
                    fontSize: 13,
                    bgcolor: i === 0 ? 'primary.main' : 'action.selected',
                    color: i === 0 ? 'primary.contrastText' : 'text.primary',
                  }}
                >
                  {i + 1}
                </Box>
                <Box sx={{ flexGrow: 1, minWidth: 0 }}>
                  <LegLine leg={item} />
                  {item.blockedBy && (
                    <Typography variant="caption" color="info.main" component="div">
                      Waits for leg {item.blockedBy.legNo} ({item.blockedBy.tripNo}) to be delivered — skipped until then
                    </Typography>
                  )}
                  {item.fit && (
                    <Stack direction="row" spacing={0.5} alignItems="center" sx={{ color: 'warning.dark' }}>
                      <WarningAmber sx={{ fontSize: 15 }} />
                      <Typography variant="caption">{item.fit}</Typography>
                    </Stack>
                  )}
                  <Stack direction="row" spacing={0.5} sx={{ mt: 0.5 }}>
                    {item.loadId && (
                      <Button size="small" startIcon={<OpenInNew fontSize="small" />} onClick={() => setOpenLoad(item.loadId)}>
                        Open
                      </Button>
                    )}
                    <Button size="small" color="inherit" startIcon={<PersonRemove fontSize="small" />} onClick={() => setRemoving(item)} sx={{ color: 'text.secondary' }}>
                      Take off {name.split(' ')[0]}
                    </Button>
                  </Stack>
                </Box>
                <Stack>
                  <Tooltip title="Move up">
                    <span>
                      <IconButton size="small" disabled={i === 0 || saving} onClick={() => void move(i, -1)} aria-label="Move up">
                        <ArrowUpward fontSize="small" />
                      </IconButton>
                    </span>
                  </Tooltip>
                  <Tooltip title="Move down">
                    <span>
                      <IconButton size="small" disabled={i === items.length - 1 || saving} onClick={() => void move(i, 1)} aria-label="Move down">
                        <ArrowDownward fontSize="small" />
                      </IconButton>
                    </span>
                  </Tooltip>
                </Stack>
              </Stack>
            ))}
            {!items.length && !isFetching && (
              <Typography variant="body2" color="text.secondary" sx={{ py: 2, textAlign: 'center' }}>
                Nothing lined up yet
              </Typography>
            )}
          </Stack>
        </Box>
        <Alert severity="info" icon={false}>
          When {name.split(' ')[0]}&apos;s current load is delivered (or they ask in chat), <b>#1</b> is offered to them. You confirm before it&apos;s sent.
        </Alert>
      </Stack>

      <Dialog open={!!removing} onClose={() => setRemoving(null)} maxWidth="xs" fullWidth>
        <DialogTitle>Take #{removing?.tripNo} off {name}?</DialogTitle>
        <DialogContent>
          <Typography variant="body2">The load stays saved and waits for a driver and truck (&quot;assign later&quot;).</Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRemoving(null)}>Keep</Button>
          <Button variant="contained" color="warning" onClick={() => void takeOff()}>
            Take off
          </Button>
        </DialogActions>
      </Dialog>
      <LoadFormDialog open={adding} onClose={() => setAdding(false)} driver={profileId ? { id: profileId, name } : null} />
      <LoadDrawer loadId={openLoad} onClose={() => setOpenLoad(null)} />
    </Drawer>
  );
}
