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

/** yard: our yard (a leg drops the trailer for the next leg) · switch: a meet point (relay) */
export type StopType = 'pickup' | 'drop' | 'switch' | 'yard';

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
  /** The load this trip is a leg of */
  load_id: number | null;
  leg_no: number;
  /** Place in the driver's lineup while lined up (1 = next) */
  queue_pos: number | null;
  ends_at_yard: boolean;
  /** ETA when the leg went Rolling */
  planned_eta_at: string | null;
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
  /** Required before Mark completed */
  invoice_no: string | null;
  loaded_trailer: boolean;
  notes: string | null;
  planned_start_at: string | null;
  sent_at: string | null;
  started_at: string | null;
  ended_at: string | null;
  completed_at: string | null;
  completed_by_name: string | null;
  total_mileage: string | null;
  /** samsara (odometer) | manual (typed by dispatch) */
  miles_source: 'samsara' | 'manual' | null;
  miles_note: string | null;
  /** Why this leg was cut and handed to another driver / truck */
  handover_reason: string | null;
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
  invoiceNo?: string | null;
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

// ---------- loads with legs (server/src/services/trips/loadService.ts) ----------

export type LoadType = 'direct' | 'via_yard' | 'relay' | 'trailer_move';
export type LoadStatus = 'scheduled' | 'waiting' | 'active' | 'transfer' | 'delivered' | 'completed' | 'cancelled';

export interface Load {
  id: number;
  load_no: string | null;
  invoice_no: string | null;
  type: LoadType;
  status: LoadStatus;
  notes: string | null;
  created_by_name: string | null;
  created_at: string;
  /** Legs in order (list: with stops) */
  legs?: Trip[];
}

export interface YardVisit {
  trailer: string | null;
  inAt: string;
  outAt: string | null;
  minutes: number;
  loaded: string | null;
  source: 'gate' | 'leg';
}

export interface DeliveryTiming {
  deliveredAt: string | null;
  appointmentAt: string | null;
  etaAt: string | null;
  lateMinutes: number | null;
  etaOffMinutes: number | null;
  etaVsAppointmentMinutes: number | null;
}

/** One driver / truck part of a load */
export interface LoadSegment {
  legId: number;
  legNo: number;
  tripNo: string | null;
  status: TripStatus;
  driverProfileId: string | null;
  drivers: string[];
  truck: string | null;
  trailers: string | null;
  from: string;
  to: string;
  startedAt: string | null;
  endedAt: string | null;
  minutes: number | null;
  miles: number | null;
  milesSource: 'samsara' | 'manual' | null;
  milesNote: string | null;
  handoverReason: string | null;
}

export interface LoadHistoryEntry {
  at: string;
  legNo: number;
  tripNo: string | null;
  type: string;
  from: string | null;
  to: string | null;
  note: string | null;
  actor: string;
  actorRole: string;
  data: any;
}

export interface HandoverPlace {
  type?: 'yard' | 'switch';
  name?: string | null;
  street?: string | null;
  city?: string | null;
  state?: string | null;
  zip?: string | null;
}

export interface MilesItem {
  legId: number;
  loadId: number | null;
  tripNo: string | null;
  invoiceNo: string | null;
  truck: string | null;
  drivers: string[];
  from: string;
  to: string;
  startedAt: string | null;
  endedAt: string | null;
  hours: number | null;
  miles: number | null;
  milesSource: string | null;
}
export interface MilesRow {
  key: string;
  name: string;
  legs: number;
  loads: number;
  miles: number;
  hours: number;
  missing: number;
  others: string[];
  items: MilesItem[];
}

export interface LoadDetail {
  load: Load;
  legs: Trip[];
  segments: LoadSegment[];
  milesTotals: { miles: number; missing: number; byDriver: Record<string, number>; byTruck: Record<string, number> };
  history: LoadHistoryEntry[];
  driverNames: Record<string, string>;
  yardVisits: YardVisit[];
  yardMinutes: number;
  timing: DeliveryTiming | null;
}

export interface LegInput extends TripInput {
  teamNames?: string[];
}

export interface LoadInput {
  type: LoadType;
  invoiceNo?: string | null;
  notes?: string | null;
  legs: LegInput[];
}

export interface LegRef {
  loadId: number | null;
  tripId: number;
  tripNo: string | null;
  invoiceNo: string | null;
  status: TripStatus;
  legNo: number;
}

export interface FleetTruck {
  id: number;
  number: string;
  state: 'on_load' | 'lined_up' | 'free';
  leg: LegRef | null;
  drivers: { id: string; name: string }[];
}
export interface FleetTrailer {
  id: number;
  number: string;
  type: string | null;
  readiness: string | null;
  state: 'on_load' | 'waiting_transfer' | 'in_yard' | 'out' | 'unknown';
  leg: LegRef | null;
  gate: { status: 'entry' | 'depart'; loaded: string | null; at: string } | null;
}
export interface FleetDriver {
  yardId: number;
  name: string;
  profileId: string | null;
  truck: string | null;
  state: 'on_load' | 'lined_up' | 'free';
  leg: LegRef | null;
  /** Loads lined up after the current one, and #1 */
  lineup: number;
  next: LegRef | null;
}

// ---------- a driver's lineup (server/src/services/trips/lineup.ts) ----------

export interface LineupStop {
  type: StopType;
  name: string | null;
  city: string | null;
  state: string | null;
  appointmentLocal: string | null;
  appointmentAt: string | null;
}
export interface LineupLeg {
  tripId: number;
  loadId: number | null;
  tripNo: string | null;
  invoiceNo: string | null;
  legNo: number;
  legCount: number;
  status: TripStatus;
  truck: string | null;
  trailers: string | null;
  first: LineupStop | null;
  last: LineupStop | null;
  finishAt: string | null;
}
export interface LineupItem extends LineupLeg {
  position: number;
  blockedBy: { legNo: number; tripNo: string | null } | null;
  fit: string | null;
}
export interface DriverLineup {
  driver: { profileId: string; name: string | null; truck: string | null };
  now: LineupLeg | null;
  next: LineupItem[];
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

/** A stop the driver will have to make on the road ahead (US hours-of-service + fuel) */
export interface RoadStop {
  kind: 'break' | 'rest' | 'fuel';
  minutes: number;
  atMile: number;
  afterDrivingMinutes: number;
  at: string;
}

/** driving + breaks + rests + fuel stops = total */
export interface EtaPlan {
  googleMinutes: number;
  drivingMinutes: number;
  breakMinutes: number;
  restMinutes: number;
  fuelMinutes: number;
  totalMinutes: number;
  stops: RoadStop[];
}

export interface LiveTrip {
  truck: LiveTruck | null;
  truckProblem: string | null;
  stops: LiveStopEta[];
  miles: number | null;
  driveMinutes: number | null;
  restMinutes: number | null;
  plan: EtaPlan | null;
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
    getLoad: builder.query<
      Res<{
        trip: Trip;
        driverNames: Record<string, string>;
        /** Its place in the load; blockedBy = the leg before still has the load (can't send yet) */
        leg?: {
          count: number;
          isLast: boolean;
          blockedBy: { legNo: number; tripNo: string | null; status: TripStatus; endsAtYard: boolean; driverName?: string | null; place?: string | null } | null;
        };
      }>,
      number
    >({
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
    // Loads with legs. Names kept unique across slices (RTK keeps the first endpoint of a name)
    listLoadBoard: builder.query<
      Res<{ loads: Load[]; total: number; page: number; counts: Record<string, number>; driverNames: Record<string, string> }>,
      { status?: string; q?: string; page?: number; limit?: number }
    >({
      query: (params) => ({ url: 'loads', method: 'GET', params }),
      providesTags: ['chatTrips'],
    }),
    getLoadDetail: builder.query<Res<LoadDetail>, number>({
      query: (id) => ({ url: `loads/${id}`, method: 'GET' }),
      providesTags: ['chatTrips'],
    }),
    createLoadWithLegs: builder.mutation<Res<LoadDetail>, LoadInput & { send?: boolean }>({
      query: (body) => ({ url: 'loads', method: 'POST', body }),
      invalidatesTags: ['chatTrips'],
    }),
    updateLoadInfo: builder.mutation<Res<LoadDetail>, { id: number; invoiceNo?: string | null; notes?: string | null; type?: LoadType }>({
      query: ({ id, ...body }) => ({ url: `loads/${id}`, method: 'PATCH', body }),
      invalidatesTags: ['chatTrips'],
    }),
    addLoadLeg: builder.mutation<Res<LoadDetail>, { id: number } & LegInput>({
      query: ({ id, ...body }) => ({ url: `loads/${id}/legs`, method: 'POST', body }),
      invalidatesTags: ['chatTrips'],
    }),
    assignLoadLeg: builder.mutation<
      Res<LoadDetail>,
      { id: number; legId: number; driverProfileId?: string | null; truckNumber?: string | null; teamDriverProfileId?: string | null; trailerNumbers?: string[]; send?: boolean }
    >({
      query: ({ id, legId, ...body }) => ({ url: `loads/${id}/legs/${legId}/assign`, method: 'POST', body }),
      invalidatesTags: ['chatTrips'],
    }),
    // Stop address search (Google Places through the server)
    searchStopPlaces: builder.query<Res<{ placeId: string; main: string; secondary: string }[]>, { q: string; session: string }>({
      query: (params) => ({ url: 'loads/places/search', method: 'GET', params }),
      keepUnusedDataFor: 120,
    }),
    getStopPlace: builder.query<
      Res<{ name: string | null; street: string | null; city: string | null; state: string | null; zip: string | null; lat: number | null; lng: number | null }>,
      { placeId: string; session: string }
    >({
      query: ({ placeId, session }) => ({ url: `loads/places/${encodeURIComponent(placeId)}`, method: 'GET', params: { session } }),
    }),
    // Full control of a load: hand over mid-way, undo, change type, correct times, miles
    getLegTruckPlace: builder.query<Res<(HandoverPlace & { at: string | null; address: string | null }) | null>, number>({
      query: (legId) => ({ url: `loads/legs/${legId}/truck-place`, method: 'GET' }),
      keepUnusedDataFor: 0,
    }),
    splitLoadLeg: builder.mutation<
      Res<LoadDetail>,
      {
        id: number;
        legId: number;
        when: 'now' | 'at' | 'plan';
        at?: string | null;
        place: HandoverPlace;
        afterSeq?: number | null;
        driverProfileId?: string | null;
        truckNumber?: string | null;
        teamDriverProfileId?: string | null;
        trailerNumbers?: string[];
        reason: string;
        note?: string | null;
        send?: boolean;
      }
    >({
      query: ({ id, legId, ...body }) => ({ url: `loads/${id}/legs/${legId}/split`, method: 'POST', body }),
      invalidatesTags: ['chatTrips'],
    }),
    releaseLoadLeg: builder.mutation<Res<LoadDetail>, { id: number; legId: number; at?: string | null }>({
      query: ({ id, legId, at }) => ({ url: `loads/${id}/legs/${legId}/release`, method: 'POST', body: { at: at ?? null } }),
      invalidatesTags: ['chatTrips'],
    }),
    undoLoadSplit: builder.mutation<Res<LoadDetail>, { id: number; legId: number }>({
      query: ({ id, legId }) => ({ url: `loads/${id}/legs/${legId}/undo-split`, method: 'POST' }),
      invalidatesTags: ['chatTrips'],
    }),
    changeLoadType: builder.mutation<Res<LoadDetail>, { id: number; type: LoadType; place?: HandoverPlace | null }>({
      query: ({ id, ...body }) => ({ url: `loads/${id}/type`, method: 'PATCH', body }),
      invalidatesTags: ['chatTrips'],
    }),
    correctLegTimes: builder.mutation<
      Res<LoadDetail>,
      {
        id: number;
        legId: number;
        reason: string;
        startedAt?: string | null;
        endedAt?: string | null;
        stops?: { id: number; arrivedAt?: string | null; departedAt?: string | null; appointment?: string | null }[];
      }
    >({
      query: ({ id, legId, ...body }) => ({ url: `loads/${id}/legs/${legId}/times`, method: 'PATCH', body }),
      invalidatesTags: ['chatTrips'],
    }),
    setLegMiles: builder.mutation<Res<LoadDetail>, { id: number; legId: number; miles: number | null; note?: string | null }>({
      query: ({ id, legId, ...body }) => ({ url: `loads/${id}/legs/${legId}/miles`, method: 'PATCH', body }),
      invalidatesTags: ['chatTrips'],
    }),
    getMilesReport: builder.query<
      Res<{ rows: MilesRow[]; totals: { miles: number; legs: number; missing: number } }>,
      { by: 'driver' | 'truck'; from: string; to: string; q?: string }
    >({
      query: (params) => ({ url: 'loads/miles', method: 'GET', params }),
      providesTags: ['chatTrips'],
    }),
    getDriverLineup: builder.query<Res<DriverLineup>, string>({
      query: (profileId) => ({ url: `loads/lineup/${profileId}`, method: 'GET' }),
      providesTags: ['chatTrips'],
    }),
    reorderDriverLineup: builder.mutation<Res<DriverLineup>, { profileId: string; tripIds: number[] }>({
      query: ({ profileId, tripIds }) => ({ url: `loads/lineup/${profileId}`, method: 'PUT', body: { tripIds } }),
      invalidatesTags: ['chatTrips'],
    }),
    removeFromDriverLineup: builder.mutation<Res<DriverLineup>, { profileId: string; tripId: number }>({
      query: ({ profileId, tripId }) => ({ url: `loads/lineup/${profileId}/${tripId}`, method: 'DELETE' }),
      invalidatesTags: ['chatTrips'],
    }),
    getYardStop: builder.query<Res<StopInput>, void>({
      query: () => ({ url: 'loads/yard-stop', method: 'GET' }),
    }),
    getFleetTrucks: builder.query<Res<FleetTruck[]>, void>({
      query: () => ({ url: 'loads/equipment/trucks', method: 'GET' }),
      providesTags: ['chatTrips'],
      keepUnusedDataFor: 30,
    }),
    getFleetTrailers: builder.query<Res<FleetTrailer[]>, void>({
      query: () => ({ url: 'loads/equipment/trailers', method: 'GET' }),
      providesTags: ['chatTrips'],
      keepUnusedDataFor: 30,
    }),
    getFleetDrivers: builder.query<Res<FleetDriver[]>, void>({
      query: () => ({ url: 'loads/equipment/drivers', method: 'GET' }),
      providesTags: ['chatTrips'],
      keepUnusedDataFor: 30,
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
    tripAction: builder.mutation<Res<Trip>, { id: number; action: TripActionName; note?: string; stopId?: number; invoiceNo?: string }>({
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
  useListLoadBoardQuery,
  useGetLoadDetailQuery,
  useCreateLoadWithLegsMutation,
  useUpdateLoadInfoMutation,
  useAddLoadLegMutation,
  useAssignLoadLegMutation,
  useLazyGetYardStopQuery,
  useGetDriverLineupQuery,
  useLazyGetLegTruckPlaceQuery,
  useSplitLoadLegMutation,
  useUndoLoadSplitMutation,
  useReleaseLoadLegMutation,
  useChangeLoadTypeMutation,
  useCorrectLegTimesMutation,
  useSetLegMilesMutation,
  useGetMilesReportQuery,
  useReorderDriverLineupMutation,
  useRemoveFromDriverLineupMutation,
  useLazySearchStopPlacesQuery,
  useLazyGetStopPlaceQuery,
  useGetFleetTrucksQuery,
  useGetFleetTrailersQuery,
  useGetFleetDriversQuery,
} = TripApiSlice;
