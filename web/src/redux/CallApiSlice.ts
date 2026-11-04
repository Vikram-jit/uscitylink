import { apiSlice } from './apiSlice';

export interface IceConfig {
  enabled: boolean;
  iceServers: RTCIceServer[];
  ttlSec: number;
  relay: boolean;
}

export type CallStatus = 'ringing' | 'ongoing' | 'completed' | 'missed' | 'declined' | 'cancelled' | 'busy' | 'failed';

export interface CallRecordingSummary {
  /** recording → processing (mixing/uploading) → ready | failed */
  status: 'recording' | 'processing' | 'ready' | 'failed';
  duration_sec: number | null;
  size_bytes: number | null;
}

export interface CallRecordingLink {
  url: string;
  mime: string | null;
  duration_sec: number | null;
  size_bytes: number | null;
  /** SHA-256 of the stored file — proves it wasn't changed after the call */
  sha256: string | null;
  expires_in_sec: number;
}

export interface CallRecord {
  id: string;
  channel_id: string;
  driver_id: string;
  initiator_id: string;
  answered_by: string | null;
  type: 'audio' | 'video';
  status: CallStatus;
  end_reason: string | null;
  started_at: string;
  answered_at: string | null;
  ended_at: string | null;
  duration_sec: number;
  quality: Record<string, any> | null;
  driver_name: string | null;
  initiator_name: string | null;
  answered_by_name: string | null;
  direction: 'driver_to_dispatch' | 'dispatch_to_driver';
  /** dispatch = the driver called the dispatch line (rings every free dispatcher, queues when all busy) */
  kind: 'direct' | 'dispatch';
  queued_sec: number;
  wait_sec: number | null;
  rang_count?: number;
  /** How many people were on the call (3+ = group call) */
  people?: number;
  recording: CallRecordingSummary | null;
}

export interface CallParticipantLog {
  user_profile_id: string;
  name: string | null;
  /** callee = rung when the call started; added = asked to join the answered call (group call) */
  role: 'caller' | 'callee' | 'added';
  outcome: 'caller' | 'answered' | 'declined' | 'missed' | 'left' | 'invited' | 'joined' | 'cancelled';
  invited_by: string | null;
  invited_by_name: string | null;
  /** added people: 'add' (asked to join) or 'transfer' (the call was handed to them) */
  join_type: 'add' | 'transfer' | null;
  invited_at: string;
  joined_at: string | null;
  left_at: string | null;
}

export type CallDetail = Omit<CallRecord, 'recording'> & {
  participants: CallParticipantLog[];
  recording: (CallRecordingSummary & { sha256: string | null; error: string | null }) | null;
};

interface Res<T> {
  status: boolean;
  message?: string;
  data: T;
}

export const CallApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getCallConfig: builder.query<Res<IceConfig>, void>({
      query: () => ({ url: 'calls/config', method: 'GET' }),
      providesTags: ['callSettings'],
    }),
    getCalls: builder.query<
      Res<{ calls: CallRecord[]; total: number; page: number; pageSize: number }>,
      { driverId?: string; status?: string; page?: number; pageSize?: number }
    >({
      query: (params) => ({ url: 'calls', method: 'GET', params }),
      providesTags: ['calls'],
    }),
    getCall: builder.query<Res<CallDetail>, string>({
      query: (id) => ({ url: `calls/${id}`, method: 'GET' }),
      providesTags: ['calls'],
    }),
    getCallSettings: builder.query<Res<{ enabled: boolean; recording: boolean }>, void>({
      query: () => ({ url: 'calls/settings', method: 'GET' }),
      providesTags: ['callSettings'],
    }),
    updateCallSettings: builder.mutation<Res<{ enabled: boolean; recording: boolean }>, { enabled?: boolean; recording?: boolean }>({
      query: (body) => ({ url: 'calls/settings', method: 'PUT', body }),
      invalidatesTags: ['callSettings'],
    }),
    /** Staff who can be asked to join a call: online; busy ones flagged. */
    getAvailableStaff: builder.query<Res<{ id: string; name: string; busy: boolean }[]>, void>({
      query: () => ({ url: 'calls/available-staff', method: 'GET' }),
      keepUnusedDataFor: 0,
    }),
    /** Short-lived (15 min) link to play/download a call recording. Staff only. */
    getCallRecording: builder.query<Res<CallRecordingLink>, string>({
      query: (id) => ({ url: `calls/${id}/recording`, method: 'GET' }),
      keepUnusedDataFor: 60,
    }),
    saveCallQuality: builder.mutation<Res<null>, { id: string; stats: Record<string, any> }>({
      query: ({ id, stats }) => ({ url: `calls/${id}/quality`, method: 'POST', body: stats }),
    }),
  }),
});

export const {
  useGetCallConfigQuery,
  useGetCallsQuery,
  useGetCallQuery,
  useGetCallSettingsQuery,
  useUpdateCallSettingsMutation,
  useLazyGetCallRecordingQuery,
  useGetAvailableStaffQuery,
  useSaveCallQualityMutation,
} = CallApiSlice;
