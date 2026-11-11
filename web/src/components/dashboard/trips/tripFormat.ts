import type { LoadStatus, LoadType, Trip, TripStatus, TripStop } from '@/redux/TripApiSlice';

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

export const STOP_LABEL = { pickup: 'Pickup', drop: 'Drop', switch: 'Meet point', yard: 'Our yard' } as const;

// ---------- loads with legs ----------

export const LOAD_TYPE: Record<LoadType, { label: string; short: string; help: string }> = {
  direct: { label: 'Direct', short: 'Direct', help: 'One driver: pickup → delivery' },
  via_yard: { label: 'Via our yard', short: 'Via yard', help: 'Pickup → drop the trailer at our yard → the same or another driver / truck takes it to the delivery' },
  relay: { label: 'Relay / transfer', short: 'Relay', help: 'Pickup → meet another driver on the road → they take the load to the delivery' },
  trailer_move: { label: 'Trailer move', short: 'Trailer move', help: 'Move a trailer (empty or loaded) from one place to another' },
};

export const LOAD_STATUS: Record<LoadStatus, { label: string; color: 'default' | 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'info' }> = {
  scheduled: { label: 'Scheduled', color: 'default' },
  waiting: { label: 'Driver waiting', color: 'warning' },
  active: { label: 'On the road', color: 'primary' },
  transfer: { label: 'Ready to transfer', color: 'warning' },
  delivered: { label: 'Delivered', color: 'secondary' },
  completed: { label: 'Completed', color: 'success' },
  cancelled: { label: 'Cancelled', color: 'default' },
};

/** Loads screen tabs: the ones that need dispatch first */
export const LOAD_TABS: { key: string; label: string; status: string }[] = [
  { key: 'all', label: 'All', status: '' },
  { key: 'transfer', label: 'Ready to transfer', status: 'transfer' },
  { key: 'waiting', label: 'Driver waiting', status: 'waiting' },
  { key: 'scheduled', label: 'Scheduled', status: 'scheduled' },
  { key: 'active', label: 'On the road', status: 'active' },
  { key: 'delivered', label: 'Delivered', status: 'delivered' },
  { key: 'completed', label: 'Completed', status: 'completed' },
];

export const legsInOrder = (legs?: Trip[]) => [...(legs || [])].sort((a, b) => a.leg_no - b.leg_no);

/** The leg dispatch needs to look at now: waiting for them, on the road, or the next one to go. */
export function currentLeg(legs?: Trip[]): Trip | undefined {
  const list = legsInOrder(legs).filter((l) => l.status !== 'cancelled');
  return (
    list.find((l) => l.status === 'offered') ||
    list.find((l) => ['planned', 'accepted', 'started', 'rolling', 'on_hold'].includes(l.status)) ||
    list.find((l) => ['scheduled'].includes(l.status)) ||
    list.find((l) => ['ended', 'paperwork'].includes(l.status)) ||
    list[list.length - 1]
  );
}

/** "45 min", "3 h 10 min", "2 d 4 h" */
export function minutesText(min: number | null | undefined): string {
  if (min === null || min === undefined) return '—';
  const m = Math.abs(Math.round(min));
  const d = Math.floor(m / 1440);
  const h = Math.floor((m % 1440) / 60);
  const r = m % 60;
  return [d ? `${d} d` : '', h ? `${h} h` : '', !d && r ? `${r} min` : ''].filter(Boolean).join(' ') || '0 min';
}

/** "+40 min late" / "25 min early" / "on time" for a difference in minutes (positive = late). */
export function lateText(min: number | null | undefined): string {
  if (min === null || min === undefined) return '—';
  if (Math.abs(min) <= 15) return 'On time';
  return `${minutesText(min)} ${min > 0 ? 'late' : 'early'}`;
}

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
