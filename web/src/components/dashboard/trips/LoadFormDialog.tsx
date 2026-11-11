'use client';

import * as React from 'react';
import {
  LoadType,
  StopInput,
  Trip,
  useAddLoadLegMutation,
  useCreateLoadWithLegsMutation,
  useEditTripMutation,
  useLazyGetDriverAssignmentQuery,
  useLazyGetYardStopQuery,
  useParseTripTextMutation,
} from '@/redux/TripApiSlice';
import type { SvgIconComponent } from '@mui/icons-material';
import {
  Add,
  Close,
  ContentCopy,
  ContentPaste,
  FormatListNumbered,
  Delete,
  LocalParking,
  LocalShipping,
  RvHookup,
  Send,
  SwapHoriz,
  Warehouse,
} from '@mui/icons-material';
import {
  Alert,
  alpha,
  Box,
  Button,
  ButtonBase,
  Chip,
  Collapse,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Grid,
  IconButton,
  Paper,
  Stack,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import { toast } from 'react-toastify';

import { LineupDrawer } from './LineupDrawer';
import { emptyStop, legBody, LegEditor, LegState, newLeg, Person } from './LegEditor';
import { LOAD_TYPE } from './tripFormat';

// Add a load (Loads screen) or send one from a driver's chat. A load is tracked by its invoice # and
// moved by one or more legs:
//   Direct        one driver, pickup → delivery
//   Via our yard  leg 1 drops the trailer at the yard, leg 2 (same or another driver / truck) delivers
//   Relay         leg 1 meets leg 2's driver on the road, leg 2 delivers
//   Trailer move  move a trailer from → to
// Later legs can be saved with "assign later" and get a driver when the load is ready to transfer.
// Also: edit one leg (trip panel) and add a leg to a load (load panel).

interface Props {
  open: boolean;
  onClose: () => void;
  /** Editing one leg (a trip) that isn't closed */
  trip?: Trip | null;
  /** Opened from a driver's chat */
  driver?: Person | null;
  /** Adding a leg to this load; it starts where the load's last leg ends */
  addLegTo?: { loadId: number; startsAt: StopInput | null } | null;
  onSaved?: () => void;
}

const TYPE_ICON: Record<LoadType, SvgIconComponent> = {
  direct: LocalShipping,
  via_yard: Warehouse,
  relay: SwapHoriz,
  trailer_move: RvHookup,
};
const TYPE_HINT: Record<LoadType, string> = {
  direct: 'One driver, pickup to delivery',
  via_yard: 'Drop at our yard, next driver delivers',
  relay: 'Swap drivers at a meet point',
  trailer_move: 'Move a trailer from A to B',
};

const isHandover = (s?: StopInput) => !!s && (s.type === 'yard' || s.type === 'switch');

/** Rebuild the legs for a load type, keeping the people of leg 1 / leg 2 and the customer stops. */
function legsForType(type: LoadType, legs: LegState[], yard: StopInput | null): LegState[] {
  const all = legs.flatMap((l) => l.stops);
  const pickups = all.filter((s) => s.type === 'pickup');
  const drops = all.filter((s) => s.type === 'drop');
  const p = pickups.length ? pickups : [emptyStop('pickup')];
  const d = drops.length ? drops : [emptyStop('drop')];
  const first = legs[0] || newLeg([]);
  if (type === 'direct' || type === 'trailer_move') return [{ ...first, stops: [...p, ...d] }];
  const existing = all.find((s) => s.type === (type === 'via_yard' ? 'yard' : 'switch'));
  const hand: StopInput =
    existing ||
    (type === 'via_yard' ? { ...(yard || emptyStop('yard')), type: 'yard', appointment: '' } : emptyStop('switch'));
  const second = legs[1] || newLeg([], { loaded: true });
  return [
    { ...first, stops: [...p, hand] },
    { ...second, stops: d },
  ];
}

const fromTrip = (trip: Trip, driver?: Person | null): LegState =>
  newLeg(
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
      })),
    {
      driver: driver || (trip.driver_profile_id ? { id: trip.driver_profile_id, name: 'Current driver' } : null),
      truck: trip.truck_number || '',
      trailers: trip.trailer_numbers ? trip.trailer_numbers.split(/,\s*/).filter(Boolean) : [],
      temperature: trip.temperature || '',
      loaded: !!trip.loaded_trailer,
      notes: trip.notes || '',
    }
  );

export function LoadFormDialog({ open, onClose, trip, driver, addLegTo, onSaved }: Props): React.JSX.Element {
  const editing = !!trip;
  const addingLeg = !!addLegTo;
  const creating = !editing && !addingLeg;
  const [type, setType] = React.useState<LoadType>('direct');
  const [legs, setLegs] = React.useState<LegState[]>([newLeg([emptyStop('pickup'), emptyStop('drop')])]);
  const [invoice, setInvoice] = React.useState('');
  /** Adding a load without an invoice #: ask once — add it, or continue without (needed later to complete) */
  const [askInvoice, setAskInvoice] = React.useState<{ send: boolean } | null>(null);
  const invoiceRef = React.useRef<HTMLInputElement>(null);
  const [pasteOpen, setPasteOpen] = React.useState(false);
  const [pasted, setPasted] = React.useState('');
  const [readNotes, setReadNotes] = React.useState<string[]>([]);
  const [yard, setYard] = React.useState<StopInput | null>(null);
  const [showLineup, setShowLineup] = React.useState(false);

  const [createLoad, { isLoading: savingLoad }] = useCreateLoadWithLegsMutation();
  const [addLeg, { isLoading: addingLegNow }] = useAddLoadLegMutation();
  const [editTrip, { isLoading: savingTrip }] = useEditTripMutation();
  const [parseText, { isLoading: reading }] = useParseTripTextMutation();
  const [lookupDriverTruck] = useLazyGetDriverAssignmentQuery();
  const [loadYard] = useLazyGetYardStopQuery();
  const busy = savingLoad || addingLegNow || savingTrip;

  // Fill from the trip being edited (or reset for a new load / leg) — once per opening
  React.useEffect(() => {
    if (!open) return;
    setReadNotes([]);
    setPasted('');
    setPasteOpen(false);
    if (trip) {
      setType('direct');
      setLegs([fromTrip(trip, driver)]);
      setInvoice(trip.invoice_no || '');
      return;
    }
    setInvoice('');
    setType('direct');
    if (addLegTo) {
      setLegs([newLeg([emptyStop('drop')], { loaded: true })]);
    } else {
      const first = newLeg([emptyStop('pickup'), emptyStop('drop')], { driver: driver || null });
      setLegs([first]);
      // From a driver's chat: their truck and team mate
      if (driver) {
        lookupDriverTruck(driver.id, true)
          .unwrap()
          .then((res) => {
            const a = res.data;
            if (!a) return;
            const mate = a.drivers.find((d) => d.id !== driver.id) || null;
            setLegs((all) =>
              all.map((l, i) => (i === 0 ? { ...l, truck: l.truck || a.truck, team: l.team || mate } : l))
            );
          })
          .catch(() => undefined);
      }
    }
    loadYard()
      .unwrap()
      .then((r) => setYard(r.data))
      .catch(() => undefined);
    // The parent passes a new `driver` object on every render: depend on ids only
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, trip?.id, driver?.id, addLegTo?.loadId]);

  // The driver's name loaded after opening: show it without resetting anything
  React.useEffect(() => {
    if (!driver?.name) return;
    setLegs((all) =>
      all.map((l, i) =>
        i === 0 && l.driver?.id === driver.id ? { ...l, driver: { ...l.driver, name: driver.name } } : l
      )
    );
  }, [driver?.id, driver?.name]);

  const patchLeg = (i: number) => (patch: Partial<LegState>) =>
    setLegs((all) => all.map((l, j) => (j === i ? { ...l, ...patch } : l)));

  const changeType = (t: LoadType | null) => {
    if (!t) return;
    setType(t);
    setLegs((all) => legsForType(t, all, yard));
  };

  const addAnotherLeg = () =>
    setLegs((all) => {
      // The leg that was last now hands over at our yard (dispatch can change it to a meet point)
      const last = all[all.length - 1];
      const lastStop = last.stops[last.stops.length - 1];
      const drops = isHandover(lastStop) ? [] : last.stops.filter((s) => s.type === 'drop');
      const kept = isHandover(lastStop)
        ? last.stops
        : [
            ...last.stops.filter((s) => s.type !== 'drop'),
            { ...(yard || emptyStop('yard')), type: 'yard' as const, appointment: '' },
          ];
      return [
        ...all.slice(0, -1),
        { ...last, stops: kept },
        newLeg(drops.length ? drops : [emptyStop('drop')], { loaded: true }),
      ];
    });

  const removeLeg = (i: number) =>
    setLegs((all) => {
      const next = all.filter((_, j) => j !== i);
      if (next.length === 1) setType('direct');
      return next;
    });

  /** Leg 2+ uses leg 1's driver / truck / trailer (via our yard with the same driver). */
  const sameAsBefore = (i: number) =>
    setLegs((all) =>
      all.map((l, j) =>
        j === i
          ? {
              ...l,
              driver: all[i - 1].driver,
              team: all[i - 1].team,
              truck: all[i - 1].truck,
              trailers: all[i - 1].trailers,
            }
          : l
      )
    );

  const readPasted = async () => {
    try {
      const res = await parseText(pasted).unwrap();
      const l = res.data;
      setType('direct');
      setLegs((all) => [
        {
          ...all[0],
          stops: l.stops.map((s) => ({ ...s, appointment: s.appointment || '' })),
          ...(l.truck ? { truck: l.truck } : {}),
          ...(l.trailers.length ? { trailers: l.trailers } : {}),
          ...(l.temperature ? { temperature: l.temperature } : {}),
          loaded: l.loadedTrailer,
        },
      ]);
      setReadNotes([
        ...l.reasons,
        ...(l.team.length > 1 ? [`Team in the text: ${l.team.join(' + ')} — pick the second driver below`] : []),
      ]);
      setPasteOpen(false);
      toast.success('Load read — check the fields');
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not read that text');
    }
  };

  const problems = (): string | null => {
    for (let i = 0; i < legs.length; i++) {
      const leg = legs[i];
      const name = legs.length > 1 ? `Leg ${i + 1}: ` : '';
      if (i === 0 && !addingLeg && !leg.driver && !leg.truck.trim())
        return `${name}choose a driver or enter a truck number`;
      if (!leg.stops.length) return `${name}add at least one stop`;
      if (leg.stops.some((s) => !s.city?.trim() || !s.state?.trim())) return `${name}every stop needs a city and state`;
      if (i < legs.length - 1 && !isHandover(leg.stops[leg.stops.length - 1]))
        return `${name}must end at our yard or a meet point (the next leg starts there)`;
    }
    const last = legs[legs.length - 1];
    if (!editing && !last.stops.some((s) => s.type === 'drop')) return 'Add the delivery';
    return null;
  };

  const save = async (send: boolean, withoutInvoice = false) => {
    const problem = problems();
    if (problem) {
      toast.error(problem);
      return;
    }
    if (creating && !invoice.trim() && !withoutInvoice) {
      setAskInvoice({ send });
      return;
    }
    try {
      if (editing) {
        const res = await editTrip({
          id: trip!.id,
          ...legBody(legs[0]),
          invoiceNo: invoice.trim() || null,
          needsReview: false,
        }).unwrap();
        toast.success(res.message || 'Trip updated');
      } else if (addingLeg) {
        const res = await addLeg({ id: addLegTo!.loadId, ...legBody(legs[0]) }).unwrap();
        toast.success(res.message || 'Leg added');
      } else {
        const res = await createLoad({
          type,
          invoiceNo: invoice.trim() || null,
          legs: legs.map(legBody),
          send,
        }).unwrap();
        toast.success(res.message || (send ? 'Load sent to the driver' : 'Load saved'));
      }
      onSaved?.();
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save the load');
    }
  };

  const title = editing
    ? `Edit ${trip?.leg_no && trip.leg_no > 1 ? `leg ${trip.leg_no} · ` : ''}trip #${trip?.trip_no || trip?.id}`
    : addingLeg
      ? 'Add a leg'
      : driver
        ? `Send load to ${driver.name}`
        : 'New load';
  const stopCount = legs.reduce((n, l) => n + l.stops.length, 0);
  const summary = creating
    ? `${LOAD_TYPE[type].label} · ${legs.length} leg${legs.length > 1 ? 's' : ''} · ${stopCount} stop${stopCount === 1 ? '' : 's'}${invoice.trim() ? ` · ${invoice.trim()}` : ''}`
    : '';

  return (
    <Dialog
      open={open}
      onClose={onClose}
      fullWidth
      maxWidth="lg"
      PaperProps={{ sx: { bgcolor: 'background.default' } }}
    >
      <DialogTitle sx={{ bgcolor: 'background.paper', borderBottom: 1, borderColor: 'divider', py: 1.5 }}>
        <Stack direction="row" alignItems="center" spacing={1}>
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            {title}
          </Typography>
          {creating && driver && (
            <Button size="small" startIcon={<FormatListNumbered />} onClick={() => setShowLineup(true)}>
              {driver.name.split(' ')[0]}&apos;s lineup
            </Button>
          )}
          {creating && (
            <Button size="small" startIcon={<ContentPaste />} onClick={() => setPasteOpen((v) => !v)}>
              Paste a typed load
            </Button>
          )}
          <IconButton onClick={onClose} aria-label="Close">
            <Close />
          </IconButton>
        </Stack>
      </DialogTitle>
      <DialogContent sx={{ py: 2.5 }}>
        <Stack spacing={2} sx={{ pt: 2 }}>
          {creating && (
            <Collapse in={pasteOpen} unmountOnExit>
              <Paper variant="outlined" sx={{ p: 2 }}>
                <Stack spacing={1}>
                  <TextField
                    multiline
                    minRows={5}
                    placeholder={'PICK #\nCOLD LINK - ELLISVILLE\n609 DACETOWN RD\nELLISVILLE, MS 39437\n\nDROP #\n…'}
                    value={pasted}
                    onChange={(e) => setPasted(e.target.value)}
                  />
                  <Box>
                    <Button
                      variant="contained"
                      size="small"
                      disabled={!pasted.trim() || reading}
                      onClick={() => void readPasted()}
                    >
                      Read into the form
                    </Button>
                  </Box>
                </Stack>
              </Paper>
            </Collapse>
          )}
          {readNotes.length > 0 && (
            <Alert severity="warning">
              {readNotes.map((n) => (
                <div key={n}>{n}</div>
              ))}
            </Alert>
          )}

          {!addingLeg && (
            <Paper variant="outlined" sx={{ p: 2 }}>
              <Grid container spacing={2} alignItems="flex-start">
                <Grid item xs={12} md={creating ? 3 : 4}>
                  <TextField
                    size="small"
                    fullWidth
                    required
                    inputRef={invoiceRef}
                    label="Invoice #"
                    placeholder="INV-10452"
                    helperText={invoice.trim() ? 'Tracks the load on every leg' : 'Needed to complete the load'}
                    value={invoice}
                    onChange={(e) => setInvoice(e.target.value)}
                    inputProps={{ 'data-testid': 'invoiceInput', maxLength: 64 }}
                  />
                </Grid>
                {creating && (
                  <Grid item xs={12} md={9}>
                    <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr 1fr', md: 'repeat(4, 1fr)' }, gap: 1 }}>
                      {(Object.keys(LOAD_TYPE) as LoadType[]).map((k) => {
                        const Icon = TYPE_ICON[k];
                        const on = type === k;
                        return (
                          <ButtonBase
                            key={k}
                            data-testid={`loadType-${k}`}
                            onClick={() => changeType(k)}
                            sx={{
                              p: 1.25,
                              borderRadius: 2,
                              border: 1.5,
                              borderColor: on ? 'primary.main' : 'divider',
                              bgcolor: on ? (t) => alpha(t.palette.primary.main, 0.06) : 'background.paper',
                              boxShadow: on ? (t) => `0 0 0 3px ${t.palette.primary.main}22` : 'none',
                              justifyContent: 'flex-start',
                              alignItems: 'flex-start',
                              textAlign: 'left',
                              gap: 1,
                              transition: 'all .15s',
                            }}
                          >
                            <Icon sx={{ color: on ? 'primary.main' : 'text.secondary', mt: 0.25 }} />
                            <Box>
                              <Typography variant="body2" fontWeight={700} color={on ? 'primary.main' : 'text.primary'}>
                                {LOAD_TYPE[k].label}
                              </Typography>
                              <Typography
                                variant="caption"
                                color="text.secondary"
                                sx={{ lineHeight: 1.3, display: 'block' }}
                              >
                                {TYPE_HINT[k]}
                              </Typography>
                            </Box>
                          </ButtonBase>
                        );
                      })}
                    </Box>
                  </Grid>
                )}
              </Grid>
            </Paper>
          )}

          {legs.map((leg, i) => {
            const prev = legs[i - 1];
            const prevLast = prev?.stops[prev.stops.length - 1];
            const startsAt = addingLeg ? addLegTo!.startsAt : isHandover(prevLast) ? prevLast : null;
            const multi = legs.length > 1;
            const handover = isHandover(prevLast) ? prevLast : null;
            return (
              <React.Fragment key={leg.key}>
                {i > 0 && handover && (
                  <Stack direction="row" alignItems="center" spacing={1} sx={{ px: 2 }}>
                    <Divider sx={{ flexGrow: 1, borderStyle: 'dashed' }} />
                    <Chip
                      size="small"
                      color="warning"
                      variant="outlined"
                      icon={handover.type === 'yard' ? <LocalParking /> : <SwapHoriz />}
                      label={`${handover.type === 'yard' ? 'Trailer drops at our yard' : 'Hand over at the meet point'}${handover.city ? ` · ${handover.city}, ${handover.state}` : ''} → leg ${i + 1}`}
                    />
                    <Divider sx={{ flexGrow: 1, borderStyle: 'dashed' }} />
                  </Stack>
                )}
                <Paper variant="outlined" sx={{ p: 2 }} data-testid={`leg-${i + 1}`}>
                  {multi && (
                    <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 1.5 }}>
                      <Box
                        sx={{
                          px: 1,
                          py: 0.25,
                          borderRadius: 1,
                          bgcolor: 'primary.main',
                          color: 'primary.contrastText',
                          fontSize: 12,
                          fontWeight: 700,
                        }}
                      >
                        LEG {i + 1}
                      </Box>
                      <Typography variant="body2" color="text.secondary" sx={{ flexGrow: 1 }}>
                        {i === 0 ? 'Pickup' : `From ${handover?.type === 'yard' ? 'our yard' : 'the meet point'}`} →{' '}
                        {i < legs.length - 1
                          ? leg.stops[leg.stops.length - 1]?.type === 'yard'
                            ? 'our yard'
                            : 'meet point'
                          : 'delivery'}
                        {leg.driver ? ` · ${leg.driver.name}` : i > 0 ? ' · driver can be assigned later' : ''}
                      </Typography>
                      {i > 0 && (
                        <Tooltip title="Same driver, truck and trailer as the leg before">
                          <Button
                            size="small"
                            startIcon={<ContentCopy fontSize="small" />}
                            onClick={() => sameAsBefore(i)}
                          >
                            Same as leg {i}
                          </Button>
                        </Tooltip>
                      )}
                      {i > 0 && creating && (
                        <Tooltip title="Remove this leg">
                          <IconButton size="small" onClick={() => removeLeg(i)}>
                            <Delete fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      )}
                    </Stack>
                  )}
                  <LegEditor
                    leg={leg}
                    onChange={patchLeg(i)}
                    startsAt={startsAt}
                    assignLater={i > 0 || addingLeg}
                    loadId={trip?.load_id ?? addLegTo?.loadId ?? null}
                  />
                </Paper>
              </React.Fragment>
            );
          })}
          {creating && type !== 'direct' && type !== 'trailer_move' && (
            <Box>
              <Button size="small" startIcon={<Add />} onClick={addAnotherLeg}>
                Add another leg (e.g. through the yard again)
              </Button>
            </Box>
          )}
        </Stack>
      </DialogContent>
      <DialogActions sx={{ bgcolor: 'background.paper', borderTop: 1, borderColor: 'divider', px: 3, py: 1.5 }}>
        <Typography variant="body2" color="text.secondary" sx={{ flexGrow: 1 }} data-testid="loadFormSummary">
          {summary}
        </Typography>
        <Button onClick={onClose}>Cancel</Button>
        {editing || addingLeg ? (
          <Button variant="contained" disabled={busy} onClick={() => void save(false)}>
            {editing ? 'Save changes' : 'Add leg'}
          </Button>
        ) : (
          <>
            <Button variant="outlined" disabled={busy} onClick={() => void save(false)}>
              Save for later
            </Button>
            <Button
              variant="contained"
              disabled={busy}
              startIcon={<Send fontSize="small" />}
              onClick={() => void save(true)}
            >
              {legs.length > 1 ? 'Send leg 1 now' : 'Send now'}
            </Button>
          </>
        )}
      </DialogActions>

      <Dialog open={!!askInvoice} onClose={() => setAskInvoice(null)} maxWidth="xs" fullWidth>
        <DialogTitle>No invoice # yet</DialogTitle>
        <DialogContent>
          <Typography variant="body2">
            This load has no invoice number. You can add it now, or continue without it — but the load can&apos;t be
            marked completed until the invoice # is added.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => {
              const send = askInvoice?.send ?? false;
              setAskInvoice(null);
              void save(send, true);
            }}
          >
            Continue without
          </Button>
          <Button
            variant="contained"
            onClick={() => {
              setAskInvoice(null);
              setTimeout(() => invoiceRef.current?.focus(), 150);
            }}
          >
            Add invoice #
          </Button>
        </DialogActions>
      </Dialog>
      <LineupDrawer profileId={showLineup && driver ? driver.id : null} onClose={() => setShowLineup(false)} />
    </Dialog>
  );
}
