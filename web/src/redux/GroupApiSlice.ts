import { ApiResponse, apiSlice } from './apiSlice';
import { GroupModel, SingleGroupModel } from './models/GroupModel';
import { TruckModel } from './models/TruckModel';

export const GroupApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getGroups: builder.query<
      {
        status: boolean;
        message: string;
        data: GroupModel[];
      },
      Partial<{ type: string }>
    >({
      providesTags: ['groups'],
      query: (payload) => ({
        url: `group`,
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
      Partial<{ id: string }>
    >({
      providesTags: ['group'],
      query: (payload) => ({
        url: `group/messages/${payload.id}`,
        method: 'GET',
      }),
    }),
    getTrucks: builder.query<
      {
        status: boolean;
        message: string;
        data: TruckModel[];
      },
      Partial<void>
    >({
      providesTags: ['trucks'],
      query: (payload) => ({
        url: `yard/trucks`,
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
      invalidatesTags: ['groups', 'group'],
      query: (payload) => ({
        url: `group/${payload.groupId}`,
        method: 'PUT',
        body: payload,
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
} = GroupApiSlice;
