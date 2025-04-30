import { ChannelModel, pagination } from '@/redux/models/ChannelModel';
import { ApiResponse, apiSlice } from './apiSlice';
import { GroupModel, SingleGroupModel } from './models/GroupModel';
import { TruckModel } from './models/TruckModel';

export const GroupApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getGroups: builder.query<
      {
        status: boolean;
        message: string;
        data: {data:GroupModel[],pagination:pagination,channel:ChannelModel};
      },
      Partial<{ type: string,page:number,search?:string }>
    >({
      providesTags: ['groups'],
      query: (payload) => ({
        url: `group?page=${payload.page}&search=${payload.search}`,
        method: 'GET',
        params: payload?.type ? { type: payload.type } : {},
      }),
    }),
    getGroupById: builder.query<
      {
        status: boolean;
        message: string;
        data: SingleGroupModel;
      },
      Partial<{ id: string,page:number,resetKey:number }>
    >({
      providesTags: ['group'],
      query: (payload) => ({
        url: `group/messages/${payload.id}?page=${payload.page}&resetKey=${payload.resetKey}`,
        method: 'GET',
      }),
    }),
    getTrucks: builder.query<
      {
        status: boolean;
        message: string;
        data: any;
      },
      Partial<void>
    >({
      providesTags: ['trucks'],
      query: (payload) => ({
        url: `yard/truckList`,
        method: 'GET',
      }),
    }),
    createGroup: builder.mutation<ApiResponse, { name: string; description?: string; type?: string }>({
      invalidatesTags: ['groups'],
      query: (payload) => ({
        url: 'group',
        method: 'POST',
        body: payload,
      }),
    }),
    addGroupMember: builder.mutation<ApiResponse, { groupId: string; members: string }>({
      invalidatesTags: ['group'],
      query: (payload) => ({
        url: `group/member/${payload.groupId}`,
        method: 'POST',
        body: payload,
      }),
    }),
    removeGroupMember: builder.mutation<ApiResponse, { groupId: string }>({
      invalidatesTags: ['group'],
      query: (payload) => ({
        url: `group/member/${payload.groupId}`,
        method: 'DELETE',
      }),
    }),
    removeGroup: builder.mutation<ApiResponse, { groupId: string }>({
      invalidatesTags: ['groups'],
      query: (payload) => ({
        url: `group/${payload.groupId}`,
        method: 'DELETE',
      }),
    }),
    updateGroup: builder.mutation<ApiResponse, { groupId: string; name: string; description: string }>({
      invalidatesTags: ['groups', 'group','trucks'],
      query: (payload) => ({
        url: `group/${payload.groupId}`,
        method: 'PUT',
        body: payload,
      }),
    }),
    updateGroupMember: builder.mutation<ApiResponse, { groupId: string; status: string;  }>({
      invalidatesTags: [ 'group'],
      query: (payload) => ({
        url: `group/member/${payload.groupId}`,
        method: 'PUT',
        body: payload,
      }),
    }),
    getGroupMessages: builder.query<
      {
        status: boolean;
        message: string;
        data: any;
      },
      Partial<{ channel_id:string,  group_id: string ,page:number,resetKey?: number}>
    >({
      providesTags: ['group'],
      query: (payload) => ({
        url: `message/${payload.channel_id}/${payload.group_id}?page=${payload.page}&resetKey=${payload.resetKey}`,
        method: 'GET',
      }),
    }),
  }),
});

export const {
  useGetGroupsQuery,
  useCreateGroupMutation,
  useGetTrucksQuery,
  useGetGroupByIdQuery,
  useAddGroupMemberMutation,
  useRemoveGroupMemberMutation,
  useRemoveGroupMutation,
  useUpdateGroupMutation,
  useUpdateGroupMemberMutation,
  useGetGroupMessagesQuery
} = GroupApiSlice;
