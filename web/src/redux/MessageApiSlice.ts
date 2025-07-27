
import { apiSlice } from './apiSlice';
import { UserProfile } from './models/ChannelModel';
import { MediaModel } from './models/MediaModel';
import { MessageModel } from './models/MessageModel';

export const MessageApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
  
    convertAndDownloadPdf: builder.query({
      query: (fileName) => ({
        url: `media/convertAndDownloadPdf/${fileName}`,
        method: 'GET',
        responseHandler: (response) => response.blob(),
      }),
    }),
    convertAndDownloadJpg: builder.query({
      query: (fileName) => ({
        url: `media/convertAndDownload/${fileName}`, 
        method: 'GET',
        responseHandler: (response) => response.blob(),
      }),
    }),
    getMessagesByUserId: builder.query<
      {
        status: boolean;
        message: string;
        data: { userProfile: UserProfile; messages: MessageModel[],pagination:{
          currentPage: number,
          pageSize: number,
          totalMessages:number,
          totalPages:number,
        },truckNumbers?:string};
      },
      { id: string,page: number; pageSize: number ,pinMessage:string,unreadMessage?:string,resetKey?: number }
    >({

      query: (payload) => ({
        url: `message/byUserId/${payload.id}?page=${payload.page}&pageSize=${payload.pageSize}&pinMessage=${payload.pinMessage}&unreadMessage=${payload.unreadMessage}&resetKey=${payload.resetKey}`,
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
      { channelId?: string; type: string,userId?: string ,source?:string,private_chat_id?:string,page:number}
    >({

      query: (payload) => ({
        url: `media/${payload.channelId}?limit=12&page=${payload.page}&type=${payload.type}&userId=${payload.userId}&source=${payload.source}&private_chat_id=${payload.private_chat_id}`,
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
      {formData:FormData, private_chat_id?:string}
    >({
      query: (formData) => ({
        url: `message/fileUploadWeb?private_chat_id=${formData.private_chat_id}`,
        method: 'POST',
        body: formData.formData,
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
    {formData:FormData,groupId?:string|null,userId?:string,private_chat_id?:string}
  >({
    query: (formData) => ({
      url: `message/fileAwsUpload?groupId=${formData.groupId}&userId=${formData.userId}&private_chat_id=${formData.private_chat_id}`,
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
  uploadMultipleFiles: builder.mutation<
    {
      status: boolean;
      message: string;
      data: any;
    },
    {formData:FormData,groupId?:string|null,userId?:string,location?:string,source?:string,uploadBy?:string,private_chat_id?:string,temp_id:string}
  >({
    query: (formData) => ({
      url: `media/uploadFileQueue?groupId=${formData.groupId}&userId=${formData.userId}&source=${formData.source}&location=${formData.location}&uploadBy=${formData.uploadBy}&private_chat_id=${formData.private_chat_id}&tempId=${formData.temp_id}`,
      method: 'POST',
      body: formData.formData,
      formData: true,
      // headers: {

      //   'Content-Type': 'multipart/form-data',
      // },
    }),

    invalidatesTags: ['media','messages'],
  }),
  }),
});

export const {useUploadMultipleFilesMutation, useConvertAndDownloadJpgQuery,useConvertAndDownloadPdfQuery, useQuickMessageMutation, useGetMessagesByUserIdQuery, useVideoUploadMutation, useFileUploadMutation,useGetMediaQuery } = MessageApiSlice;
