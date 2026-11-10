'use client';

import * as React from 'react';
import dynamic from 'next/dynamic';
import { Alert, Box, Chip, IconButton, LinearProgress, Skeleton, Stack, Tooltip, Typography } from '@mui/material';
import { LocalGasStation, Refresh, Route, Schedule, Speed } from '@mui/icons-material';

import { LiveStopEta, LiveTrip, useGetLoadLiveQuery } from '@/redux/TripApiSlice';

import { STOP_LABEL } from './tripFormat';

// Live tracking in the trip panel: where the truck is (Samsara), the road ahead and every ETA
// (Google, with traffic, plus hours-of-service rest for a solo driver), fuel on board and diesel to
// finish. Refreshes every 30 seconds while open.

const TripMap = dynamic(() => import('./TripMap'), { ssr: false, loading: () => <Skeleton variant="rounded" height={320} /> });

const STALE_MINUTES = 30;

export const duration = (minutes: number | null | undefined) => {
  if (minutes === null || minutes === undefined) return '—';
  const m = Math.max(0, Math.round(minutes));
  const d = Math.floor(m / 1440);
  const h = Math.floor((m % 1440) / 60);
  const min = m % 60;
  return [d ? `${d} d` : '', h ? `${h} h` : '', !d && min ? `${min} min` : ''].filter(Boolean).join(' ') || '0 min';
};

const when = (iso?: string | null) =>
  iso ? new Intl.DateTimeFormat('en-US', { weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }).format(new Date(iso)) : '—';

/** Short form for the summary card: "Nov 11, 4:39 PM" */
const whenShort = (iso?: string | null) =>
  iso ? new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }).format(new Date(iso)) : '—';

const ago = (iso: string) => {
  const minutes = (Date.now() - new Date(iso).getTime()) / 60_000;
  return minutes < 1 ? 'just now' : `${duration(minutes)} ago`;
};

function Punctuality({ late }: { late: number | null }) {
  if (late === null) return <Chip size="small" variant="outlined" label="No appointment" />;
  if (Math.abs(late) <= 15) return <Chip size="small" color="success" label="On time" />;
  return late > 0 ? <Chip size="small" color="error" label={`${duration(late)} late`} /> : <Chip size="small" color="success" variant="outlined" label={`${duration(-late)} early`} />;
}

function Stat({ icon, label, value, caption, children }: { icon: React.ReactNode; label: string; value: string; caption?: string; children?: React.ReactNode }) {
  return (
    <Box sx={{ p: 1.5, borderRadius: 2, border: 1, borderColor: 'divider', minWidth: 0 }}>
      <Stack direction="row" spacing={0.75} alignItems="center" sx={{ color: 'text.secondary' }}>
        {icon}
        <Typography variant="caption">{label}</Typography>
      </Stack>
      <Typography variant="subtitle1" fontWeight={700} noWrap>
        {value}
      </Typography>
      {children}
      {caption && (
        <Typography variant="caption" color="text.secondary" component="div" noWrap title={caption}>
          {caption}
        </Typography>
      )}
    </Box>
  );
}

function truckState(live: LiveTrip) {
  const t = live.truck;
  if (!t) return { value: 'No position', caption: live.truckProblem || '' };
  const moving = (t.speedMph || 0) > 3;
  const value = moving ? `Moving · ${Math.round(t.speedMph || 0)} mph` : t.engine === 'Idle' || t.engine === 'On' ? 'Stopped · engine on' : 'Parked · engine off';
  return { value, caption: t.address || '' };
}

export function TripLivePanel({ tripId }: { tripId: number }): React.JSX.Element {
  const { data, isFetching, refetch, error } = useGetLoadLiveQuery(tripId, { pollingInterval: 30_000 });
  const live = data?.data;

  if (!live) {
    return error ? (
      <Alert severity="warning">Live tracking isn't available right now.</Alert>
    ) : (
      <Stack spacing={1}>
        <Skeleton variant="rounded" height={72} />
        <Skeleton variant="rounded" height={320} />
      </Stack>
    );
  }

  const t = live.truck;
  const stale = t ? (Date.now() - new Date(t.at).getTime()) / 60_000 > STALE_MINUTES : false;
  const state = truckState(live);
  const fuel = t?.fuelPercent ?? null;
  const fitKey = `${tripId}:${live.stops.map((s) => s.stopId).join(',')}:${t ? 'truck' : 'no-truck'}`;

  return (
    <Stack spacing={1.5}>
      <Stack direction="row" alignItems="center" spacing={1}>
        <Typography variant="subtitle2" sx={{ flexGrow: 1 }}>
          Live tracking
        </Typography>
        <Typography variant="caption" color="text.secondary">
          {t ? `Samsara · ${ago(t.at)}` : ''}
        </Typography>
        <Tooltip title="Refresh now">
          <IconButton size="small" onClick={() => void refetch()}>
            <Refresh fontSize="small" />
          </IconButton>
        </Tooltip>
      </Stack>
      {isFetching && <LinearProgress sx={{ mt: -1 }} />}

      {stale && t && (
        <Alert severity="warning">
          Samsara last saw truck {t.vehicleName || ''} {ago(t.at)} — the position and ETAs may be out of date (tracker offline or truck parked).
        </Alert>
      )}
      {!t && live.truckProblem && <Alert severity="info">{live.truckProblem}</Alert>}
      {live.routeProblem && <Alert severity="warning">{live.routeProblem}</Alert>}

      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr 1fr', md: 'repeat(4, 1fr)' }, gap: 1 }}>
        <Stat icon={<Speed fontSize="small" />} label="Truck" value={state.value} caption={state.caption} />
        <Stat
          icon={<LocalGasStation fontSize="small" />}
          label="Fuel"
          value={fuel === null ? '—' : `${Math.round(fuel)}%`}
          caption={live.fuelGallons !== null ? `~${live.fuelGallons} gal diesel to finish` : undefined}
        >
          {fuel !== null && (
            <LinearProgress
              variant="determinate"
              value={Math.min(100, Math.max(0, fuel))}
              color={fuel < 20 ? 'error' : fuel < 40 ? 'warning' : 'success'}
              sx={{ height: 6, borderRadius: 3, my: 0.5 }}
            />
          )}
        </Stat>
        <Stat
          icon={<Route fontSize="small" />}
          label="Remaining"
          value={live.miles !== null ? `${live.miles.toLocaleString()} mi` : '—'}
          caption={live.driveMinutes !== null ? `${duration(live.driveMinutes)} driving (traffic)` : undefined}
        />
        <Stat
          icon={<Schedule fontSize="small" />}
          label="Final ETA"
          value={whenShort(live.eta)}
          caption={live.eta ? (live.team ? 'Team — no rest stops' : `Includes ${duration(live.restMinutes)} rest (solo hours)`) : undefined}
        />
      </Box>

      <TripMap truck={t} stops={live.stops} path={live.path} fitKey={fitKey} />

      {live.stops.length > 0 && (
        <Stack spacing={0.75}>
          {live.stops.map((s: LiveStopEta) => (
            <Stack key={s.stopId} direction="row" spacing={1} alignItems="center" sx={{ p: 1, borderRadius: 1.5, bgcolor: 'action.hover' }}>
              <Chip size="small" label={STOP_LABEL[s.type]} color={s.type === 'pickup' ? 'primary' : 'default'} />
              <Box sx={{ flexGrow: 1, minWidth: 0 }}>
                <Typography variant="body2" fontWeight={600} noWrap>
                  {s.name || s.place}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {s.place} · {s.miles.toLocaleString()} mi · {duration(s.driveMinutes)} drive · ETA {when(s.eta)}
                </Typography>
              </Box>
              <Punctuality late={s.lateMinutes} />
            </Stack>
          ))}
        </Stack>
      )}
      <Typography variant="caption" color="text.secondary">
        Route and drive times: Google Maps (car roads with live traffic — allow extra for truck routing). Truck position, speed and fuel: Samsara.
      </Typography>
    </Stack>
  );
}
