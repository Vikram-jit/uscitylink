import { apiSlice } from './apiSlice';

// Trips (loads sent to drivers): server/src/services/trips. Loads screen, Send load, trip panel.

export type TripStatus =
  | 'scheduled'
  | 'offered'
  | 'planned'
  | 'accepted'
  | 'started'
  | 'rolling'
  | 'ended'
  | 'paperwork'
  | 'completed'
  | 'routed'
  | 'on_hold'
  | 'cancelled';

export type StopType = 'pickup' | 'drop' | 'switch';

export interface TripStop {
  id: number;
  seq: number;
  type: StopType;
  name: string | null;
  street: string | null;
  city: string | null;
  state: string | null;
  zip: string | null;
  /** The stop's own local time, "2026-11-06T03:15" */
  appointment_local: string | null;
  appointment_at: string | null;
  timezone: string | null;
  arrived_at: string | null;
  departed_at: string | null;
  ref: string | null;
  mileage: string | null;
}

export interface TripEvent {
  id: number;
  type: string;
  from_status: string | null;
  to_status: string | null;
  stop_id: number | null;
  actor_role: 'driver' | 'dispatcher' | 'accountant' | 'ai' | 'system';
  actor_name: string | null;
  note: string | null;
  data: Record<string, any> | null;
  lat: string | null;
  lng: string | null;
  happened_at: string;
}

export interface TripProblem {
  id: number;
  kind: string;
  note: string | null;
  amount: string | null;
  opened_by_name: string | null;
  resolved_at: string | null;
  resolved_by_name: string | null;
  created_at: string;
}

export interface Trip {
  id: number;
  trip_no: string | null;
  status: TripStatus;
  source: 'form' | 'typed';
  needs_review: boolean;
  review_notes: string | null;
  driver_profile_id: string | null;
  channel_id: string | null;
  driver_id_1: number | null;
  driver_id_2: number | null;
  truck_number: string | null;
  trailer_numbers: string | null;
  temperature: string | null;
  loaded_trailer: boolean;
  notes: string | null;
  planned_start_at: string | null;
  sent_at: string | null;
  started_at: string | null;
  ended_at: string | null;
  completed_at: string | null;
  completed_by_name: string | null;
  total_mileage: string | null;
  driver_pay_details_id: number | null;
  /** The yard Route List trip id, given when dispatch marks the trip completed */
  route_trip_no: string | null;
  created_by_name: string | null;
  created_at: string;
  stops?: TripStop[];
  events?: TripEvent[];
  problems?: TripProblem[];
}

export interface StopInput {
  type: StopType;
  name?: string;
  street?: string;
  city?: string;
  state?: string;
  zip?: string;
  appointment?: string | null;
  ref?: string;
}

export interface TripInput {
  driverProfileId?: string | null;
  truckNumber?: string | null;
  teamDriverProfileId?: string | null;
  trailerNumbers?: string[];
  temperature?: string | null;
  loadedTrailer?: boolean;
  notes?: string | null;
  channelId?: string | null;
  stops: StopInput[];
  needsReview?: boolean;
}

export interface ParsedLoad {
  stops: { type: StopType; name: string; street: string; city: string; state: string; zip: string; appointment: string | null }[];
  truck: string | null;
  trailers: string[];
  team: string[];
  temperature: string | null;
  loadedTrailer: boolean;
  needsReview: boolean;
  reasons: string[];
}

/** A truck and the driver(s) its truck group assigns (two for a team). */
export interface TruckAssignment {
  truck: string;
  drivers: { id: string; name: string }[];
}

/** Trip panel map: the truck now (Samsara) and the road ahead (Google) — server/src/services/trips/liveTrip.ts */
export interface LiveTruck {
  lat: number;
  lng: number;
  headingDegrees: number | null;
  speedMph: number | null;
  address: string | null;
  at: string;
  fuelPercent: number | null;
  engine: string | null;
  vehicleName: string | null;
}

export interface LiveStopEta {
  stopId: number;
  seq: number;
  type: StopType;
  name: string | null;
  place: string;
  lat: number | null;
  lng: number | null;
  miles: number;
  driveMinutes: number;
  eta: string;
  lateMinutes: number | null;
}

export interface LiveTrip {
  truck: LiveTruck | null;
  truckProblem: string | null;
  stops: LiveStopEta[];
  miles: number | null;
  driveMinutes: number | null;
  restMinutes: number | null;
  team: boolean;
  eta: string | null;
  fuelGallons: number | null;
  path: [number, number][];
  routeProblem: string | null;
  updatedAt: string;
}

export type TripActionName = 'accept' | 'start' | 'rolling' | 'arrive' | 'depart' | 'end' | 'paperwork' | 'complete' | 'hold' | 'resume' | 'cancel';

interface Res<T> {
  status: boolean;
  message?: string;
  data: T;
}

export const TripApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    // Named getLoads/getLoad: AutomationApiSlice already has a getTrips (the scale agent's routes) and
    // RTK keeps the first endpoint of a name, so a second getTrips silently called that one instead
    getLoads: builder.query<
      Res<{ trips: Trip[]; total: number; page: number; counts: Record<string, number>; driverNames: Record<string, string> }>,
      { status?: string; q?: string; driverProfileId?: string; page?: number; limit?: number }
    >({
      query: (params) => ({ url: 'trips', method: 'GET', params }),
      providesTags: ['chatTrips'],
    }),
    getLoad: builder.query<Res<{ trip: Trip; driverNames: Record<string, string> }>, number>({
      query: (id) => ({ url: `trips/${id}`, method: 'GET' }),
      providesTags: ['chatTrips'],
    }),
    getTruckAssignments: builder.query<Res<TruckAssignment[]>, string>({
      query: (q) => ({ url: 'trips/trucks', method: 'GET', params: { q } }),
      keepUnusedDataFor: 60,
    }),
    getDriverAssignment: builder.query<Res<TruckAssignment | null>, string>({
      query: (profileId) => ({ url: `trips/drivers/${profileId}/truck`, method: 'GET' }),
      keepUnusedDataFor: 60,
    }),
    getLoadLive: builder.query<Res<LiveTrip>, number>({
      query: (id) => ({ url: `trips/${id}/live`, method: 'GET' }),
      keepUnusedDataFor: 0,
    }),
    parseTripText: builder.mutation<Res<ParsedLoad>, string>({
      query: (text) => ({ url: 'trips/parse', method: 'POST', body: { text } }),
    }),
    createTrip: builder.mutation<Res<Trip>, TripInput & { send?: boolean }>({
      query: (body) => ({ url: 'trips', method: 'POST', body }),
      invalidatesTags: ['chatTrips'],
    }),
    editTrip: builder.mutation<Res<Trip>, { id: number } & Partial<TripInput>>({
      query: ({ id, ...body }) => ({ url: `trips/${id}`, method: 'PATCH', body }),
      invalidatesTags: ['chatTrips'],
    }),
    sendTrip: builder.mutation<Res<Trip>, number>({
      query: (id) => ({ url: `trips/${id}/send`, method: 'POST' }),
      invalidatesTags: ['chatTrips'],
    }),
    declineOffer: builder.mutation<Res<Trip>, number>({
      query: (id) => ({ url: `trips/${id}/decline-offer`, method: 'POST' }),
      invalidatesTags: ['chatTrips'],
    }),
    tripAction: builder.mutation<Res<Trip>, { id: number; action: TripActionName; note?: string; stopId?: number }>({
      query: ({ id, ...body }) => ({ url: `trips/${id}/action`, method: 'POST', body }),
      invalidatesTags: ['chatTrips'],
    }),
    undoTrip: builder.mutation<Res<Trip>, number>({
      query: (id) => ({ url: `trips/${id}/undo`, method: 'POST' }),
      invalidatesTags: ['chatTrips'],
    }),
    addTripProblem: builder.mutation<Res<Trip>, { id: number; kind: string; note?: string; amount?: number | null; hold?: boolean }>({
      query: ({ id, ...body }) => ({ url: `trips/${id}/problems`, method: 'POST', body }),
      invalidatesTags: ['chatTrips'],
    }),
    resolveTripProblem: builder.mutation<Res<Trip>, { id: number; problemId: number }>({
      query: ({ id, problemId }) => ({ url: `trips/${id}/problems/${problemId}/resolve`, method: 'PATCH' }),
      invalidatesTags: ['chatTrips'],
    }),
  }),
});

export const {
  useGetLoadsQuery,
  useGetLoadQuery,
  useGetLoadLiveQuery,
  useParseTripTextMutation,
  useGetTruckAssignmentsQuery,
  useLazyGetDriverAssignmentQuery,
  useCreateTripMutation,
  useEditTripMutation,
  useSendTripMutation,
  useDeclineOfferMutation,
  useTripActionMutation,
  useUndoTripMutation,
  useAddTripProblemMutation,
  useResolveTripProblemMutation,
} = TripApiSlice;
