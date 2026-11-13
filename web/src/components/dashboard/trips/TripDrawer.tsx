'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Button,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Drawer,
  FormControlLabel,
  IconButton,
  MenuItem,
  Stack,
  Switch,
  TextField,
  Typography,
} from '@mui/material';
import { Close } from '@mui/icons-material';
import { toast } from 'react-toastify';

import {
  TripActionName,
  useAddTripProblemMutation,
  useDeclineOfferMutation,
  useGetLoadQuery,
  useResolveTripProblemMutation,
  useSendTripMutation,
  useTripActionMutation,
} from '@/redux/TripApiSlice';

import { CompleteTripButton } from './CompleteTripButton';
import { EndLegDialog, ReleaseLegDialog, ReleaseTarget } from './ReleaseLegDialog';
import { LoadFormDialog } from './LoadFormDialog';
import { TripLivePanel } from './TripLivePanel';
import { appointment, atStop, PROBLEM_KINDS, STATUS, STOP_LABEL, tripLabel } from './tripFormat';

// One trip for dispatch: where it is, every recorded step (who, when, where), problems, and the
// actions dispatch can take — send / confirm, edit, add a problem, hold, mark completed, cancel.

const ACTOR: Record<string, string> = { driver: 'Driver', dispatcher: 'Dispatch', accountant: 'Accountant', ai: 'Assistant', system: 'System' };

const EVENT_TEXT: Record<string, string> = {
  stop_arrived: 'Arrived',
  stop_departed: 'Departed',
  problem: 'Problem',
  problem_resolved: 'Problem resolved',
  edit: 'Edited',
  paperwork: 'Paperwork',
  ai_suggestion: 'Assistant suggestion',
  correction: 'Undone',
  transfer: 'Handed over',
  transfer_undone: 'Handover undone',
  time_correction: 'Times corrected',
  miles: 'Miles',
  offer: 'Offered to the driver',
  note: 'Note',
};

function ask(title: string, label: string, onOk: (text: string) => void, required = true) {
  return { title, label, onOk, required };
}

function Fact({ label, value, warn, testId }: { label: string; value: string; warn?: boolean; testId?: string }): React.JSX.Element {
  return (
    <Box sx={{ minWidth: 0 }} data-testid={testId}>
      <Typography variant="caption" color="text.secondary" sx={{ textTransform: 'uppercase', letterSpacing: 0.6, fontSize: 11 }}>
        {label}
      </Typography>
      <Typography variant="body2" fontWeight={600} color={warn ? 'warning.main' : 'text.primary'} noWrap title={value}>
        {value}
      </Typography>
    </Box>
  );
}

export function TripDrawer({ tripId, onClose }: { tripId: number | null; onClose: () => void }): React.JSX.Element {
  const { data, isFetching } = useGetLoadQuery(tripId as number, { skip: !tripId });
  const trip = data?.data?.trip;
  const driverName = trip?.driver_profile_id ? data?.data?.driverNames?.[trip.driver_profile_id] : null;
  const legInfo = data?.data?.leg;
  const blockedBy = legInfo?.blockedBy || null;

  const [sendTrip, { isLoading: sending }] = useSendTripMutation();
  const [declineOffer] = useDeclineOfferMutation();
  const [tripAction] = useTripActionMutation();
  const [addProblem] = useAddTripProblemMutation();
  const [resolveProblem] = useResolveTripProblemMutation();

  const [editing, setEditing] = React.useState(false);
  const [ending, setEnding] = React.useState(false);
  const [release, setRelease] = React.useState<ReleaseTarget | null>(null);
  const [prompt, setPrompt] = React.useState<ReturnType<typeof ask> | null>(null);
  const [promptText, setPromptText] = React.useState('');
  const [problemOpen, setProblemOpen] = React.useState(false);
  const [problem, setProblem] = React.useState({ kind: 'delay', note: '', amount: '', hold: false });

  const run = async (fn: () => Promise<any>, done?: string) => {
    try {
      const res = await fn();
      toast.success(done || res?.message || 'Done');
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not do that');
    }
  };
  const doAction = (action: TripActionName, note?: string) => run(() => tripAction({ id: trip!.id, action, note }).unwrap());

  const s = trip?.status;
  const stops = [...(trip?.stops || [])].sort((a, b) => a.seq - b.seq);
  const events = trip?.events || [];
  const openProblems = (trip?.problems || []).filter((p) => !p.resolved_at);

  return (
    // On the dialog layer (not the lower drawer layer): opened from the full-screen Loads dialog it must
    // sit above it; its own Edit / Add problem dialogs then open above it in turn
    <Drawer
      anchor="right"
      open={!!tripId}
      onClose={onClose}
      sx={{ zIndex: (theme) => theme.zIndex.modal }}
      PaperProps={{ sx: { width: { xs: '100%', sm: 720, lg: 900 } } }}
    >
      {!trip ? (
        <Box sx={{ p: 4, textAlign: 'center' }}>{isFetching ? <CircularProgress /> : 'Trip not found'}</Box>
      ) : (
        <Stack spacing={2.5} sx={{ p: { xs: 2, sm: 3 } }}>
          <Stack direction="row" alignItems="center" spacing={1} sx={{ position: 'sticky', top: 0, zIndex: 2, bgcolor: 'background.paper', py: 1, mx: { xs: -2, sm: -3 }, px: { xs: 2, sm: 3 }, borderBottom: 1, borderColor: 'divider' }}>
            <Box sx={{ flexGrow: 1, minWidth: 0 }}>
              <Typography variant="overline" color="text.secondary" sx={{ lineHeight: 1.2 }}>
                Trip
              </Typography>
              <Typography variant="h6" noWrap sx={{ lineHeight: 1.2 }}>
                {tripLabel(trip)}
              </Typography>
            </Box>
            <Chip size="small" label={STATUS[trip.status].label} color={STATUS[trip.status].color} sx={{ fontWeight: 700 }} />
            <IconButton onClick={onClose} aria-label="Close">
              <Close />
            </IconButton>
          </Stack>

          <Box
            sx={{
              display: 'grid',
              gap: 1.5,
              gridTemplateColumns: { xs: 'repeat(2, minmax(0, 1fr))', sm: 'repeat(3, minmax(0, 1fr))' },
              p: 2,
              borderRadius: 2,
              border: 1,
              borderColor: 'divider',
              bgcolor: 'action.hover',
            }}
            data-testid="tripSummary"
          >
            <Fact label="Driver" value={`${driverName || 'Driver'}${trip.driver_id_2 ? ' + team' : ''}`} />
            <Fact label="Truck" value={trip.truck_number || '—'} />
            <Fact label="Trailer" value={trip.trailer_numbers || '—'} />
            <Fact label="Load #" value={trip.invoice_no || 'Not added yet'} warn={!trip.invoice_no} testId="tripInvoice" />
            {trip.temperature ? <Fact label="Temperature" value={trip.temperature} /> : null}
            {trip.total_mileage ? <Fact label="Miles" value={`${trip.total_mileage} mi`} /> : null}
            {trip.loaded_trailer ? <Fact label="Trailer" value="Loaded" /> : null}
          </Box>

          {trip.needs_review && (
            <Alert severity="warning">
              Check this load before the driver relies on it:
              {(trip.review_notes || '').split('\n').filter(Boolean).map((n) => (
                <div key={n}>• {n}</div>
              ))}
            </Alert>
          )}
          {blockedBy && (s === 'scheduled' || s === 'offered') && (
            <Alert severity="info" data-testid="legBlocked">
              Goes out after leg {blockedBy.legNo} (#{blockedBy.tripNo}) is {blockedBy.endsAtYard ? 'dropped at the yard' : 'handed over'} — it&apos;s{' '}
              {STATUS[blockedBy.status]?.label.toLowerCase() || blockedBy.status} now. The driver is offered this leg then; you confirm before it&apos;s sent.
              {trip.driver_profile_id && trip.load_id && (
                <Box sx={{ mt: 1 }}>
                  <Button
                    size="small"
                    variant="contained"
                    color="warning"
                    data-testid="tripReleaseBtn"
                    onClick={() =>
                      setRelease({
                        loadId: trip.load_id!,
                        legId: trip.id,
                        tripNo: trip.trip_no,
                        driverName: driverName || 'the driver',
                        prevLegNo: blockedBy.legNo,
                        prevTripNo: blockedBy.tripNo,
                        prevDriver: blockedBy.driverName || 'the driver before',
                        place: blockedBy.place || '',
                      })
                    }
                  >
                    Already handed over? Send to {driverName || 'the driver'} now
                  </Button>
                </Box>
              )}
            </Alert>
          )}
          {s === 'offered' && !blockedBy && <Alert severity="info">The driver is waiting for this load. Confirm to send it to their chat.</Alert>}

          {/* Dispatch actions for this status */}
          <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap sx={{ '& .MuiButton-root': { borderRadius: 2, textTransform: 'none', fontWeight: 600 } }}>
            {(s === 'scheduled' || s === 'offered') && !blockedBy && (
              <Button variant="contained" disabled={sending} onClick={() => void run(() => sendTrip(trip.id).unwrap())}>
                {s === 'offered' ? 'Confirm & send' : 'Send to driver'}
              </Button>
            )}
            {s === 'offered' && (
              <Button onClick={() => void run(() => declineOffer(trip.id).unwrap(), 'Driver told you will update them')}>Not yet</Button>
            )}
            {(s === 'ended' || s === 'paperwork') && (
              <CompleteTripButton trip={trip} requireInvoice={legInfo ? legInfo.isLast : !(trip.ends_at_yard || stops[stops.length - 1]?.type === 'switch')} />
            )}
            {!['completed', 'routed', 'cancelled'].includes(s!) && <Button variant="outlined" onClick={() => setEditing(true)}>Edit</Button>}
            {!['scheduled', 'offered', 'cancelled', 'routed'].includes(s!) && <Button variant="outlined" onClick={() => setProblemOpen(true)}>Add problem</Button>}
            {['planned', 'accepted', 'started', 'rolling', 'ended', 'paperwork'].includes(s!) && (
              <Button variant="outlined" onClick={() => setPrompt(ask('Put the trip on hold', 'Why?', (t) => void doAction('hold', t), false))}>Hold</Button>
            )}
            {s === 'on_hold' && <Button variant="outlined" onClick={() => void doAction('resume')}>Resume</Button>}
            {trip.load_id && ['planned', 'accepted', 'started', 'rolling', 'on_hold'].includes(s!) && (
              <Button variant="outlined" color="warning" onClick={() => setEnding(true)} data-testid="tripEndBtn">
                End load
              </Button>
            )}
            {!['completed', 'routed', 'cancelled'].includes(s!) && (
              <Button variant="outlined" color="error" onClick={() => setPrompt(ask('Cancel this trip', 'Reason (the driver sees it)', (t) => void doAction('cancel', t)))}>
                Cancel trip
              </Button>
            )}
          </Stack>

          {/* Where the truck is and the road ahead, while the load is lined up or on the road */}
          {['planned', 'accepted', 'started', 'rolling', 'on_hold'].includes(s!) && (
            <>
              <Divider />
              <TripLivePanel tripId={trip.id} />
            </>
          )}

          <Divider />
          <Typography variant="subtitle1" fontWeight={700}>
            Stops
          </Typography>
          <Stack spacing={1.25}>
            {stops.map((st, i) => (
              <Box
                key={st.id}
                sx={{ display: 'flex', gap: 1.5, p: 1.5, borderRadius: 2, border: 1, borderColor: 'divider', borderLeftWidth: 4, borderLeftColor: st.departed_at ? 'success.main' : st.arrived_at ? 'warning.main' : 'divider' }}
              >
                <Box sx={{ width: 26, height: 26, flexShrink: 0, borderRadius: '50%', bgcolor: 'action.selected', display: 'grid', placeItems: 'center', fontSize: 13, fontWeight: 700 }}>{i + 1}</Box>
                <Box sx={{ minWidth: 0 }}>
                  <Typography variant="body2" fontWeight={700}>
                    {STOP_LABEL[st.type]} · {st.name || '—'}
                  </Typography>
                  <Typography variant="caption" color="text.secondary" component="div">
                    {[st.street, [st.city, st.state, st.zip].filter(Boolean).join(' ')].filter(Boolean).join(', ')}
                  </Typography>
                  <Stack direction="row" flexWrap="wrap" useFlexGap spacing={0.75} sx={{ mt: 0.75 }}>
                    <Chip size="small" variant="outlined" label={`Appointment ${appointment(st.appointment_local)}`} />
                    <Chip size="small" variant="outlined" color={st.arrived_at ? 'warning' : 'default'} label={`Arrived ${atStop(st.arrived_at, st.timezone)}`} />
                    <Chip size="small" variant="outlined" color={st.departed_at ? 'success' : 'default'} label={`Left ${atStop(st.departed_at, st.timezone)}`} />
                    {st.mileage ? <Chip size="small" variant="outlined" label={`${st.mileage} mi`} /> : null}
                  </Stack>
                </Box>
              </Box>
            ))}
          </Stack>

          {(trip.problems || []).length > 0 && (
            <>
              <Divider />
              <Typography variant="subtitle2">Problems</Typography>
              {(trip.problems || []).map((p) => (
                <Stack key={p.id} direction="row" alignItems="center" spacing={1}>
                  <Chip size="small" color={p.resolved_at ? 'default' : 'error'} label={PROBLEM_KINDS[p.kind] || p.kind} />
                  <Typography variant="body2" sx={{ flexGrow: 1 }}>
                    {p.note || ''}
                    {p.amount ? ` · $${p.amount}` : ''} — {p.opened_by_name || '—'}
                    {p.resolved_at ? ` · resolved by ${p.resolved_by_name || '—'}` : ''}
                  </Typography>
                  {!p.resolved_at && (
                    <Button size="small" onClick={() => void run(() => resolveProblem({ id: trip.id, problemId: p.id }).unwrap())}>
                      Resolve
                    </Button>
                  )}
                </Stack>
              ))}
              {openProblems.length > 0 && s === 'on_hold' && (
                <Typography variant="caption" color="text.secondary">
                  The trip resumes when the last open problem is resolved.
                </Typography>
              )}
            </>
          )}

          <Divider />
          <Typography variant="subtitle2">Record</Typography>
          <Stack spacing={1}>
            {events.map((e) => {
              const stop = e.stop_id ? stops.find((x) => x.id === Number(e.stop_id)) : null;
              const what =
                e.type === 'status' ? (e.to_status ? STATUS[e.to_status as keyof typeof STATUS]?.label || e.to_status : 'Status') : EVENT_TEXT[e.type] || e.type;
              return (
                <Box key={e.id}>
                  <Typography variant="body2">
                    <b>{what}</b>
                    {stop ? ` · ${stop.name || STOP_LABEL[stop.type]}` : ''} — {ACTOR[e.actor_role] || e.actor_role}
                    {e.actor_name ? ` ${e.actor_name}` : ''}
                  </Typography>
                  <Typography variant="caption" color="text.secondary" component="div">
                    {atStop(e.happened_at, stop?.timezone || stops[0]?.timezone)}
                    {e.lat && e.lng ? (
                      <>
                        {' · '}
                        <a href={`https://maps.google.com/?q=${e.lat},${e.lng}`} target="_blank" rel="noreferrer">
                          location
                        </a>
                      </>
                    ) : null}
                    {e.note ? ` · ${e.note}` : ''}
                  </Typography>
                </Box>
              );
            })}
          </Stack>
        </Stack>
      )}

      <ReleaseLegDialog target={release} onClose={() => setRelease(null)} />
      {trip?.load_id && (
        <EndLegDialog loadId={trip.load_id} leg={ending ? trip : null} driverName={driverName} onClose={() => setEnding(false)} />
      )}
      <LoadFormDialog open={editing} onClose={() => setEditing(false)} trip={trip} driver={trip?.driver_profile_id && driverName ? { id: trip.driver_profile_id, name: driverName } : null} />

      <Dialog open={!!prompt} onClose={() => setPrompt(null)} fullWidth maxWidth="xs">
        <DialogTitle>{prompt?.title}</DialogTitle>
        <DialogContent>
          <TextField autoFocus fullWidth multiline minRows={2} label={prompt?.label} value={promptText} onChange={(e) => setPromptText(e.target.value)} sx={{ mt: 1 }} />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPrompt(null)}>Back</Button>
          <Button
            variant="contained"
            disabled={!!prompt?.required && !promptText.trim()}
            onClick={() => {
              prompt?.onOk(promptText.trim());
              setPrompt(null);
              setPromptText('');
            }}
          >
            OK
          </Button>
        </DialogActions>
      </Dialog>

      <Dialog open={problemOpen} onClose={() => setProblemOpen(false)} fullWidth maxWidth="xs">
        <DialogTitle>Add a problem</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField select label="What happened" value={problem.kind} onChange={(e) => setProblem({ ...problem, kind: e.target.value })}>
              {Object.entries(PROBLEM_KINDS).map(([k, v]) => (
                <MenuItem key={k} value={k}>
                  {v}
                </MenuItem>
              ))}
            </TextField>
            <TextField label="Details" multiline minRows={2} value={problem.note} onChange={(e) => setProblem({ ...problem, note: e.target.value })} />
            {(problem.kind === 'lumper' || problem.kind === 'detention') && (
              <TextField
                label="Amount ($) — shown to the accountant"
                type="number"
                value={problem.amount}
                onChange={(e) => setProblem({ ...problem, amount: e.target.value })}
              />
            )}
            <FormControlLabel control={<Switch checked={problem.hold} onChange={(e) => setProblem({ ...problem, hold: e.target.checked })} />} label="Put the trip on hold" />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setProblemOpen(false)}>Back</Button>
          <Button
            variant="contained"
            onClick={() => {
              const amount = problem.amount ? Number(problem.amount) : null;
              void run(() => addProblem({ id: trip!.id, kind: problem.kind, note: problem.note.trim(), amount, hold: problem.hold }).unwrap());
              setProblemOpen(false);
              setProblem({ kind: 'delay', note: '', amount: '', hold: false });
            }}
          >
            Add
          </Button>
        </DialogActions>
      </Dialog>
    </Drawer>
  );
}
