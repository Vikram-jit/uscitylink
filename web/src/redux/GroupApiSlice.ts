import { ApiResponse, apiSlice } from './apiSlice';
import { GroupModel } from './models/GroupModel';

export const GroupApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getGroups: builder.query<
      {
        status: boolean;
        message: string;
        data: GroupModel[];
      },
      Partial<void>
    >({
      providesTags: ['groups'],
      query: () => ({
        url: 'group',
        method: 'GET',
      }),
    }),

    createGroup: builder.mutation<
      ApiResponse,
      {name:string, description?:string}
    >({
      invalidatesTags: ['groups'],
      query: (payload) => ({
        url: 'group',
        method: 'POST',
        body: payload,
      }),
    }),
  }),
});

export const { useGetGroupsQuery,useCreateGroupMutation } = GroupApiSlice;
