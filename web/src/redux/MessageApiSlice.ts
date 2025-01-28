
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
      { channelId?: string; type: string,userId?: string ,source?:string}
    >({

      query: (payload) => ({
        url: `media/${payload.channelId}?type=${payload.type}&userId=${payload.userId}&source=${payload.source}`,
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

    videoUpload: builder.mutation<
    {
      status: boolean;
      message: string;
      data: any;
    },
    {formData:FormData,groupId?:string|null,userId?:string}
  >({
    query: (formData) => ({
      url: `message/fileAwsUpload?groupId=${formData.groupId}&userId=${formData.userId}`,
      method: 'POST',
      body: formData.formData,
      formData: true,
      // headers: {

      //   'Content-Type': 'multipart/form-data',
      // },
    }),

    invalidatesTags: ['media','messages'],
  }),

    quickMessage: builder.mutation<
    {status:string,message:string},
    {
      body: string;
      userProfileId: string;
    }
  >({
    invalidatesTags: ['messages',"dashboard"],
    query: (payload) => ({
      url: 'message/quickMessageAndReply',
      method: 'POST',
      body: payload,
    }),
  }),
  }),
});

export const { useQuickMessageMutation, useGetMessagesByUserIdQuery, useVideoUploadMutation, useFileUploadMutation,useGetMediaQuery } = MessageApiSlice;
