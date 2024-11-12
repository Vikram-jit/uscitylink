import { ApiResponse, apiSlice } from "./apiSlice";
import { UserModel } from "./models/UserModel";

export const UserApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({

    getUsers: builder.query<{
      status:boolean,
      message:string,
      data:UserModel[]
    }, Partial<void>>({
      providesTags:['users'],
      query: () => ({
        url: 'user',
        method: 'GET',

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


export const {useGetUsersQuery,useAddUserMutation,useUpdateActiveChannelMutation,useGetUserWithoutChannelQuery} = UserApiSlice;
