import {  apiSlice } from './apiSlice';
import { UserProfile } from './models/ChannelModel';
import { MessageModel } from './models/MessageModel';

export const MessageApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getMessagesByUserId: builder.query<
      {
        status: boolean;
        message: string;
        data: {userProfile:UserProfile,messages:MessageModel[]};
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
