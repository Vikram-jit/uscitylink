import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

const baseQuery = fetchBaseQuery({
  baseUrl: process.env.API_URL, // Replace with your API base URL
  prepareHeaders: (headers) => {
    const token = localStorage.getItem('custom-auth-token'); // Retrieve the token from local storage

    if (token) {
      headers.set('Authorization', `Bearer ${token}`);
    }


return headers;

  },
});

export interface ApiResponse<T = unknown> {
  status: boolean
  message: string
  data?: T
}

export const apiSlice = createApi({
  reducerPath: 'api',
  baseQuery,
  endpoints: () => ({ }),
  tagTypes:['dashboard','truck-groups','staffChatusers','staff_users','staff_messages', 'trainings','assgin_drivers', 'users','profile','channels','groups','channel','channelUsers','messages','members','media','group','trucks','templates']
});
