import { ApiResponse, apiSlice } from './apiSlice';
import { pagination } from './models/ChannelModel';
import { DashboardModel } from './models/DashboardModel';
import { MessageModel } from './models/MessageModel';
import { StaffChatModel } from './models/StaffChatModel';
import { UserModel } from './models/UserModel';

export const StaffChatApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getStaffUsers: builder.query<
      {
        status: boolean;
        message: string;
        data: StaffChatModel[];
      },
      void
    >({
      providesTags: ['staff_users'],
      query: () => ({
        url: `staff/private/chat/getStaffList`,
        method: 'GET',
      }),
    }),
    getStaffChatUsers: builder.query<
      {
        status: boolean;
        message: string;
        data: StaffChatModel[];
      },
      {search:string}
    >({
      providesTags: ['staffChatusers'],
      query: (payload) => ({
        url: `staff/private/chat/staffChatUsers?search=${payload.search}`,
        method: 'GET',
      }),
    }),
    getMessagesByPrivateChatId: builder.query<
      {
        status: boolean;
        message: string;
        data: {
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
      { id: string; page: number; pinMessage?: string; pin_type?: string }
    >({
      query: (payload) => ({
        url: `staff/private/chat/messages/${payload.id}?page=${payload.page}&pin_type=${payload.pin_type}&pinMessage=${payload.pinMessage}`,
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['staff_messages'],
    }),
    addStaffMember: builder.mutation<
      {
        status: boolean;
        message: string;
      },
      { type: string; userProfileId: string }
    >({
      invalidatesTags: ['staffChatusers', 'staff_users'],
      query: (payload) => ({
        url: `staff/private/chat/addStaffMember`,
        method: 'POST',
        body: payload,
      }),
    }),
  }),
});

export const {
  useGetStaffUsersQuery,
  useGetMessagesByPrivateChatIdQuery,
  useGetStaffChatUsersQuery,
  useAddStaffMemberMutation,
} = StaffChatApiSlice;
