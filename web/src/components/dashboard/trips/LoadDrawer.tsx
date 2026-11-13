'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Button,
  Chip,
  Divider,
  Drawer,
  IconButton,
  LinearProgress,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import { Close, ContentCopy, Edit, ExpandLess, History, Link, LocalParking, OpenInNew, Save, Schedule, StopCircle, Straighten } from '@mui/icons-material';
import { toast } from 'react-toastify';

import {
  LoadDetail,
  LoadDocument,
  LoadHistoryEntry,
  Trip,
  useGetLoadDetailQuery,
  useMatchLegGpsMutation,
  useSendTripMutation,
  useUpdateLoadInfoMutation,
} from '@/redux/TripApiSlice';

import { AssignLegDialog } from './AssignLegDialog';
import { CorrectTimesDialog, MilesDialog } from './CorrectTimesDialog';
import { HANDOVER_REASONS } from './HandoverDialog';
import { CompleteTripButton } from './CompleteTripButton';
import { LegChain } from './LegChain';
import { LineupDrawer } from './LineupDrawer';
import { LoadFormDialog } from './LoadFormDialog';
import { EndLegDialog, ReleaseLegDialog, ReleaseTarget } from './ReleaseLegDialog';
import { TripDrawer } from './TripDrawer';
import { mediaServerUrl } from '@/lib/serverUrl';
import { appointment, lateText, LOAD_STATUS, LOAD_TYPE, legsInOrder, minutesText, STATUS, STOP_LABEL, milesSourceLabel } from './tripFormat';

// One load (tracked by its invoice #): every leg with its driver, truck and trailer and the button
// it needs now (assign, send, complete), how long it sat in the yard, and how the delivery compared
// with the appointment and with the ETA it had when it went Rolling. A leg opens the trip panel
// (live map, problems, record).


const STATUS_WORD: Record<string, string> = {
  scheduled: 'Saved for later',
  offered: 'Offered — driver waiting',
  planned: 'Sent to the driver',
  accepted: 'Driver: Got it',
  started: 'Started',
  rolling: 'Rolling',
  ended: 'Delivered / dropped',
  paperwork: 'Paperwork in',
  completed: 'Completed',
  routed: 'Priced',
  on_hold: 'On hold',
  cancelled: 'Cancelled',
};

const S3 = 'https://ciity-sms.s3.us-west-1.amazonaws.com';
const docLink = (key: string, type: string | null) => (type === 'not-upload' || type === 'local' ? `${mediaServerUrl()}/${key}` : `${S3}/${key}`);
const DOC_NAME: Record<string, string> = { bol: 'BOL', pod: 'POD', scale_ticket: 'Scale ticket', lumper: 'Lumper receipt', lumper_receipt: 'Lumper receipt' };
const docName = (d: LoadDocument) => (d.docType ? DOC_NAME[d.docType] || d.docType.replace(/_/g, ' ') : /\.pdf$/i.test(d.url) ? 'PDF' : 'Photo');

/** Paperwork the driver sent in the chat — on the load automatically, newest first */
function Paperwork({ docs }: { docs: LoadDocument[] }): React.JSX.Element {
  return (
    <Box data-testid="loadPaperwork">
      <Typography variant="subtitle2" sx={{ mb: 1 }}>{`Paperwork (${docs.length})`}</Typography>
      {docs.length === 0 ? (
        <Typography variant="body2" color="text.secondary">
          Nothing yet — photos / PDFs the driver sends in the chat (BOL, POD …) show up here by themselves.
        </Typography>
      ) : (
        <Stack direction="row" spacing={1} useFlexGap flexWrap="wrap">
          {[...docs].reverse().map((d) => {
            const href = docLink(d.url, d.uploadType);
            const pdf = /\.pdf$/i.test(d.url);
            return (
              <Box
                key={d.messageId}
                component="a"
                href={href}
                target="_blank"
                rel="noreferrer"
                sx={{ width: 112, textDecoration: 'none', color: 'inherit', border: 1, borderColor: 'divider', borderRadius: 1.5, overflow: 'hidden', '&:hover': { borderColor: 'primary.main' } }}
              >
                <Box sx={{ height: 84, bgcolor: 'action.hover', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  {pdf ? (
                    <Typography variant="h6" color="text.secondary">PDF</Typography>
                  ) : (
                    <Box component="img" src={d.thumbnail ? docLink(d.thumbnail, d.uploadType) : href} alt={docName(d)} sx={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  )}
                </Box>
                <Box sx={{ px: 0.75, py: 0.5 }}>
                  <Typography variant="caption" sx={{ fontWeight: 600, display: 'block' }} noWrap>
                    {docName(d)}
                    {d.legNo > 1 ? ` · leg ${d.legNo}` : ''}
                  </Typography>
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }} noWrap>
                    {when(d.at)}
                  </Typography>
                </Box>
              </Box>
            );
          })}
        </Stack>
      )}
    </Box>
  );
}

/** One line of the load's history */
function historyText(h: LoadHistoryEntry): string {
  const fmt = (v?: string | null) =>
    v ? new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }).format(new Date(v)) : 'none';
  switch (h.type) {
    case 'transfer':
      return `🔁 ${h.note || 'Handed over'}`;
    case 'transfer_undone':
      return `↩️ ${h.note || 'Handover undone'}`;
    case 'time_correction': {
      const b = h.data?.before?.leg || {};
      const a = h.data?.after?.leg || {};
      const parts = Object.keys(a).map((k) => `${k === 'started_at' ? 'start' : 'end'} ${fmt(b[k])} → ${fmt(a[k])}`);
      const stops = (h.data?.after?.stops || []).length;
      return `🕑 Times corrected${parts.length ? `: ${parts.join(', ')}` : ''}${stops ? ` (${stops} stop${stops > 1 ? 's' : ''})` : ''} — ${h.note || ''}`;
    }
    case 'miles':
      return `📏 ${h.note || 'Miles changed'}`;
    case 'document':
      return `📎 ${h.note || 'Document from the chat'}`;
    case 'stop_arrived':
      return `📍 Arrived${h.note ? ` — ${h.note}` : ''}`;
    case 'stop_departed':
      return '🛣️ Left the stop';
    case 'problem':
      return `⚠️ Problem${h.note ? `: ${h.note}` : ''}`;
    case 'problem_resolved':
      return '✔️ Problem resolved';
    case 'correction':
      return `↩️ ${h.note || 'Undo'}`;
    case 'status':
    case 'offer':
      return `${STATUS_WORD[h.to || ''] || h.to || 'Status'}${h.note ? ` — ${h.note}` : ''}`;
    default:
      return h.note || h.type;
  }
}

const HANDED_OVER = ['ended', 'paperwork', 'completed', 'routed'];
const when = (iso?: string | null) =>
  iso ? new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }).format(new Date(iso)) : '—';

function InvoiceField({ detail }: { detail: LoadDetail }) {
  const [editing, setEditing] = React.useState(false);
  const [value, setValue] = React.useState(detail.load.invoice_no || '');
  const [update, { isLoading }] = useUpdateLoadInfoMutation();
  React.useEffect(() => setValue(detail.load.invoice_no || ''), [detail.load.invoice_no]);
  const save = async () => {
    try {
      await update({ id: detail.load.id, invoiceNo: value.trim() || null }).unwrap();
      toast.success('Invoice # saved on every leg');
      setEditing(false);
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save');
    }
  };
  if (!editing) {
    return (
      <Stack direction="row" spacing={1} alignItems="center">
        <Typography variant="body2" color={detail.load.invoice_no ? 'text.primary' : 'warning.main'} data-testid="loadInvoice">
          Invoice # <b>{detail.load.invoice_no || 'not added yet — needed to complete the load'}</b>
        </Typography>
        <Tooltip title="Edit invoice #">
          <IconButton size="small" onClick={() => setEditing(true)}>
            <Edit fontSize="small" />
          </IconButton>
        </Tooltip>
      </Stack>
    );
  }
  return (
    <Stack direction="row" spacing={1} alignItems="center">
      <TextField size="small" label="Invoice #" value={value} onChange={(e) => setValue(e.target.value)} inputProps={{ maxLength: 64 }} autoFocus />
      <Button size="small" variant="contained" startIcon={<Save />} disabled={isLoading} onClick={() => void save()}>
        Save
      </Button>
      <Button size="small" onClick={() => setEditing(false)}>
        Cancel
      </Button>
    </Stack>
  );
}

/** The shipper's public tracking link: copy it into an email / text, or open it */
function TrackingLink({ detail }: { detail: LoadDetail }) {
  const token = detail.load.track_token;
  if (!token) return null;
  const closed = ['completed', 'cancelled'].includes(detail.load.status);
  const url = typeof window !== 'undefined' ? `${window.location.origin}/track/${token}` : `/track/${token}`;
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(url);
      toast.success('Tracking link copied — send it to the shipper / customer');
    } catch {
      toast.info(url, { autoClose: 15000 });
    }
  };
  return (
    <Stack direction="row" spacing={1} alignItems="center" sx={{ p: 1, px: 1.5, borderRadius: 2, bgcolor: 'action.hover' }} data-testid="trackingLink">
      <Link fontSize="small" color={closed ? 'disabled' : 'primary'} />
      <Typography variant="body2" sx={{ flexGrow: 1, minWidth: 0 }} noWrap color={closed ? 'text.disabled' : 'text.primary'}>
        {closed ? 'Tracking link expired (load completed)' : url}
      </Typography>
      {!closed && (
        <Tooltip title="Customers enter this load number in the app's “Track a load”">
          <Chip size="small" label={`Code ${detail.load.invoice_no || detail.load.load_no}`} sx={{ fontWeight: 700, letterSpacing: 1 }} data-testid="trackCode" />
        </Tooltip>
      )}
      {!closed && (
        <>
          <Button size="small" startIcon={<ContentCopy fontSize="small" />} onClick={() => void copy()}>
            Copy
          </Button>
          <Button size="small" startIcon={<OpenInNew fontSize="small" />} href={url} target="_blank" rel="noopener">
            Open
          </Button>
        </>
      )}
    </Stack>
  );
}

function LegCard({
  leg,
  prev,
  isLast,
  names,
  onOpen,
  onAssign,
  onEdit,
  onLineup,
  onTimes,
  onMiles,
  onRelease,
  onEnd,
  allLegs,
}: {
  leg: Trip;
  prev?: Trip;
  isLast: boolean;
  names: Record<string, string>;
  onOpen: () => void;
  onAssign: () => void;
  onEdit: () => void;
  onLineup: (profileId: string) => void;

  onTimes: () => void;
  onMiles: () => void;
  onRelease: () => void;
  onEnd: () => void;
  /** Every leg of the load (Mark completed lists the delivered ones together) */
  allLegs: Trip[];
}) {
  const [sendTrip, { isLoading: sending }] = useSendTripMutation();
  const [matchGps, { isLoading: matching }] = useMatchLegGpsMutation();
  const recheck = async () => {
    try {
      const res = await matchGps({ id: leg.load_id!, legId: leg.id }).unwrap();
      toast.success(res.message || 'Miles re-checked');
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not re-check the miles');
    }
  };
  const stops = [...(leg.stops || [])].sort((a, b) => a.seq - b.seq);
  const first = stops[0];
  const last = stops[stops.length - 1];
  const blocked = !!prev && !HANDED_OVER.includes(prev.status);
  const who = leg.driver_profile_id ? names[leg.driver_profile_id] || 'Driver' : null;
  const s = STATUS[leg.status];
  const send = async () => {
    try {
      await sendTrip(leg.id).unwrap();
      toast.success(`Leg ${leg.leg_no} sent to ${who}`);
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not send');
    }
  };
  const place = (st?: typeof first) => (st ? `${st.type === 'yard' || st.type === 'switch' ? `${STOP_LABEL[st.type]}: ` : ''}${st.name || ''}${st.city ? ` (${st.city}, ${st.state})` : ''}` : '—');

  return (
    <Box sx={{ border: 1, borderColor: leg.status === 'offered' ? 'warning.main' : 'divider', borderRadius: 2, p: 1.5 }} data-testid={`loadLeg-${leg.leg_no}`}>
      <Stack direction="row" alignItems="center" spacing={1}>
        <Typography variant="subtitle2" sx={{ flexGrow: 1 }}>
          Leg {leg.leg_no} · #{leg.trip_no}
        </Typography>
        {leg.needs_review && <Chip size="small" color="warning" variant="outlined" label="Check" />}
        <Chip size="small" label={s.label} color={s.color} />
      </Stack>
      <Typography variant="body2" sx={{ mt: 0.5 }} color={who ? 'text.primary' : 'warning.main'}>
        {who || 'No driver yet'}
        {leg.driver_id_2 ? ' + team' : ''} · Truck {leg.truck_number || '—'} · Trailer {leg.trailer_numbers || '—'}
        {leg.driver_profile_id && (
          <Button size="small" sx={{ ml: 1, py: 0, minWidth: 0 }} onClick={() => onLineup(leg.driver_profile_id!)}>
            {['scheduled', 'offered'].includes(leg.status) && leg.queue_pos ? `#${leg.queue_pos} in lineup` : 'Lineup'}
          </Button>
        )}
      </Typography>
      <Typography variant="caption" color="text.secondary" component="div">
        {place(first)} → {place(last)}
        {last?.appointment_local ? ` · appt ${appointment(last.appointment_local)}` : ''}
      </Typography>
      {(leg.started_at || leg.ended_at) && (
        <Typography variant="caption" color="text.secondary" component="div">
          {leg.started_at ? `Rolling ${when(leg.started_at)}` : ''}
          {leg.ended_at ? ` · ${leg.ends_at_yard ? 'Dropped at yard' : last?.type === 'switch' ? 'Handed over' : 'Delivered'} ${when(leg.ended_at)}` : ''}
          {leg.planned_eta_at && !leg.ended_at ? ` · ETA at rolling ${when(leg.planned_eta_at)}` : ''}
        </Typography>
      )}
      {(leg.ended_at || leg.total_mileage) && (
        <Typography variant="caption" component="div" color={leg.total_mileage ? 'text.secondary' : 'warning.main'} data-testid={`legMiles-${leg.leg_no}`}>
          {leg.total_mileage
            ? `${Number(leg.total_mileage).toLocaleString()} mi · ${milesSourceLabel(leg.miles_source, leg.miles_note || 'no note')}`
            : leg.miles_note || 'Miles missing — Samsara had nothing yet'}
          {leg.ended_at && leg.miles_source !== 'manual' && leg.load_id && (
            <Button size="small" sx={{ ml: 1, py: 0, minWidth: 0 }} disabled={matching} onClick={() => void recheck()} data-testid={`recheckMiles-${leg.leg_no}`}>
              {matching ? 'Checking…' : 'Re-check miles'}
            </Button>
          )}
        </Typography>
      )}
      {leg.handover_reason && (
        <Typography variant="caption" color="warning.dark" component="div">
          Handed over: {HANDOVER_REASONS[leg.handover_reason] || leg.handover_reason}
        </Typography>
      )}
      {blocked && ['scheduled', 'offered'].includes(leg.status) && (
        <Typography variant="caption" color="info.main" component="div">
          Goes out after leg {prev!.leg_no} is {prev!.ends_at_yard ? 'dropped at the yard' : 'handed over'}
        </Typography>
      )}
      {leg.review_notes && leg.needs_review && (
        <Typography variant="caption" color="warning.dark" component="div">
          {leg.review_notes.split('\n')[0]}
        </Typography>
      )}
      <Stack direction="row" spacing={1} sx={{ mt: 1 }} flexWrap="wrap" useFlexGap>
        {['scheduled', 'offered'].includes(leg.status) && !who && (
          <Button size="small" variant="contained" color="warning" onClick={onAssign}>
            Assign driver
          </Button>
        )}
        {['scheduled', 'offered'].includes(leg.status) && who && blocked && (
          <Button size="small" variant="contained" color="warning" onClick={onRelease} data-testid={`releaseBtn-${leg.leg_no}`}>
            Leg {prev!.leg_no} handed over — send to {who}
          </Button>
        )}
        {['scheduled', 'offered'].includes(leg.status) && who && !blocked && (
          <Button size="small" variant="contained" color={leg.status === 'offered' ? 'warning' : 'primary'} disabled={sending} onClick={() => void send()}>
            {leg.status === 'offered' ? 'Confirm & send' : 'Send to driver'}
          </Button>
        )}
        {['scheduled', 'offered'].includes(leg.status) && who && (
          <Button size="small" onClick={onAssign}>
            Reassign
          </Button>
        )}
        {['planned', 'accepted', 'started', 'rolling', 'on_hold'].includes(leg.status) && (
          <Button size="small" color="warning" startIcon={<StopCircle fontSize="small" />} onClick={onEnd} data-testid={`endBtn-${leg.leg_no}`}>
            End load
          </Button>
        )}
        {leg.started_at && !['routed', 'cancelled'].includes(leg.status) && (
          <Button size="small" startIcon={<Schedule fontSize="small" />} onClick={onTimes}>
            Correct times
          </Button>
        )}
        {leg.ended_at && !['routed', 'cancelled'].includes(leg.status) && (
          <Button size="small" startIcon={<Straighten fontSize="small" />} onClick={onMiles}>
            Miles
          </Button>
        )}
        {(leg.status === 'ended' || leg.status === 'paperwork') && <CompleteTripButton trip={leg} size="small" requireInvoice={isLast} legs={allLegs} names={names} />}
        {!['completed', 'routed', 'cancelled'].includes(leg.status) && (
          <Button size="small" startIcon={<Edit fontSize="small" />} onClick={onEdit}>
            Edit
          </Button>
        )}
        <Button size="small" startIcon={<OpenInNew fontSize="small" />} onClick={onOpen}>
          Open
        </Button>
      </Stack>
    </Box>
  );
}

export function LoadDrawer({ loadId, onClose }: { loadId: number | null; onClose: () => void }): React.JSX.Element {
  const { data, isFetching } = useGetLoadDetailQuery(loadId as number, { skip: !loadId });
  const detail = data?.data;
  const [openTrip, setOpenTrip] = React.useState<number | null>(null);
  const [assigning, setAssigning] = React.useState<Trip | null>(null);
  const [editing, setEditing] = React.useState<Trip | null>(null);
  const [lineupOf, setLineupOf] = React.useState<string | null>(null);
  const [timesOf, setTimesOf] = React.useState<Trip | null>(null);
  const [milesOf, setMilesOf] = React.useState<Trip | null>(null);
  const [showHistory, setShowHistory] = React.useState(false);
  const [showRemoved, setShowRemoved] = React.useState(false);
  const [release, setRelease] = React.useState<ReleaseTarget | null>(null);
  const [ending, setEnding] = React.useState<Trip | null>(null);

  const legs = legsInOrder(detail?.legs);
  const names = detail?.driverNames || {};
  const live = legs.filter((l) => l.status !== 'cancelled');
  const lastLeg = live[live.length - 1];
  const lastStop = lastLeg ? [...(lastLeg.stops || [])].sort((a, b) => a.seq - b.seq).pop() : undefined;
  const t = detail?.timing;
  const st = detail ? LOAD_STATUS[detail.load.status] : null;
  const assigningPrev = assigning ? legs.filter((l) => l.leg_no < assigning.leg_no && l.status !== 'cancelled').pop() : undefined;

  return (
    <Drawer anchor="right" open={!!loadId} onClose={onClose} sx={{ zIndex: (theme) => theme.zIndex.modal }} PaperProps={{ sx: { width: { xs: '100%', md: 860, lg: 980 } } }}>
      {isFetching && <LinearProgress />}
      {detail && (
        <Stack spacing={2} sx={{ p: 2.5 }} data-testid="loadDrawer">
          <Stack direction="row" alignItems="center" spacing={1}>
            <Box sx={{ flexGrow: 1 }}>
              <Typography variant="h6">Load #{detail.load.invoice_no || detail.load.load_no}</Typography>
              <Stack direction="row" spacing={0.75} sx={{ mt: 0.5 }}>
<Chip size="small" variant="outlined" label={LOAD_TYPE[detail.load.type].label} data-testid="loadTypeChip" />
                {st && <Chip size="small" label={st.label} color={st.color} />}
              </Stack>
            </Box>
            <IconButton onClick={onClose}>
              <Close />
            </IconButton>
          </Stack>

          <InvoiceField detail={detail} />
          <TrackingLink detail={detail} />
          <LegChain legs={legs} names={names} />

          {detail.load.status === 'transfer' && (
            <Alert severity="warning">
              {lastLeg && live.find((l) => ['scheduled', 'offered'].includes(l.status) && !l.driver_profile_id)
                ? 'The load is waiting for the next leg — assign a driver and truck.'
                : 'The load is waiting for the next leg — send it to the driver.'}
            </Alert>
          )}

          {/* Delivered vs appointment / ETA */}
          {t && (t.deliveredAt || t.etaAt) && (
            <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 1 }} data-testid="loadTiming">
              <Box sx={{ p: 1.25, border: 1, borderColor: 'divider', borderRadius: 2 }}>
                <Typography variant="caption" color="text.secondary">
                  {t.deliveredAt ? 'Delivered' : 'ETA at rolling'}
                </Typography>
                <Typography variant="subtitle2">{when(t.deliveredAt || t.etaAt)}</Typography>
                <Typography variant="caption" color="text.secondary">
                  Appt {appointment(lastStop?.appointment_local)}
                </Typography>
              </Box>
              <Box sx={{ p: 1.25, border: 1, borderColor: 'divider', borderRadius: 2 }}>
                <Typography variant="caption" color="text.secondary">
                  vs appointment
                </Typography>
                <Typography variant="subtitle2" color={((t.deliveredAt ? t.lateMinutes : t.etaVsAppointmentMinutes) ?? 0) > 15 ? 'error.main' : 'success.main'}>
                  {lateText(t.deliveredAt ? t.lateMinutes : t.etaVsAppointmentMinutes)}
                </Typography>
              </Box>
              <Box sx={{ p: 1.25, border: 1, borderColor: 'divider', borderRadius: 2 }}>
                <Typography variant="caption" color="text.secondary">
                  vs ETA at rolling
                </Typography>
                <Typography variant="subtitle2">
                  {t.etaOffMinutes === null ? '—' : Math.abs(t.etaOffMinutes) <= 15 ? 'As predicted' : `${minutesText(t.etaOffMinutes)} ${t.etaOffMinutes > 0 ? 'later' : 'sooner'}`}
                </Typography>
                {t.etaAt && (
                  <Typography variant="caption" color="text.secondary">
                    ETA was {when(t.etaAt)}
                  </Typography>
                )}
              </Box>
            </Box>
          )}

          {/* Yard (only when the load went through it) */}
          {detail.yardVisits.length > 0 && (
          <Box sx={{ p: 1.5, border: 1, borderColor: 'divider', borderRadius: 2 }} data-testid="loadYard">
            <Stack direction="row" spacing={1} alignItems="center">
              <LocalParking fontSize="small" color="action" />
              <Typography variant="subtitle2" sx={{ flexGrow: 1 }}>
                {`In the yard ${detail.yardVisits.length}× · ${minutesText(detail.yardMinutes)} total`}
              </Typography>
            </Stack>
            {detail.yardVisits.map((v, i) => (
              <Typography key={i} variant="caption" color="text.secondary" component="div" sx={{ pl: 3.5 }}>
                {v.trailer ? `Trailer ${v.trailer} · ` : ''}in {when(v.inAt)} → {v.outAt ? `out ${when(v.outAt)}` : 'still in'} · {minutesText(v.minutes)}
                {v.loaded ? ` · ${v.loaded}` : ''}
                {v.source === 'leg' ? ' · (leg drop, no gate record)' : ''}
              </Typography>
            ))}
          </Box>
          )}

          {/* Who moved which part, on which truck, and the miles */}
          <Box data-testid="loadSegments">
            <Stack direction="row" alignItems="baseline" spacing={1}>
              <Typography variant="subtitle2" sx={{ flexGrow: 1 }}>
                Segments
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {(detail.milesTotals?.miles ?? 0).toLocaleString()} mi total{detail.milesTotals?.missing ? ` · ${detail.milesTotals?.missing} missing` : ''}
              </Typography>
            </Stack>
            <Table size="small" sx={{ mt: 0.5, '& td, & th': { px: 0.75, py: 0.5, fontSize: 12 } }}>
              <TableHead>
                <TableRow>
                  <TableCell>#</TableCell>
                  <TableCell>Driver · truck</TableCell>
                  <TableCell>From → to</TableCell>
                  <TableCell>When</TableCell>
                  <TableCell align="right">Miles</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {(detail.segments || []).map((sg) => (
                  <TableRow key={sg.legId}>
                    <TableCell>{sg.legNo}</TableCell>
                    <TableCell>
                      <b>{sg.drivers.join(' + ') || '—'}</b>
                      <br />
                      {sg.truck ? `T ${sg.truck}` : 'no truck'}
                      {sg.trailers ? ` · TR ${sg.trailers}` : ''}
                    </TableCell>
                    <TableCell>
                      {sg.from} → {sg.to}
                      {sg.handoverReason && (
                        <Typography variant="caption" color="warning.dark" component="div">
                          handed over: {HANDOVER_REASONS[sg.handoverReason] || sg.handoverReason}
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      {sg.startedAt ? when(sg.startedAt) : '—'}
                      <br />
                      {sg.endedAt ? `→ ${when(sg.endedAt)}` : STATUS[sg.status].label}
                      {sg.minutes !== null ? ` · ${minutesText(sg.minutes)}` : ''}
                    </TableCell>
                    <TableCell align="right">
                      {sg.miles !== null ? (
                        <>
                          <b>{sg.miles.toLocaleString()}</b>
                          <Typography variant="caption" color="text.secondary" component="div">
                            {milesSourceLabel(sg.milesSource)}
                          </Typography>
                        </>
                      ) : sg.endedAt ? (
                        <Typography variant="caption" color="warning.main">
                          missing
                        </Typography>
                      ) : (
                        '—'
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
            {(Object.keys(detail.milesTotals?.byDriver || {}).length > 1 || Object.keys(detail.milesTotals?.byTruck || {}).length > 1) && (
              <Typography variant="caption" color="text.secondary" component="div" sx={{ mt: 0.5 }}>
                By driver: {Object.entries(detail.milesTotals?.byDriver || {}).map(([k, v]) => `${k} ${v.toLocaleString()} mi`).join(' · ')}
                <br />
                By truck: {Object.entries(detail.milesTotals?.byTruck || {}).map(([k, v]) => `${k} ${v.toLocaleString()} mi`).join(' · ')}
              </Typography>
            )}
          </Box>

          <Paperwork docs={detail.documents || []} />

          {/* Everything that happened, in order */}
          <Box data-testid="loadHistory">
            <Button size="small" startIcon={showHistory ? <ExpandLess /> : <History />} onClick={() => setShowHistory((v) => !v)}>
              {showHistory ? 'Hide history' : `History (${(detail.history || []).length})`}
            </Button>
            {showHistory && (
              <Stack spacing={0} sx={{ mt: 1, pl: 1, borderLeft: 2, borderColor: 'divider' }}>
                {[...(detail.history || [])].reverse().map((h, i) => {
                  const important = ['transfer', 'transfer_undone', 'time_correction', 'miles', 'problem'].includes(h.type);
                  return (
                    <Box key={i} sx={{ pl: 1.5, py: 0.5, position: 'relative' }}>
                      <Box sx={{ position: 'absolute', left: -6, top: 11, width: 10, height: 10, borderRadius: '50%', bgcolor: important ? 'warning.main' : 'divider' }} />
                      <Typography variant="caption" color="text.secondary">
                        {when(h.at)} · leg {h.legNo} · {h.actor}
                      </Typography>
                      <Typography variant="body2" fontWeight={important ? 600 : 400}>
                        {historyText(h)}
                      </Typography>
                    </Box>
                  );
                })}
              </Stack>
            )}
          </Box>

          <Divider />
          <Stack direction="row" alignItems="center">
            <Typography variant="subtitle2" sx={{ flexGrow: 1 }}>
              Legs
            </Typography>

          </Stack>
          {legs.filter((l) => l.status !== 'cancelled').map((leg, i) => (
            <LegCard
              key={leg.id}
              leg={leg}
              prev={live[i - 1]}
              isLast={leg.id === lastLeg?.id}
              names={names}
              onOpen={() => setOpenTrip(leg.id)}
              onAssign={() => setAssigning(leg)}
              onEdit={() => setEditing(leg)}
              onLineup={setLineupOf}
              onTimes={() => setTimesOf(leg)}
              onMiles={() => setMilesOf(leg)}
              onEnd={() => setEnding(leg)}
              allLegs={legs}
              onRelease={() => {
                const prev = live[i - 1];
                const hs = prev ? [...(prev.stops || [])].sort((a, b) => a.seq - b.seq).pop() : undefined;
                setRelease({
                  loadId: loadId!,
                  legId: leg.id,
                  tripNo: leg.trip_no,
                  driverName: (leg.driver_profile_id && names[leg.driver_profile_id]) || 'the driver',
                  prevLegNo: prev?.leg_no || leg.leg_no - 1,
                  prevTripNo: (prev?.trip_no) || null,
                  prevDriver: (prev?.driver_profile_id && names[prev.driver_profile_id]) || 'the driver before',
                  place: hs ? [hs.name, [hs.city, hs.state].filter(Boolean).join(', ')].filter(Boolean).join(' · ') : '',
                });
              }}
            />
          ))}
          {legs.some((l) => l.status === 'cancelled') && (
            <Box>
              <Button size="small" color="inherit" sx={{ color: 'text.secondary' }} onClick={() => setShowRemoved((v) => !v)}>
                {showRemoved ? 'Hide removed legs' : `Removed legs (${legs.filter((l) => l.status === 'cancelled').length})`}
              </Button>
              {showRemoved &&
                legs
                  .filter((l) => l.status === 'cancelled')
                  .map((l) => (
                    <Typography key={l.id} variant="caption" color="text.disabled" component="div" sx={{ pl: 1 }}>
                      #{l.trip_no} · {l.driver_profile_id ? names[l.driver_profile_id] || 'Driver' : 'no driver'} · {l.truck_number || 'no truck'} — cancelled (kept for the record)
                    </Typography>
                  ))}
            </Box>
          )}
        </Stack>
      )}

      <AssignLegDialog
        open={!!assigning}
        onClose={() => setAssigning(null)}
        loadId={loadId || 0}
        leg={assigning}
        canSend={!assigningPrev || HANDED_OVER.includes(assigningPrev.status)}
        driverName={assigning?.driver_profile_id ? names[assigning.driver_profile_id] : null}
      />
      <LoadFormDialog
        open={!!editing}
        onClose={() => setEditing(null)}
        trip={editing}
        driver={editing?.driver_profile_id && names[editing.driver_profile_id] ? { id: editing.driver_profile_id, name: names[editing.driver_profile_id] } : null}
      />


      <CorrectTimesDialog open={!!timesOf} onClose={() => setTimesOf(null)} loadId={loadId || 0} leg={timesOf} />
      <MilesDialog open={!!milesOf} onClose={() => setMilesOf(null)} loadId={loadId || 0} leg={milesOf} />

      <ReleaseLegDialog target={release} onClose={() => setRelease(null)} />
      <EndLegDialog loadId={loadId || 0} leg={ending} driverName={ending?.driver_profile_id ? names[ending.driver_profile_id] : null} onClose={() => setEnding(null)} />
      <TripDrawer tripId={openTrip} onClose={() => setOpenTrip(null)} />
      <LineupDrawer profileId={lineupOf} onClose={() => setLineupOf(null)} />
    </Drawer>
  );
}
