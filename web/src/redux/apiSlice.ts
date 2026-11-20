import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';
import { apiUrl } from '@/lib/serverUrl';
import { endSession, hasToken } from '@/lib/auth/session';




const prepareHeaders = (headers: Headers) => {
  const token = localStorage.getItem('custom-auth-token'); // Retrieve the token from local storage

  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  return headers;
};

// The server is chosen at request time (IP dashboard → IP server, domain dashboard → domain server)
let cached: { url: string; query: ReturnType<typeof fetchBaseQuery> } | null = null;

const baseQuery: ReturnType<typeof fetchBaseQuery> = async (args, api, extraOptions) => {
  const url = apiUrl();
  if (!cached || cached.url !== url) cached = { url, query: fetchBaseQuery({ baseUrl: url, prepareHeaders }) };
  const result = await cached.query(args, api, extraOptions);
  // 401 = the session is no longer valid (token expired / revoked). Sign-in calls answer 401 for a
  // wrong password, so those are left to the form.
  const path = typeof args === 'string' ? args : args.url;
  if (result.error?.status === 401 && hasToken() && !/^\/?auth\//.test(path)) endSession();
  return result;
};

export interface ApiResponse<T = unknown> {
  status: boolean
  message: string
  data?: T
}

export const apiSlice = createApi({
  reducerPath: 'api',
  baseQuery,
  endpoints: () => ({ }),
  tagTypes:['dashboard','truck-groups','staffChatusers','staff_users','staff_messages', 'trainings','assgin_drivers', 'users','profile','channels','groups','channel','channelUsers','messages','members','media','group','trucks','templates','docTypes','candidateExamples','automationMeta','flows','flowRuns','reviewQueue','messageDocument','scaleChecks','ruleSets','equipment','trips','chatTrips','appVersions','calls','callSettings','loadFeatures']
});
