import { ApiResponse, apiSlice } from './apiSlice';
import { GroupModel, SingleGroupModel } from './models/GroupModel';

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
  }),
});

export const { useGetGroupsQuery, useCreateGroupMutation, useGetGroupByIdQuery, useAddGroupMemberMutation,useRemoveGroupMemberMutation } =
  GroupApiSlice;
