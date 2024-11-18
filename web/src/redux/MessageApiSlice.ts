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
      keepUnusedDataFor: 60,  // Keep data in the cache for 60 seconds


    }),

    fileUpload: builder.mutation<
    {
      status: boolean;
      message: string;
      data: any
    },
    FormData
  >({

    query: (formData) => ({
      url: 'message/fileUpload',
      method: 'POST',
      body: formData,
      formData: true,
      // headers: {

      //   'Content-Type': 'multipart/form-data',
      // },
    }),

    invalidatesTags: ['messages'],
  }),
  }),
});

export const { useGetMessagesByUserIdQuery,useFileUploadMutation } = MessageApiSlice;
