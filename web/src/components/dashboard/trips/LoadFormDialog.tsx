'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  Collapse,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  IconButton,
  Paper,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import { Close, ContentPaste, FormatListNumbered, Send } from '@mui/icons-material';
import { toast } from 'react-toastify';

import {
  LegBrief,
  LoadLookup,
  Trip,
  useAddSimpleLoadMutation,
  useEditTripMutation,
  useLazyGetDriverAssignmentQuery,
  useLazyLookupLoadNoQuery,
  useParseTripTextMutation,
} from '@/redux/TripApiSlice';

import { LineupDrawer } from './LineupDrawer';
import { emptyStop, legBody, LegEditor, LegState, newLeg, Person } from './LegEditor';
import { STATUS } from './tripFormat';

// Add a load (Loads screen) or send one from a driver's chat — always one simple load:
//   Load # (required) · truck → driver · trailer · stops.
// The Load # decides the rest: a new number is a new load; a number already used is the next leg
// of that load (another driver / truck / trailer). Before anything is ended dispatch is asked:
// the previous leg of this load still open, or the driver already on another load.
// Also: edit one trip (trip / load panel).

interface Props {
  open: boolean;
  onClose: () => void;
  /** Editing one trip that isn't closed */
  trip?: Trip | null;
  /** Opened from a driver's chat */
  driver?: Person | null;
  onSaved?: () => void;
}

type Question = { needs: 'endPrevious'; prev: LegBrief } | { needs: 'driverBusy'; current: LegBrief };

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

const legText = (l: LegBrief) => `${l.driverName || 'no driver'}${l.truck ? ` / truck ${l.truck}` : ''} (${l.from} → ${l.to})`;

/** What the Load # means, under the field */
function LookupNote({ lookup, loading }: { lookup: LoadLookup | null; loading: boolean }) {
  if (loading) return <CircularProgress size={14} />;
  if (!lookup?.loadNo) return null;
  if (!lookup.load) {
    return (
      <Typography variant="caption" color="success.main" data-testid="loadNoNote">
        New load {lookup.loadNo}
      </Typography>
    );
  }
  const prev = lookup.prev;
  return (
    <Alert severity={prev?.open ? 'warning' : 'info'} sx={{ py: 0.25 }} data-testid="loadNoNote">
      Load {lookup.loadNo} already exists — this is <b>leg {lookup.nextLegNo}</b>
      {prev ? (
        <>
          , after {legText(prev)} — {STATUS[prev.status]?.label.toLowerCase() || prev.status}
          {prev.open ? `. ${prev.driverName || 'That leg'} hasn't ended it yet — you'll be asked to end it when you send.` : '.'}
        </>
      ) : (
        '.'
      )}
    </Alert>
  );
}

export function LoadFormDialog({ open, onClose, trip, driver, onSaved }: Props): React.JSX.Element {
  const editing = !!trip;
  const [loadNo, setLoadNo] = React.useState('');
  const [leg, setLeg] = React.useState<LegState>(newLeg([emptyStop('pickup'), emptyStop('drop')]));
  const [pasteOpen, setPasteOpen] = React.useState(false);
  const [pasted, setPasted] = React.useState('');
  const [readNotes, setReadNotes] = React.useState<string[]>([]);
  const [showLineup, setShowLineup] = React.useState(false);
  const [question, setQuestion] = React.useState<Question | null>(null);
  const loadNoRef = React.useRef<HTMLInputElement>(null);

  const [addLoad, { isLoading: adding }] = useAddSimpleLoadMutation();
  const [editTrip, { isLoading: saving }] = useEditTripMutation();
  const [parseText, { isLoading: reading }] = useParseTripTextMutation();
  const [lookupDriverTruck] = useLazyGetDriverAssignmentQuery();
  const [lookupLoad, lookupState] = useLazyLookupLoadNoQuery();
  const busy = adding || saving;
  const lookup = lookupState.data?.data || null;

  // Fill from the trip being edited (or reset for a new load) — once per opening
  React.useEffect(() => {
    if (!open) return;
    setReadNotes([]);
    setPasted('');
    setPasteOpen(false);
    setQuestion(null);
    if (trip) {
      setLeg(fromTrip(trip, driver));
      setLoadNo(trip.invoice_no || '');
      return;
    }
    setLoadNo('');
    setLeg(newLeg([emptyStop('pickup'), emptyStop('drop')], { driver: driver || null }));
    // From a driver's chat: their truck and team mate
    if (driver) {
      lookupDriverTruck(driver.id, true)
        .unwrap()
        .then((res) => {
          const a = res.data;
          if (!a) return;
          const mate = a.drivers.find((d) => d.id !== driver.id) || null;
          setLeg((l) => ({ ...l, truck: l.truck || a.truck, team: l.team || mate }));
        })
        .catch(() => undefined);
    }
    // The parent passes a new `driver` object on every render: depend on ids only
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, trip?.id, driver?.id]);

  // The driver's name loaded after opening: show it without resetting anything
  React.useEffect(() => {
    if (!driver?.name) return;
    setLeg((l) => (l.driver?.id === driver.id ? { ...l, driver: { ...l.driver, name: driver.name } } : l));
  }, [driver?.id, driver?.name]);

  // What the Load # means (new / leg N after …), after typing stops
  React.useEffect(() => {
    if (!open || editing || !loadNo.trim()) return;
    const t = setTimeout(() => void lookupLoad({ no: loadNo.trim(), driver: leg.driver?.id || null }), 400);
    return () => clearTimeout(t);
  }, [open, editing, loadNo, leg.driver?.id, lookupLoad]);

  const readPasted = async () => {
    try {
      const res = await parseText(pasted).unwrap();
      const l = res.data;
      if (l.loadNo) setLoadNo(l.loadNo);
      setLeg((cur) => ({
        ...cur,
        stops: l.stops.map((s) => ({ ...s, appointment: s.appointment || '' })),
        ...(l.truck ? { truck: l.truck } : {}),
        ...(l.trailers.length ? { trailers: l.trailers } : {}),
        ...(l.temperature ? { temperature: l.temperature } : {}),
        loaded: l.loadedTrailer,
      }));
      setReadNotes([
        ...(l.loadNo ? [] : ['No Load # in the text — type it above']),
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
    if (!editing && !loadNo.trim()) return 'Enter the Load # — it’s how the load is tracked';
    if (!leg.driver && !leg.truck.trim()) return 'Choose a driver or enter a truck number';
    if (!leg.stops.length) return 'Add at least one stop';
    if (leg.stops.some((s) => !s.city?.trim() || !s.state?.trim())) return 'Every stop needs a city and state';
    if (!leg.stops.some((s) => s.type === 'drop' || s.type === 'yard' || s.type === 'switch')) return 'Add where it goes';
    return null;
  };

  const save = async (send: boolean, answers: { endPrevious?: boolean; endDriverCurrent?: boolean; lineUp?: boolean } = {}) => {
    const problem = problems();
    if (problem) {
      toast.error(problem);
      if (!loadNo.trim()) loadNoRef.current?.focus();
      return;
    }
    try {
      if (editing) {
        const res = await editTrip({ id: trip!.id, ...legBody(leg), needsReview: false }).unwrap();
        toast.success(res.message || 'Trip updated');
      } else {
        const res = await addLoad({ loadNo: loadNo.trim(), ...legBody(leg), send, ...answers }).unwrap();
        toast.success(res.message || (send ? 'Load sent to the driver' : 'Load saved'));
      }
      setQuestion(null);
      onSaved?.();
      onClose();
    } catch (err: any) {
      // The server asks first before ending anything
      if (err?.status === 409 && err?.data?.needs) {
        const info = err.data.info || {};
        setQuestion(err.data.needs === 'endPrevious' ? { needs: 'endPrevious', prev: info.prev } : { needs: 'driverBusy', current: info.current });
        return;
      }
      toast.error(err?.data?.message || 'Could not save the load');
    }
  };

  // Answering one question can lead to the other (previous leg open AND driver busy): keep earlier answers
  const [given, setGiven] = React.useState<{ endPrevious?: boolean; endDriverCurrent?: boolean; lineUp?: boolean }>({});
  React.useEffect(() => {
    if (open) setGiven({});
  }, [open]);
  const answer = (a: { endPrevious?: boolean; endDriverCurrent?: boolean; lineUp?: boolean }) => {
    const all = { ...given, ...a };
    setGiven(all);
    setQuestion(null);
    void save(true, all);
  };

  const who = leg.driver?.name.split(' (')[0] || 'the driver';
  const title = editing ? `Edit trip #${trip?.trip_no || trip?.id}` : driver ? `Send load to ${driver.name}` : 'New load';

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="lg" PaperProps={{ sx: { bgcolor: 'background.default' } }}>
      <DialogTitle sx={{ bgcolor: 'background.paper', borderBottom: 1, borderColor: 'divider', py: 1.5 }}>
        <Stack direction="row" alignItems="center" spacing={1}>
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            {title}
          </Typography>
          {!editing && driver && (
            <Button size="small" startIcon={<FormatListNumbered />} onClick={() => setShowLineup(true)}>
              {driver.name.split(' ')[0]}&apos;s lineup
            </Button>
          )}
          {!editing && (
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
          {!editing && (
            <Collapse in={pasteOpen} unmountOnExit>
              <Paper variant="outlined" sx={{ p: 2 }}>
                <Stack spacing={1}>
                  <TextField
                    multiline
                    minRows={5}
                    placeholder={'LOAD # 1011\nTRUCK # 101\nPICK #\nCOLD LINK - ELLISVILLE\n609 DACETOWN RD\nELLISVILLE, MS 39437\n\nDROP #\n…'}
                    value={pasted}
                    onChange={(e) => setPasted(e.target.value)}
                  />
                  <Box>
                    <Button variant="contained" size="small" disabled={!pasted.trim() || reading} onClick={() => void readPasted()}>
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

          <Paper variant="outlined" sx={{ p: 2 }}>
            <Grid container spacing={2} alignItems="flex-start">
              <Grid item xs={12} md={4}>
                <TextField
                  size="small"
                  fullWidth
                  required
                  inputRef={loadNoRef}
                  label="Load # / Invoice #"
                  placeholder="1011"
                  disabled={editing}
                  helperText={editing ? 'The load this trip belongs to' : 'Same number again = the next leg of that load'}
                  value={loadNo}
                  onChange={(e) => setLoadNo(e.target.value.toUpperCase())}
                  inputProps={{ 'data-testid': 'loadNoInput', maxLength: 64 }}
                />
              </Grid>
              {!editing && (
                <Grid item xs={12} md={8} sx={{ pt: { md: '22px !important' } }}>
                  <LookupNote lookup={lookup} loading={lookupState.isFetching} />
                </Grid>
              )}
            </Grid>
          </Paper>

          <Paper variant="outlined" sx={{ p: 2 }} data-testid="leg-1">
            <LegEditor leg={leg} onChange={(p) => setLeg((l) => ({ ...l, ...p }))} loadId={trip?.load_id ?? lookup?.load?.id ?? null} />
          </Paper>
        </Stack>
      </DialogContent>
      <DialogActions sx={{ bgcolor: 'background.paper', borderTop: 1, borderColor: 'divider', px: 3, py: 1.5 }}>
        <Typography variant="body2" color="text.secondary" sx={{ flexGrow: 1 }} data-testid="loadFormSummary">
          {!editing && loadNo.trim() ? `Load ${loadNo.trim()}${lookup?.load ? ` · leg ${lookup.nextLegNo}` : ''} · ${leg.stops.length} stops` : ''}
        </Typography>
        <Button onClick={onClose}>Cancel</Button>
        {editing ? (
          <Button variant="contained" disabled={busy} onClick={() => void save(false)}>
            Save changes
          </Button>
        ) : (
          <>
            <Button variant="outlined" disabled={busy} onClick={() => void save(false)}>
              Save for later
            </Button>
            <Button variant="contained" disabled={busy} startIcon={<Send fontSize="small" />} onClick={() => void save(true, given)} data-testid="sendNow">
              Send now
            </Button>
          </>
        )}
      </DialogActions>

      {/* The server asks before ending anything */}
      <Dialog open={!!question} onClose={() => setQuestion(null)} maxWidth="sm" fullWidth>
        {question?.needs === 'endPrevious' && (
          <>
            <DialogTitle>End leg {question.prev.legNo} first?</DialogTitle>
            <DialogContent dividers>
              <Typography variant="body2" data-testid="askEndPrevious">
                <b>{question.prev.driverName || 'The driver'}</b> hasn&apos;t ended leg {question.prev.legNo} of load {loadNo} (#{question.prev.tripNo},{' '}
                {question.prev.from} → {question.prev.to}). End it now and send this leg to <b>{who}</b>?
              </Typography>
              <Typography variant="caption" color="text.secondary" component="div" sx={{ mt: 1 }}>
                {question.prev.driverName || 'The driver'} is told it&apos;s handed over and the load leaves their app. Miles are counted up to now.
              </Typography>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setQuestion(null)}>Cancel</Button>
              <Button variant="contained" color="warning" onClick={() => answer({ endPrevious: true })} data-testid="answerEndPrevious">
                End leg {question.prev.legNo} &amp; send
              </Button>
            </DialogActions>
          </>
        )}
        {question?.needs === 'driverBusy' && (
          <>
            <DialogTitle>{question.current.driverName || 'The driver'} is on another load</DialogTitle>
            <DialogContent dividers>
              <Typography variant="body2" data-testid="askDriverBusy">
                {question.current.driverName || 'The driver'} has load <b>#{question.current.tripNo}</b> ({question.current.from} → {question.current.to},{' '}
                {STATUS[question.current.status]?.label.toLowerCase() || question.current.status}).
              </Typography>
              <Typography variant="body2" sx={{ mt: 1 }}>
                End it now and send this one, or line this one up to go after it?
              </Typography>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setQuestion(null)}>Cancel</Button>
              <Button variant="outlined" onClick={() => answer({ lineUp: true })} data-testid="answerLineUp">
                Line up after #{question.current.tripNo}
              </Button>
              <Button variant="contained" color="warning" onClick={() => answer({ endDriverCurrent: true })} data-testid="answerEndCurrent">
                End #{question.current.tripNo} &amp; send
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>
      <LineupDrawer profileId={showLineup && driver ? driver.id : null} onClose={() => setShowLineup(false)} />
    </Dialog>
  );
}
