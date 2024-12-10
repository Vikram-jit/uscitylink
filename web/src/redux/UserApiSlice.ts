import { ApiResponse, apiSlice } from "./apiSlice";
import { pagination } from "./models/ChannelModel";
import { UserModel } from "./models/UserModel";

export const UserApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({

    getUsers: builder.query<{
      status:boolean,
      message:string,
      data:{users:UserModel[],pagination:pagination}
    }, Partial<{role?:string,page:number,search?:string}>>({
      providesTags:['users'],
      query: (payload) => ({
        url: `user?page=${payload.page}&search=${payload.search}`,
        method: 'GET',
        params: payload?.role ? { role: payload.role } : {},
      }),
    }),
    addUser: builder.mutation< ApiResponse,{email?:string,password?:string,role?:string,phone_number?:string}>({
      invalidatesTags:['users'],
      query: (newPost) => ({
        url: 'auth/register',
        method: 'POST',
        body: {...newPost},
      }),
    }),
    syncUser: builder.mutation< ApiResponse,any>({
      invalidatesTags:['users'],
      query: (newPost) => ({
        url: 'auth/syncUser',
        method: 'POST',

      }),
    }),
    syncDriver: builder.mutation< ApiResponse,any>({
      invalidatesTags:['users'],
      query: (newPost) => ({
        url: 'auth/syncDriver',
        method: 'POST',

      }),
    }),
    updateActiveChannel: builder.mutation< ApiResponse,{channelId:string}>({
      invalidatesTags:['channels',"groups","channel","channelUsers"],
      query: (newPost) => ({
        url: `user/updateActiveChannel`,
        method: 'PUT',
        body: {channelId:newPost?.channelId},
      }),
    }),
    getUserWithoutChannel: builder.query<{
      status:boolean,
      message:string,
      data:UserModel[]
    }, Partial<void>>({
      providesTags:['channelUsers'],
      query: () => ({
        url: 'user/drivers',
        method: 'GET',

      }),
    }),
  }),
});


export const {useGetUsersQuery,useAddUserMutation,useUpdateActiveChannelMutation,useGetUserWithoutChannelQuery,useSyncDriverMutation,useSyncUserMutation} = UserApiSlice;
