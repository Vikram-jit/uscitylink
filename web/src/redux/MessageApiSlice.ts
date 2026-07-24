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
    getMessagesBroadcast: builder.query<
      {
        status: boolean;
        message: string;
        data: {
          messages: {
            id: string;
            totalMessages: number;
            sentMessages: number;
            body: string;
            url: string | null;

            createdAt: string;
            updatedAt: string;
            broadcast_messages: {
              id: string;
              broadcast_message_log_id: string;
              sender_id: string;
              user_id: string;
              body: string;
              url: string | null;
              status: string;
              createdAt: string;
              updatedAt: string;
              userProfile: UserProfile;
            }[];
          }[];
          pagination: {
            currentPage: number;
            pageSize: number;
            totalMessages: number;
            totalPages: number;
          };
        };
      },
      { resetKey?: number; page: number; pageSize: number; search?: string; status?: string }
    >({
      query: (payload) => ({
        url: `message/broadcast?resetKey=${payload.resetKey}&page=${payload.page}&pageSize=${payload.pageSize}&search=${payload.search}&status=${payload.status}`,
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['messages'],
    }),
    getMessagesByUserId: builder.query<
      {
        status: boolean;
        message: string;
        data: {
          userProfile: UserProfile;
          messages: MessageModel[];
          pagination: {
            currentPage: number;
            pageSize: number;
            totalMessages: number;
            totalPages: number;
          };
          truckNumbers?: string;
        };
      },
      { id: string; page: number; pageSize: number; pinMessage: string; unreadMessage?: string; resetKey?: number }
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
      { channelId?: string; type: string; userId?: string; source?: string; private_chat_id?: string; page: number; startDate?: string; endDate?: string }
    >({
      query: (payload) => {
        let url = `media/${payload.channelId}?limit=12&page=${payload.page}&type=${payload.type}&userId=${payload.userId}&source=${payload.source}&private_chat_id=${payload.private_chat_id}`;
        if (payload.startDate) url += `&startDate=${payload.startDate}`;
        if (payload.endDate) url += `&endDate=${payload.endDate}`;
        return { url, method: 'GET' };
      },
      keepUnusedDataFor: 0,
      providesTags: ['messages', 'media'],
    }),
    fileUpload: builder.mutation<
      {
        status: boolean;
        message: string;
        data: any;
      },
      { formData: FormData; private_chat_id?: string }
    >({
      query: (formData) => ({
        url: `message/fileUploadWeb?private_chat_id=${formData.private_chat_id}`,
        method: 'POST',
        body: formData.formData,
        formData: true,
      }),

      invalidatesTags: ['media', 'messages'],
    }),

    videoUpload: builder.mutation<
      {
        status: boolean;
        message: string;
        data: any;
      },
      { formData: FormData; groupId?: string | null; userId?: string; private_chat_id?: string }
    >({
      query: (formData) => ({
        url: `message/fileAwsUpload?groupId=${formData.groupId}&userId=${formData.userId}&private_chat_id=${formData.private_chat_id}`,
        method: 'POST',
        body: formData.formData,
        formData: true,
      }),

      invalidatesTags: ['media', 'messages'],
    }),

    quickMessage: builder.mutation<
      { status: string; message: string },
      {
        body: string;
        userProfileId: string;
      }
    >({
      invalidatesTags: ['messages', 'dashboard'],
      query: (payload) => ({
        url: 'message/quickMessageAndReply',
        method: 'POST',
        body: payload,
      }),
    }),
    getSystemUnreadMessages: builder.query<
      {
        status: boolean;
        data: {
          messages: {
            id: string;
            body: string;
            url: string | null;
            messageTimestampUtc: string;
            isCompleted: boolean;
          }[];
        };
      },
      void
    >({
      query: () => ({ url: 'message/system/unread', method: 'GET' }),
      keepUnusedDataFor: 0,
      providesTags: ['messages'],
    }),
    markSystemMessageComplete: builder.mutation<
      { status: boolean; message: string },
      { id: string; note?: string }
    >({
      query: ({ id, note }) => ({
        url: `message/system/${id}/complete`,
        method: 'PUT',
        body: { note },
      }),
      invalidatesTags: ['messages', 'channels'],
    }),
    markAllSystemMessagesRead: builder.mutation<
      { status: boolean; message: string },
      void
    >({
      query: () => ({ url: 'message/system/mark-all-read', method: 'PUT' }),
      invalidatesTags: ['messages', 'channels'],
    }),
    getSystemMessages: builder.query<
      {
        status: boolean;
        data: {
          messages: {
            id: string;
            body: string;
            url: string | null;
            messageTimestampUtc: string;
            channel: { name: string } | null;
            note?: string | null;
          }[];
          pagination: {
            currentPage: number;
            pageSize: number;
            total: number;
            totalPages: number;
          };
        };
      },
      { page: number; pageSize: number; search?: string; completedBy?: string; startDate?: string; endDate?: string }
    >({
      query: (payload) => ({
        url: `message/system?page=${payload.page}&pageSize=${payload.pageSize}&search=${payload.search ?? ''}&completedBy=${payload.completedBy ?? ''}&startDate=${payload.startDate ?? ''}&endDate=${payload.endDate ?? ''}`,
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['messages'],
    }),
    uploadMultipleFiles: builder.mutation<
      {
        status: boolean;
        message: string;
        data: any;
      },
      {
        formData: FormData;
        groupId?: string | null;
        userId?: string;
        location?: string;
        source?: string;
        uploadBy?: string;
        private_chat_id?: string;
        temp_id: string;
      }
    >({
      query: (formData) => ({
        url: `media/uploadFileQueue?groupId=${formData.groupId}&userId=${formData.userId}&source=${formData.source}&location=${formData.location}&uploadBy=${formData.uploadBy}&private_chat_id=${formData.private_chat_id}`,
        method: 'POST',
        body: formData.formData,
        formData: true,
        // headers: {

        //   'Content-Type': 'multipart/form-data',
        // },
      }),

      invalidatesTags: ['media', 'messages'],
    }),
  }),
});

export const {
  useGetMessagesBroadcastQuery,
  useUploadMultipleFilesMutation,
  useConvertAndDownloadJpgQuery,
  useConvertAndDownloadPdfQuery,
  useQuickMessageMutation,
  useGetMessagesByUserIdQuery,
  useVideoUploadMutation,
  useFileUploadMutation,
  useGetMediaQuery,
  useGetSystemMessagesQuery,
  useGetSystemUnreadMessagesQuery,
  useMarkSystemMessageCompleteMutation,
  useMarkAllSystemMessagesReadMutation,
} = MessageApiSlice;
