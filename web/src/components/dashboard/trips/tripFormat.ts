import type { Trip, TripStatus, TripStop } from '@/redux/TripApiSlice';

// Labels and time formatting shared by the Loads screen, the trip panel and Send load.

export const STATUS: Record<TripStatus, { label: string; color: 'default' | 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'info' }> = {
  scheduled: { label: 'Scheduled', color: 'default' },
  offered: { label: 'Driver waiting', color: 'warning' },
  planned: { label: 'Sent', color: 'info' },
  accepted: { label: 'Accepted', color: 'info' },
  started: { label: 'Started', color: 'primary' },
  rolling: { label: 'Rolling', color: 'primary' },
  ended: { label: 'Delivered', color: 'secondary' },
  paperwork: { label: 'Paperwork', color: 'secondary' },
  completed: { label: 'Completed', color: 'success' },
  routed: { label: 'Priced', color: 'success' },
  on_hold: { label: 'On hold', color: 'error' },
  cancelled: { label: 'Cancelled', color: 'default' },
};

export const TABS: { key: string; label: string; status: string }[] = [
  { key: 'all', label: 'All', status: '' },
  { key: 'waiting', label: 'Driver waiting', status: 'offered' },
  { key: 'scheduled', label: 'Scheduled', status: 'scheduled' },
  { key: 'active', label: 'Active', status: 'planned,accepted,started,rolling,on_hold' },
  { key: 'delivered', label: 'Delivered', status: 'ended,paperwork' },
  { key: 'completed', label: 'Completed', status: 'completed,routed' },
];

/** The tab a load in [status] is listed under (not counting All). */
export const tabOf = (status: string) => TABS.find((t) => t.status && t.status.split(',').includes(status))?.key || 'all';

export const PROBLEM_KINDS: Record<string, string> = {
  delay: 'Delay',
  breakdown: 'Breakdown',
  detention: 'Detention',
  lumper: 'Lumper',
  rejected: 'Load rejected',
  shortage: 'Shortage',
  damage: 'Damage',
  other: 'Other',
};

export const STOP_LABEL = { pickup: 'Pickup', drop: 'Drop', switch: 'Switch' } as const;

const sorted = (stops?: TripStop[]) => [...(stops || [])].sort((a, b) => a.seq - b.seq);

/** "11/06 03:15 AM" from the stop's own local time (as dispatch typed it). */
export function appointment(local?: string | null): string {
  if (!local) return '—';
  const [d, t = '00:00'] = local.split('T');
  const [, m, day] = d.split('-');
  const [hh, mm] = t.split(':').map(Number);
  return `${m}/${day} ${String(hh % 12 || 12).padStart(2, '0')}:${String(mm).padStart(2, '0')} ${hh >= 12 ? 'PM' : 'AM'}`;
}

/** A real moment shown in the stop's time zone, with the zone ("11/06 02:58 AM PST"). */
export function atStop(iso?: string | null, timeZone?: string | null): string {
  if (!iso) return '—';
  return new Intl.DateTimeFormat('en-US', {
    timeZone: timeZone || undefined,
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    timeZoneName: 'short',
  }).format(new Date(iso));
}

export const place = (s?: TripStop) => (s ? [s.name, [s.city, s.state].filter(Boolean).join(', ')].filter(Boolean).join(' · ') : '—');

export const firstLast = (trip: Trip) => {
  const list = sorted(trip.stops);
  return { first: list[0], last: list[list.length - 1], count: list.length };
};

export const tripLabel = (trip: Pick<Trip, 'trip_no' | 'id'>) => `#${trip.trip_no || trip.id}`;

/** Late = an appointment passed and the driver hasn't arrived there. */
export function isLate(trip: Trip): boolean {
  if (!['planned', 'accepted', 'started', 'rolling'].includes(trip.status)) return false;
  return sorted(trip.stops).some((s) => !s.arrived_at && s.appointment_at && new Date(s.appointment_at).getTime() < Date.now());
}
