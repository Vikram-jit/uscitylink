import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

const baseQuery = fetchBaseQuery({
  baseUrl: 'http://localhost:4300/api/v1/', // Replace with your API base URL
  prepareHeaders: (headers) => {
    const token = localStorage.getItem('custom-auth-token'); // Retrieve the token from local storage
    if (token) {
      headers.set('Authorization', `Bearer ${token}`);
    }
    return headers;

  },
});


export const apiSlice = createApi({
  reducerPath: 'api',
  baseQuery,
  endpoints: (builder) => ({ }),
  tagTypes:['users','profile','channels']
});
