'use client';

import * as React from 'react';
import dynamic from 'next/dynamic';
import { Alert, Box, Chip, Container, LinearProgress, Paper, Skeleton, Stack, Typography } from '@mui/material';
import { AccessTime, Bedtime, CheckCircle, Coffee, LocalGasStation, LocalShipping, PauseCircle, Place, Speed, Thermostat, Timeline } from '@mui/icons-material';

import { apiUrl } from '@/lib/serverUrl';
import { BrandLogo } from '@/components/core/brand-logo';
import type { LiveStopEta, LiveTruck } from '@/redux/TripApiSlice';

// Public shipment tracking (/track/<token>): where the load is, when it gets there, every stop with
// its appointment and actual times, and what happened so far — for shippers and customers. Refreshes
// every minute. No login; nothing about the driver beyond the truck / trailer numbers.

const TripMap = dynamic(() => import('@/components/dashboard/trips/TripMap'), { ssr: false, loading: () => <Skeleton variant="rounded" height={380} /> });

interface Stop {
  id: number;
  type: 'pickup' | 'drop' | 'transfer';
  name: string | null;
  place: string;
  address: string | null;
  appointment: string | null;
  timezone: string | null;
  arrivedAt: string | null;
  departedAt: string | null;
  state: 'done' | 'next' | 'upcoming';
}
interface View {
  expired: boolean;
  loadNo: string;
  status: string;
  deliveredAt: string | null;
  phase?: 'booked' | 'dispatched' | 'picked_up' | 'in_transit' | 'delivered';
  legs?: number;
  equipment?: { truck: string | null; trailer: string | null; temperature: string | null } | null;
  stops?: Stop[];
  nextStop?: Stop | null;
  live?: {
    truck: LiveTruck | null;
    stops: LiveStopEta[];
    path: [number, number][];
    miles: number | null;
    eta: string | null;
    updatedAt: string;
    breaks?: { kind: 'break' | 'rest' | 'fuel'; minutes: number; at: string; atMile: number }[];
    stopped?: { since: string | null; minutes: number | null; address: string | null; reason: string | null } | null;
  } | null;
  eta?: string | null;
  lateMinutes?: number | null;
  activity?: { at: string; text: string }[];
  updatedAt?: string;
}

const STEPS: { key: NonNullable<View['phase']>; label: string }[] = [
  { key: 'booked', label: 'Booked' },
  { key: 'dispatched', label: 'Dispatched' },
  { key: 'in_transit', label: 'In transit' },
  { key: 'delivered', label: 'Delivered' },
];

const when = (iso?: string | null, tz?: string | null) =>
  iso
    ? new Intl.DateTimeFormat('en-US', { timeZone: tz || undefined, weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit', timeZoneName: tz ? 'short' : undefined }).format(new Date(iso))
    : '—';
/** "Thu, Nov 20 · 8:00 AM" from the stop's own local time */
const appt = (local?: string | null) => {
  if (!local) return null;
  const [d, t = '00:00'] = local.split('T');
  const [y, m, day] = d.split('-').map(Number);
  const [hh, mm] = t.split(':').map(Number);
  const date = new Date(Date.UTC(y, m - 1, day));
  const wd = new Intl.DateTimeFormat('en-US', { weekday: 'short', month: 'short', day: 'numeric', timeZone: 'UTC' }).format(date);
  return `${wd} · ${hh % 12 || 12}:${String(mm).padStart(2, '0')} ${hh >= 12 ? 'PM' : 'AM'}`;
};
const ago = (iso?: string | null) => {
  if (!iso) return '';
  const min = Math.max(0, Math.round((Date.now() - new Date(iso).getTime()) / 60000));
  return min < 1 ? 'just now' : min < 60 ? `${min} min ago` : `${Math.round(min / 60)} h ago`;
};
const lateText = (min?: number | null) => {
  if (min === null || min === undefined) return null;
  if (Math.abs(min) <= 15) return { label: 'On time', color: 'success' as const };
  const h = Math.floor(Math.abs(min) / 60);
  const m = Math.abs(min) % 60;
  const t = `${h ? `${h} h ` : ''}${m ? `${m} min` : ''}`.trim();
  return min > 0 ? { label: `Running ${t} late`, color: 'warning' as const } : { label: `${t} early`, color: 'success' as const };
};
const STOP_WORD = { pickup: 'Pickup', drop: 'Delivery', transfer: 'Transfer point' } as const;

const BREAK_INFO = {
  break: { label: '30-min break', why: 'Required after 8 hours of driving', icon: Coffee, color: '#0284C7' },
  rest: { label: '10-hour rest', why: 'Driver hours-of-service rule', icon: Bedtime, color: '#7C3AED' },
  fuel: { label: 'Fuel stop', why: 'About every 1,000 miles', icon: LocalGasStation, color: '#D97706' },
} as const;
const span = (min: number) => (min >= 60 ? `${Math.floor(min / 60)} h${min % 60 ? ` ${min % 60} min` : ''}` : `${min} min`);

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#F4F6FA' }}>
      <Box sx={{ bgcolor: '#0B1F3A', color: 'white' }}>
        <Container maxWidth="lg" sx={{ py: 1.5, display: 'flex', alignItems: 'center', gap: 2 }}>
          <BrandLogo height={34} invert />
          <Box sx={{ flexGrow: 1 }} />
          <Typography variant="body2" sx={{ opacity: 0.8 }}>
            Shipment tracking
          </Typography>
        </Container>
      </Box>
      <Container maxWidth="lg" sx={{ py: { xs: 2, md: 4 } }}>
        {children}
      </Container>
      <Typography variant="caption" color="text.secondary" component="div" sx={{ textAlign: 'center', pb: 4 }}>
        Tracking by US City Link · this link works until the load is completed
      </Typography>
    </Box>
  );
}

function Steps({ phase }: { phase: NonNullable<View['phase']> }) {
  const at = STEPS.findIndex((s) => s.key === (phase === 'picked_up' ? 'in_transit' : phase));
  return (
    <Stack direction="row" alignItems="center" sx={{ mt: 2.5 }} data-testid="trackSteps">
      {STEPS.map((s, i) => {
        const done = i <= at;
        return (
          <React.Fragment key={s.key}>
            <Stack alignItems="center" spacing={0.75} sx={{ minWidth: 72 }}>
              <Box
                sx={{
                  width: 30,
                  height: 30,
                  borderRadius: '50%',
                  display: 'grid',
                  placeItems: 'center',
                  bgcolor: done ? (i === at ? '#1D4ED8' : '#16A34A') : '#E5E7EB',
                  color: done ? 'white' : '#9CA3AF',
                  boxShadow: i === at ? '0 0 0 5px rgba(29,78,216,.15)' : 'none',
                }}
              >
                {done && i < at ? <CheckCircle sx={{ fontSize: 18 }} /> : <Typography sx={{ fontSize: 13, fontWeight: 700 }}>{i + 1}</Typography>}
              </Box>
              <Typography variant="caption" fontWeight={i === at ? 700 : 500} color={done ? 'text.primary' : 'text.secondary'}>
                {s.label}
              </Typography>
            </Stack>
            {i < STEPS.length - 1 && <Box sx={{ flexGrow: 1, height: 3, borderRadius: 2, bgcolor: i < at ? '#16A34A' : '#E5E7EB', mb: 3 }} />}
          </React.Fragment>
        );
      })}
    </Stack>
  );
}

export function TrackingPage({ token }: { token: string }): React.JSX.Element {
  const [view, setView] = React.useState<View | null>(null);
  const [error, setError] = React.useState<string | null>(null);
  const [loading, setLoading] = React.useState(false);

  const load = React.useCallback(async () => {
    setLoading(true);
    try {
      const base = apiUrl().replace(/\/?$/, '/');
      const res = await fetch(`${base}public/track/${encodeURIComponent(token)}`, { cache: 'no-store' });
      const json = await res.json().catch(() => null);
      if (!res.ok || !json?.status) {
        setError(res.status === 404 ? 'not_found' : json?.message || 'Tracking is not available right now');
        return;
      }
      setError(null);
      setView(json.data);
    } catch {
      setError('Tracking is not available right now — check your connection');
    } finally {
      setLoading(false);
    }
  }, [token]);

  React.useEffect(() => {
    void load();
    const t = setInterval(() => void load(), 60_000);
    return () => clearInterval(t);
  }, [load]);

  if (error === 'not_found') {
    return (
      <Shell>
        <Paper sx={{ p: 5, textAlign: 'center', borderRadius: 3 }} data-testid="trackNotFound">
          <Typography variant="h5" gutterBottom>
            Tracking link not found
          </Typography>
          <Typography color="text.secondary">Check the link you were sent, or contact the carrier for a new one.</Typography>
        </Paper>
      </Shell>
    );
  }
  if (!view) {
    return (
      <Shell>
        {error ? <Alert severity="warning">{error}</Alert> : <Skeleton variant="rounded" height={420} />}
      </Shell>
    );
  }
  if (view.expired) {
    return (
      <Shell>
        <Paper sx={{ p: { xs: 3, md: 5 }, textAlign: 'center', borderRadius: 3 }} data-testid="trackExpired">
          <CheckCircle sx={{ fontSize: 56, color: view.status === 'cancelled' ? 'text.disabled' : '#16A34A' }} />
          <Typography variant="h5" sx={{ mt: 1 }}>
            Load {view.loadNo} {view.status === 'cancelled' ? 'was cancelled' : 'is completed'}
          </Typography>
          <Typography color="text.secondary" sx={{ mt: 1 }}>
            {view.status === 'cancelled'
              ? 'This tracking link is no longer active.'
              : `Delivered${view.deliveredAt ? ` ${when(view.deliveredAt)}` : ''}. This tracking link has expired.`}
          </Typography>
        </Paper>
      </Shell>
    );
  }

  const stops = view.stops || [];
  const origin = stops[0];
  const dest = [...stops].reverse().find((s) => s.type === 'drop') || stops[stops.length - 1];
  const late = lateText(view.lateMinutes);
  const truck = view.live?.truck || null;
  const delivered = view.phase === 'delivered';
  const headline = delivered
    ? `Delivered${view.deliveredAt ? ` ${when(view.deliveredAt, dest?.timezone)}` : ''}`
    : view.eta
      ? `Arriving ${when(view.eta, dest?.timezone)}`
      : view.phase === 'in_transit'
        ? 'In transit'
        : view.phase === 'dispatched'
          ? 'Driver assigned — pickup coming up'
          : 'Booked — waiting for dispatch';

  return (
    <Shell>
      {loading && <LinearProgress sx={{ position: 'fixed', top: 0, left: 0, right: 0 }} />}
      <Stack spacing={2.5}>
        {/* Headline */}
        <Paper sx={{ p: { xs: 2.5, md: 3.5 }, borderRadius: 3 }} data-testid="trackHeader">
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} justifyContent="space-between">
            <Box>
              <Typography variant="overline" color="text.secondary">
                Load {view.loadNo}
              </Typography>
              <Typography variant="h4" fontWeight={800} sx={{ lineHeight: 1.15, mt: 0.5 }}>
                {headline}
              </Typography>
              <Typography color="text.secondary" sx={{ mt: 1 }}>
                {origin?.place || '—'} → {dest?.place || '—'}
              </Typography>
            </Box>
            <Stack spacing={1} alignItems={{ md: 'flex-end' }}>
              <Chip
                label={delivered ? 'Delivered' : view.phase === 'in_transit' ? 'In transit' : view.phase === 'dispatched' ? 'Dispatched' : 'Booked'}
                color={delivered ? 'success' : 'primary'}
                sx={{ fontWeight: 700 }}
              />
              {late && !delivered && <Chip label={late.label} color={late.color} variant="outlined" />}
              {dest?.appointment && (
                <Typography variant="caption" color="text.secondary">
                  Delivery appointment {appt(dest.appointment)}
                </Typography>
              )}
            </Stack>
          </Stack>
          {view.phase && <Steps phase={view.phase} />}
        </Paper>

        {/* Map + truck */}
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '2fr 1fr' }, gap: 2.5 }}>
          <Paper sx={{ p: 1.5, borderRadius: 3, alignSelf: "start" }}>
            {view.live && (view.live.truck || view.live.path.length) ? (
              <TripMap truck={truck} stops={view.live.stops} path={view.live.path} fitKey={`${token}:${view.live.stops.length}:${truck ? 1 : 0}`} />
            ) : (
              <Stack alignItems="center" justifyContent="center" sx={{ height: 360, color: 'text.secondary', textAlign: 'center', px: 3 }}>
                <Place sx={{ fontSize: 44, mb: 1 }} />
                <Typography>{delivered ? 'The load has been delivered.' : 'The live map shows once the truck is on its way.'}</Typography>
              </Stack>
            )}
          </Paper>
          <Paper sx={{ p: 2.5, borderRadius: 3 }}>
            <Typography variant="subtitle2" gutterBottom>
              Shipment
            </Typography>
            <Stack spacing={1.5}>
              {view.equipment?.truck && (
                <Stack direction="row" spacing={1.25} alignItems="center">
                  <LocalShipping color="action" />
                  <Typography variant="body2">
                    Truck <b>{view.equipment.truck}</b>
                    {view.equipment.trailer ? (
                      <>
                        {' '}
                        · Trailer <b>{view.equipment.trailer}</b>
                      </>
                    ) : null}
                  </Typography>
                </Stack>
              )}
              {view.equipment?.temperature && (
                <Stack direction="row" spacing={1.25} alignItems="center">
                  <Thermostat color="action" />
                  <Typography variant="body2">Temperature {view.equipment.temperature}</Typography>
                </Stack>
              )}
              {truck && (
                <>
                  <Stack direction="row" spacing={1.25} alignItems="flex-start">
                    <Place color="action" />
                    <Box>
                      <Typography variant="body2">{truck.address || 'On the road'}</Typography>
                      <Typography variant="caption" color="text.secondary">
                        Last seen {ago(truck.at)}
                      </Typography>
                    </Box>
                  </Stack>
                  {(truck.speedMph || 0) > 3 ? (
                    <Stack direction="row" spacing={1.25} alignItems="center">
                      <Speed color="action" />
                      <Typography variant="body2">Moving · {Math.round(truck.speedMph || 0)} mph</Typography>
                    </Stack>
                  ) : (
                    <Stack direction="row" spacing={1.25} alignItems="flex-start" data-testid="trackStopped">
                      <PauseCircle sx={{ color: '#D97706' }} />
                      <Box>
                        <Typography variant="body2" fontWeight={600}>
                          Stopped{view.live?.stopped?.minutes ? ` · ${span(view.live.stopped.minutes)}` : ''}
                          {view.live?.stopped?.reason ? ` · ${view.live.stopped.reason}` : ''}
                        </Typography>
                        {view.live?.stopped?.since && (
                          <Typography variant="caption" color="text.secondary">
                            Since {when(view.live.stopped.since, dest?.timezone)}
                          </Typography>
                        )}
                      </Box>
                    </Stack>
                  )}
                </>
              )}
              {view.live?.miles !== null && view.live?.miles !== undefined && !delivered && (
                <Stack direction="row" spacing={1.25} alignItems="center">
                  <Timeline color="action" />
                  <Typography variant="body2">{view.live.miles.toLocaleString()} miles to go</Typography>
                </Stack>
              )}
              {view.nextStop && !delivered && (
                <Stack direction="row" spacing={1.25} alignItems="center">
                  <AccessTime color="action" />
                  <Typography variant="body2">
                    Next: {STOP_WORD[view.nextStop.type]} · {view.nextStop.name || view.nextStop.place}
                  </Typography>
                </Stack>
              )}
            </Stack>
          </Paper>
        </Box>

        {/* Breaks the ETA already includes */}
        {!delivered && (view.live?.breaks?.length || 0) > 0 && (
          <Paper sx={{ p: 2.5, borderRadius: 3 }} data-testid="trackBreaks">
            <Stack direction="row" alignItems="baseline" spacing={1} sx={{ mb: 1.5 }}>
              <Typography variant="subtitle2" sx={{ flexGrow: 1 }}>
                Breaks on the way
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Already included in the ETA
              </Typography>
            </Stack>
            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(3, 1fr)' }, gap: 1.25 }}>
              {view.live!.breaks!.map((b, i) => {
                const info = BREAK_INFO[b.kind];
                const Icon = info.icon;
                return (
                  <Stack key={i} direction="row" spacing={1.25} sx={{ p: 1.25, borderRadius: 2, bgcolor: '#F8FAFC', border: 1, borderColor: '#E2E8F0' }}>
                    <Icon sx={{ color: info.color, mt: 0.25 }} />
                    <Box>
                      <Typography variant="body2" fontWeight={700}>
                        {info.label} · {span(b.minutes)}
                      </Typography>
                      <Typography variant="caption" color="text.secondary" component="div">
                        Around {when(b.at, dest?.timezone)} · mile {b.atMile.toLocaleString()}
                      </Typography>
                      <Typography variant="caption" color="text.secondary" component="div">
                        {info.why}
                      </Typography>
                    </Box>
                  </Stack>
                );
              })}
            </Box>
          </Paper>
        )}

        {/* Stops + activity */}
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '3fr 2fr' }, gap: 2.5 }}>
          <Paper sx={{ p: 2.5, borderRadius: 3 }} data-testid="trackStops">
            <Typography variant="subtitle2" sx={{ mb: 1.5 }}>
              Stops
            </Typography>
            {stops.map((s, i) => (
              <Stack key={s.id} direction="row" spacing={1.75}>
                <Stack alignItems="center" sx={{ width: 18 }}>
                  <Box
                    sx={{
                      width: 14,
                      height: 14,
                      mt: 0.5,
                      borderRadius: '50%',
                      bgcolor: s.state === 'done' ? '#16A34A' : s.state === 'next' ? '#1D4ED8' : 'white',
                      border: 2,
                      borderColor: s.state === 'upcoming' ? '#CBD5E1' : 'transparent',
                    }}
                  />
                  {i < stops.length - 1 && <Box sx={{ flexGrow: 1, width: 2, bgcolor: '#E5E7EB', my: 0.5 }} />}
                </Stack>
                <Box sx={{ pb: 2.25, flexGrow: 1 }}>
                  <Typography variant="caption" fontWeight={700} color={s.type === 'pickup' ? 'success.main' : s.type === 'drop' ? 'error.main' : 'warning.main'}>
                    {STOP_WORD[s.type].toUpperCase()}
                    {s.state === 'next' ? ' · NEXT' : ''}
                  </Typography>
                  <Typography variant="body1" fontWeight={600}>
                    {s.name || s.place}
                  </Typography>
                  {s.address && (
                    <Typography variant="body2" color="text.secondary">
                      {s.address}
                    </Typography>
                  )}
                  <Typography variant="caption" color="text.secondary" component="div" sx={{ mt: 0.5 }}>
                    {s.appointment ? `Appointment ${appt(s.appointment)}` : 'No appointment'}
                    {s.arrivedAt ? ` · Arrived ${when(s.arrivedAt, s.timezone)}` : ''}
                    {s.departedAt ? ` · Left ${when(s.departedAt, s.timezone)}` : ''}
                  </Typography>
                </Box>
              </Stack>
            ))}
          </Paper>
          <Paper sx={{ p: 2.5, borderRadius: 3 }} data-testid="trackActivity">
            <Typography variant="subtitle2" sx={{ mb: 1.5 }}>
              Activity
            </Typography>
            <Stack spacing={1.5}>
              {(view.activity || []).map((a, i) => (
                <Stack key={i} direction="row" spacing={1.5}>
                  <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: i === 0 ? '#1D4ED8' : '#CBD5E1', mt: 0.9, flexShrink: 0 }} />
                  <Box>
                    <Typography variant="body2" fontWeight={i === 0 ? 700 : 500}>
                      {a.text}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {when(a.at)}
                    </Typography>
                  </Box>
                </Stack>
              ))}
            </Stack>
          </Paper>
        </Box>
        <Typography variant="caption" color="text.secondary" sx={{ textAlign: 'center' }}>
          Updated {ago(view.updatedAt)} · refreshes every minute
        </Typography>
      </Stack>
    </Shell>
  );
}
