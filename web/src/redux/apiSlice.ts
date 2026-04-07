import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';


const getBaseUrl = () => {
  if (typeof window !== "undefined") {
    const host = window.location.hostname;

    
    if (host === "chatbox.truckcrave.com") {
      return "https://chatbox-server.truckcrave.com/api/v1";
    }

   
    return "http://52.8.75.98:4300/api/v1";
  }

  // fallback (SSR)
  return process.env.API_URL || "http://52.8.75.98:4300/api/v1";
};


const baseQuery = fetchBaseQuery({
  baseUrl: getBaseUrl(), // Replace with your API base URL
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
