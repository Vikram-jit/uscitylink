import { ApiResponse, apiSlice } from './apiSlice';
import { ChannelModel, SingleChannelModel } from './models/ChannelModel';
import { UserModel } from './models/UserModel';

export const ChannelApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getChannels: builder.query<
      {
        status: boolean;
        message: string;
        data: ChannelModel[];
      },
      Partial<void>
    >({
      query: () => ({
        url: 'channel',
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['channels'],
    }),
    getActiveChannel: builder.query<
      {
        status: boolean;
        message: string;
        data: {channel:ChannelModel,messages:number,group:number,staffcountUnRead:number,truckGroup:number};
      },
      Partial<void>
    >({
      query: () => ({
        url: 'channel/activeChannel',
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['channels'],
    }),
    addChannel: builder.mutation<
      {
        name: string;
        description?: string;
      },
      Partial<any>
    >({
      invalidatesTags: ['channels'],
      query: (payload) => ({
        url: 'channel',
        method: 'POST',
        body: payload,
      }),
    }),
    getChannelMembers: builder.query<
      {
        status: boolean;
        message: string;
        data: SingleChannelModel;
      },
      { page: number; pageSize: number; search: string,type:string,unreadMessage:string }
    >({
      query: (payload) => ({
        url: `channel/members?page=${payload.page}&pageSize=${payload.pageSize}&search=${payload.search}&type=${payload.type}&unreadMessage=${payload.unreadMessage}`,
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['channel', 'members'],
    }),
    addMemberToChannel: builder.mutation<
      {
        status: boolean;
        message: string;
      },
      { ids: string[] }
    >({
      invalidatesTags: ['channel', 'channelUsers'],
      query: (payload) => ({
        url: 'channel/addToChannel',
        method: 'POST',
        body: payload,
      }),
    }),
    unReadMessageAll: builder.mutation<
    {
      status: boolean;
      message: string;
    },
    void
  >({
    invalidatesTags: ['channels', 'messages'],
    query: (payload) => ({
      url: 'channel/markAllUnreadMessage',
      method: 'POST',
      body: payload,
    }),
  }),
    removeChannelMember: builder.mutation<ApiResponse, { id: string }>({
      invalidatesTags: ['members'],
      query: (payload) => ({
        url: `channel/member/${payload.id}`,
        method: 'DELETE',
      }),
    }),
    changeChannelMemberStatus: builder.mutation<ApiResponse, { id: string,status:string }>({
      invalidatesTags: ['members'],
      query: (payload) => ({
        url: `channel/member/${payload.id}`,
        method: 'PUT',
        body: payload,
      }),
    }),
  }),
});

export const {
  useGetChannelsQuery,
  useAddChannelMutation,
  useGetActiveChannelQuery,
  useGetChannelMembersQuery,
  useAddMemberToChannelMutation,
  useRemoveChannelMemberMutation,
  useChangeChannelMemberStatusMutation,
  useUnReadMessageAllMutation
} = ChannelApiSlice;
