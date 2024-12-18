
import { apiSlice } from './apiSlice';
import { UserProfile } from './models/ChannelModel';
import { MediaModel } from './models/MediaModel';
import { MessageModel } from './models/MessageModel';

export const MessageApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getMessagesByUserId: builder.query<
      {
        status: boolean;
        message: string;
        data: { userProfile: UserProfile; messages: MessageModel[],pagination:{
          currentPage: number,
          pageSize: number,
          totalMessages:number,
          totalPages:number,
        } };
      },
      { id: string,page: number; pageSize: number }
    >({

      query: (payload) => ({
        url: `message/byUserId/${payload.id}?page=${payload.page}&pageSize=${payload.pageSize}`,
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['messages'],
    }),
    getMedia: builder.query<
      {
        status: boolean;
        message: string;
        data: MediaModel;
      },
      { channelId?: string; type: string,userId: string }
    >({

      query: (payload) => ({
        url: `media/${null}?type=${payload.type}&userId=${payload.userId}&source=channel`,
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['messages','media'],
    }),
    fileUpload: builder.mutation<
      {
        status: boolean;
        message: string;
        data: any;
      },
      FormData
    >({
      query: (formData) => ({
        url: 'message/fileUploadWeb',
        method: 'POST',
        body: formData,
        formData: true,
        // headers: {

        //   'Content-Type': 'multipart/form-data',
        // },
      }),

      invalidatesTags: ['media','messages'],
    }),
  }),
});

export const { useGetMessagesByUserIdQuery, useFileUploadMutation,useGetMediaQuery } = MessageApiSlice;
