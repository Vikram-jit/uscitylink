import { apiSlice } from './apiSlice';

export interface IceConfig {
  enabled: boolean;
  iceServers: RTCIceServer[];
  ttlSec: number;
  relay: boolean;
}

export type CallStatus = 'ringing' | 'ongoing' | 'completed' | 'missed' | 'declined' | 'cancelled' | 'busy' | 'failed';

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
}

export interface CallParticipantLog {
  user_profile_id: string;
  name: string | null;
  role: 'caller' | 'callee';
  outcome: 'caller' | 'answered' | 'declined' | 'missed' | 'left' | 'invited' | 'joined';
  invited_at: string;
  joined_at: string | null;
  left_at: string | null;
}

export type CallDetail = CallRecord & { participants: CallParticipantLog[] };

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
    updateCallSettings: builder.mutation<Res<{ enabled: boolean }>, { enabled: boolean }>({
      query: (body) => ({ url: 'calls/settings', method: 'PUT', body }),
      invalidatesTags: ['callSettings'],
    }),
    saveCallQuality: builder.mutation<Res<null>, { id: string; stats: Record<string, any> }>({
      query: ({ id, stats }) => ({ url: `calls/${id}/quality`, method: 'POST', body: stats }),
    }),
  }),
});

export const { useGetCallConfigQuery, useGetCallsQuery, useGetCallQuery, useUpdateCallSettingsMutation, useSaveCallQualityMutation } =
  CallApiSlice;
