import {  apiSlice } from './apiSlice';
import { MessageModel } from './models/MessageModel';

export const MessageApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getMessagesByUserId: builder.query<
      {
        status: boolean;
        message: string;
        data: MessageModel[];
      },
      {id:string}
    >({
      providesTags: ['messages'],
      query: (payload) => ({
        url: `message/byUserId/${payload.id}`,
        method: 'GET',
      }),
    }),


  }),
});

export const { useGetMessagesByUserIdQuery } = MessageApiSlice;
